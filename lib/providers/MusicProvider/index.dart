import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Audio/index.dart';
import 'package:myapp/service/Hotkeys/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/src/rust/api/audio_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';

import 'music_library.dart';
import 'music_queue.dart';
import 'music_repository.dart';

// ── 重新导出类型，方便外部直接引用（无须修改原有的 import 路径） ──
export 'music_library.dart' show SongSortType, AlbumSortType;
export 'music_queue.dart' show PlayMode, PlayTrigger, QueueSnapshot;

/// 播放进度数据结构体（用于流式同步当前播放位置、缓冲位置及总时长）
class PositionData {
  final Duration position; // 当前播放进度
  final Duration bufferedPosition; // 当前缓冲进度
  final Duration duration; // 歌曲总时长
  const PositionData(this.position, this.bufferedPosition, this.duration);
}

/// 音乐播放核心 Provider（负责应用层播放状态管理与 UI 响应）
class MusicProvider extends ChangeNotifier {
  /// 底层音频处理器句柄
  final MyAudioHandler audioHandler;

  /// 获取底层的 just_audio 播放器实例
  AudioPlayer get player => audioHandler.player;

  /// 播放状态监听订阅句柄
  StreamSubscription? _stateSubscription;
  StreamSubscription? _stateSubscription2;

  // ── 内部委托服务对象 (Delegates) ──
  final MusicQueue _playbackQueue = MusicQueue(); // 管理播放队列与历史记录
  final MusicLibrary _libraryService = MusicLibrary(); // 管理本地/在线媒体库的排序与合并
  final MusicRepository _repository = MusicRepository(); // 管理持久化数据、网络元数据与网络请求缓存

  // ── 媒体库 ──
  List<Music> _library = [];
  List<Music> get library => _library;

  // ── 排序偏好配置 ──
  SongSortType _songSortType = SongSortType.auto;
  AlbumSortType _albumSortType = AlbumSortType.nameAsc;

  SongSortType get songSortType => _songSortType;
  AlbumSortType get albumSortType => _albumSortType;

  // ── 播放队列与历史访问器（透传至 MusicQueue） ──
  List<Music> get queue => _playbackQueue.queue;
  List<QueueSnapshot> get history => _playbackQueue.history; // 暴露播放队列历史记录
  Music? get currentMusic => _playbackQueue.currentMusic;
  bool isInQueue(String id) => _playbackQueue.contains(id);
  PlayMode get playMode => _playbackQueue.playMode;

  // ── 歌词数据 ──
  List<LyricLine> _currentLyrics = [];
  List<LyricLine> get currentLyrics => _currentLyrics;

  // ── 迷你模式状态 ──
  bool _isMiniMode = false;
  bool get isMiniMode => _isMiniMode;

  // ── 应用元信息（透传至 Repository） ──
  PackageInfo? get appInfo => _repository.appInfo;
  String get appVersion => _repository.appVersion;
  String get buildNumber => _repository.buildNumber;

  // ── 封面加载辅助状态（透传至 Repository） ──
  bool isCoverLoading(String musicId) => _repository.isCoverLoading(musicId);
  bool hasNoCover(String musicId) => _repository.hasNoCover(musicId);

  // ── 网络歌曲元数据（透传至 Repository） ──
  String? getCoverUrl(String musicId) => _repository.getCoverUrl(musicId);
  bool isNetworkSong(String musicId) => _repository.isNetworkSong(musicId);
  Set<String> get networkSongIds => _repository.networkSongIds;
  String? getCachedLyrics(String musicId) =>
      _repository.getCachedLyrics(musicId);

  /// 歌曲开始播放时的回调（可用于外部记录播放历史等统计）
  void Function(Music song)? onMusicPlayed;

  MusicProvider({required this.audioHandler}) {
    // 绑定音频控制切歌事件（如系统通知栏、耳机按键）
    audioHandler.onSkipToNext = () => playNext();
    audioHandler.onSkipToPrevious = () => playPrev();

    // 绑定仓库层的更新通知
    _repository.onNotify = _safeNotifyListeners;

    // 监听播放器处理状态（如自动下一曲）
    _stateSubscription = player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _playNext();
    });

    // 监听播放状态改变（播放/暂停），触发 UI 刷新
    _stateSubscription2 = player.playingStream.listen((playing) {
      _safeNotifyListeners();
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  安全通知 UI 刷新 (Safe notify)
  // ═══════════════════════════════════════════════════════════

  /// 安全地触发 notifyListeners，规避 Flutter 构建阶段（build phase）内调用 notify 导致的异常
  void _safeNotifyListeners() {
    if (!hasListeners) return;

    final binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.midFrameMicrotasks ||
        binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  初始化与媒体库管理 (Bootstrap & Library Management)
  // ═══════════════════════════════════════════════════════════

  /// 应用启动引导流程：初始化快捷键、恢复本地媒体库及获取应用信息
  Future<void> bootstrap({
    required List<Music> scannedSongs,
    void Function(String module, String detail)? onProgress,
  }) async {
    // 初始化全局快捷键监听
    HotkeyService().init(
      onNextTrack: () => playNext(),
      onTogglePlay: () => togglePlay(),
      onPrevTrack: () => playPrev(),
    );

    onProgress?.call('恢复媒体库', '已载入 ${scannedSongs.length} 首歌曲');
    _library = List.from(scannedSongs);
    _safeNotifyListeners();

    onProgress?.call('读取应用信息', '正在获取版本号');
    await _repository.loadAppInfo();
    _safeNotifyListeners();

    // 4. 恢复历史播放队列快照
    onProgress?.call('播放历史', '正在恢复历史播放队列...');
    await loadQueueHistory();
  }

  /// 批量合并更新媒体库
  void updateLibrary(List<Music> scannedSongs) {
    _library = _libraryService.mergeLibrary(_library, scannedSongs);
    _safeNotifyListeners();
  }

  /// 向媒体库添加单首歌曲（根据 ID 去重更新）
  void addToLibrary(Music music) {
    final idx = _library.indexWhere((m) => m.id == music.id);
    if (idx != -1) {
      // 保留已存在的封面与歌词等缓存信息
      _library[idx] = _library[idx].copyWith(
        title: music.title,
        artist: music.artist,
        album: music.album,
        duration: music.duration,
        coverBytes: music.coverBytes ?? _library[idx].coverBytes,
        lyrics: music.lyrics ?? _library[idx].lyrics,
      );
    } else {
      _library.add(music);
    }
    _safeNotifyListeners();
  }

  /// 切换迷你模式
  void setMiniMode(bool value) {
    _isMiniMode = value;
    _safeNotifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  排序控制 (Sorting - 委托给 LibraryService)
  // ═══════════════════════════════════════════════════════════

  /// 设置单曲排序规则
  Future<void> setSongSortType(SongSortType type) async {
    _songSortType = type;
    _safeNotifyListeners();
  }

  /// 设置专辑排序规则
  Future<void> setAlbumSortType(AlbumSortType type) async {
    _albumSortType = type;
    _safeNotifyListeners();
  }

  /// 获取排序后的媒体库列表
  List<Music> getSortedLibrary() {
    return _libraryService.getSortedLibrary(_library, sortType: _songSortType);
  }

  /// 获取排序后的专辑分组列表
  List<MapEntry<String, List<Music>>> getSortedAlbums() {
    return _libraryService.getSortedAlbums(
      _library,
      songSortType: _songSortType,
      albumSortType: _albumSortType,
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  歌词处理 (Lyrics)
  // ═══════════════════════════════════════════════════════════

  /// 解析 LRC 文本字符串为歌词行列表
  Future<List<LyricLine>> _parseLrc(String? lrcContent) async {
    if (lrcContent == null || lrcContent.isEmpty) return [];
    return await MusicService.parseLyrics(lrcContent);
  }

  /// 为当前播放的歌曲设置新歌词，并更新本地持久化
  Future<void> setCurrentLrc(String? lrcContent) async {
    final music = _playbackQueue.currentMusic;
    if (music == null) return;
    music.lyrics = lrcContent;
    _currentLyrics = await _parseLrc(lrcContent);
    _safeNotifyListeners();
    await MusicService.saveLyrics(lrcContent, music.id);
  }

  /// 直接更新并渲染当前歌词内容
  Future<void> setLyricsDirectly(String lrcContent) async {
    _currentLyrics = await _parseLrc(lrcContent);
    final music = _playbackQueue.currentMusic;
    if (music != null) {
      _repository.updateLyricContent(music.id, lrcContent);
      music.lyrics = lrcContent;
    }
    _safeNotifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  队列管理 (Queue Management - 委托给 PlaybackQueue)
  // ═══════════════════════════════════════════════════════════

  /// 添加歌曲至队列末尾
  void addToQueue(Music music) {
    _playbackQueue.add(music);
    _safeNotifyListeners();
  }

  /// 调整队列中歌曲顺序
  void reorderQueue(int oldIndex, int newIndex) {
    _playbackQueue.reorder(oldIndex, newIndex);
    _safeNotifyListeners();
  }

  /// 从队列移除指定位置的歌曲
  void removeFromQueue(int index) {
    if (index == _playbackQueue.currentIndex ||
        index < 0 ||
        index >= _playbackQueue.length) {
      return;
    }
    _playbackQueue.removeAt(index);
    _safeNotifyListeners();
  }

  /// 清空当前播放队列并停止播放
  void clearQueue() {
    _playbackQueue.clear();
    player.stop();
    _safeNotifyListeners();
  }

  /// 删除指定的单条队列历史快照
  void deleteQueueSnapshot(String snapshotId) {
    _playbackQueue.removeHistoryById(snapshotId);
    _safeNotifyListeners();

    // 委托给 Repository 处理持久化，不直接操作 DbService
    _repository.deleteQueueSnapshot(snapshotId);
  }

  /// 清空所有的队列历史快照记录
  void clearQueueHistory() {
    _playbackQueue.clearHistory();
    _safeNotifyListeners();

    // 委托给 Repository 处理持久化
    _repository.clearQueueHistory();
  }

  /// 替换或保存当前播放队列并持久化
  void saveCurrentQueueToHistory({String? queueName}) {
    // 1. 更新内存状态，获取最新快照
    final snapshot = _playbackQueue.saveCurrentToHistory(queueName: queueName);

    if (snapshot != null) {
      _safeNotifyListeners();
      // 2. 触发异步持久化落盘
      _repository.saveQueueSnapshot(snapshot);
    }
  }

  // music_provider.dart

  /// 启动时从 SQLite 数据库恢复历史播放队列列表
  Future<void> loadQueueHistory() async {
    // 1. 调用 repository 拉取 DB 数据并还原成 QueueSnapshot 实体列表
    final snapshots = await _repository.loadQueueHistoryFromDb(
      library: _library,
      currentQueue: _playbackQueue.queue,
    );

    if (snapshots.isNotEmpty) {
      // 2. 将数据灌入内存模型 MusicQueue
      _playbackQueue.loadHistory(snapshots);

      // 3. 通知 UI 刷新（例如 _QueueSheet 页面）
      _safeNotifyListeners();
    }
  }

  /// 替换当前播放队列（可选标记队列名称 [queueName]，并控制是否保存快照到历史记录）
  Future<void> replaceQueue(
    List<Music> songs, {
    int startIndex = 0,
    bool autoPlay = true,
    String? queueName,
    bool saveToHistory = true,
  }) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    // 1. 在替换前，先将当前旧队列自动存入历史快照
    if (saveToHistory && queue.isNotEmpty) {
      saveCurrentQueueToHistory();
    }

    _playbackQueue.replace(
      songs,
      queueName: queueName,
      saveToHistory: saveToHistory,
    );
    await player.stop();
    await playByIndex(startIndex, autoPlay: autoPlay);
  }

  /// 从历史快照中恢复播放队列
  Future<void> restoreQueueFromHistory(
    QueueSnapshot snapshot, {
    bool autoPlay = true,
  }) async {
    final targetIndex = _playbackQueue.restoreFromSnapshot(snapshot);
    await player.stop();
    await playByIndex(targetIndex, autoPlay: autoPlay);
  }

  /// 从媒体库单曲直接点击播放（存在则切过去，不存在则追加到末尾）
  void playFromLibrary(Music music, {bool autoPlay = true}) {
    if (_playbackQueue.currentMusic?.id == music.id) return;

    if (_playbackQueue.contains(music.id)) {
      playByIndex(
        _playbackQueue.queue.indexWhere((m) => m.id == music.id),
        autoPlay: autoPlay,
      );
    } else {
      _playbackQueue.add(music);
      playByIndex(_playbackQueue.length - 1, autoPlay: autoPlay);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  核心播放逻辑 (Core Playback)
  // ═══════════════════════════════════════════════════════════

  /// 按队列索引进行播放
  Future<void> playByIndex(int index, {bool autoPlay = true}) async {
    final queue = _playbackQueue.queue;
    if (index < 0 || index >= queue.length) return;
    if (index == _playbackQueue.currentIndex && player.playing && autoPlay) {
      return;
    }

    _playbackQueue.setCurrentIndex(index);
    final music = queue[index];

    // 读取缓存歌词或已有歌词并解析
    final effectiveLyrics =
        _repository.getCachedLyrics(music.id) ?? music.lyrics;
    _currentLyrics = await _parseLrc(effectiveLyrics);
    _safeNotifyListeners();

    // 若无歌词且为网络歌曲，在后台异步拉取
    if (effectiveLyrics == null && music.source == MusicSource.network) {
      _fetchLyricsInBackground(music);
    }

    // 本地歌曲且无封面时，延迟异步加载封面
    if (music.source != MusicSource.network &&
        (music.coverBytes == null || music.coverBytes!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadCoverLazy(music.id);
      });
    }

    if (_repository.isNetworkSong(music.id)) {
      // 从缓存获取网络音频链接
      String? playUrl = _repository.getNetworkUrl(music.id);

      // 若为网易云歌曲，视情况刷新 URL 链接防失效
      if (music.id.startsWith('net_')) {
        final freshUrl = await _repository.refreshNeteaseUrl(music.id);
        if (freshUrl != null) playUrl = freshUrl;
      }

      if (playUrl == null || playUrl.isEmpty) return;

      if (autoPlay) onMusicPlayed?.call(music);

      // 优先直接播放音频（暂不带封面，规避图片 403 防盗链阻断音频加载）
      await audioHandler.playFromUrl(
        playUrl,
        id: music.id,
        title: music.title,
        artist: music.artist,
        coverUrl: null,
        autoPlay: autoPlay,
      );

      // 后台异步获取安全封面代理，成功后热更新通知栏元数据
      final coverUrl = _repository.getCoverUrl(music.id);
      final currentPlayingId = music.id;
      final safePlayUrl = playUrl;

      _repository.getSafeArtUri(coverUrl).then((safeCoverUrl) {
        if (safeCoverUrl != null &&
            _playbackQueue.currentIndex >= 0 &&
            _playbackQueue.queue[_playbackQueue.currentIndex].id ==
                currentPlayingId) {
          final currentCover = getCoverUrl(currentPlayingId);
          if (currentCover == safeCoverUrl) return;
          debugPrint('--- [MusicProvider] 安全封面热更新: $safeCoverUrl ---');
          audioHandler.playFromUrl(
            safePlayUrl,
            id: currentPlayingId,
            title: music.title,
            artist: music.artist,
            coverUrl: safeCoverUrl,
            autoPlay: player.playing,
            updateAudioSource: false,
          );
        }
      });
    } else {
      // 本地音频播放
      if (autoPlay) onMusicPlayed?.call(music);
      await audioHandler.playMusic(music, autoPlay: autoPlay);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  封面加载 (Cover Loading - 委托给 MusicRepository)
  // ═══════════════════════════════════════════════════════════

  /// 懒加载指定歌曲的封面 Byte 数组
  Future<void> loadCoverLazy(String musicId) async {
    final coverBytes = await _repository.loadCoverLazy(musicId);
    if (coverBytes != null) {
      _updateCoverBytes(musicId, coverBytes);
    }
  }

  /// 内部更新指定歌曲的封面 Data，并同步刷新媒体库与队列
  void _updateCoverBytes(String musicId, Uint8List? coverBytes) {
    if (coverBytes == null || coverBytes.isEmpty) return;

    bool hasChanged = false;
    void patch(List<Music> list) {
      final idx = list.indexWhere((m) => m.id == musicId);
      if (idx != -1 &&
          (list[idx].coverBytes == null || list[idx].coverBytes!.isEmpty)) {
        list[idx].coverBytes = coverBytes;
        hasChanged = true;
      }
    }

    patch(_library);
    _playbackQueue.updateCoverBytes(musicId, coverBytes);

    if (hasChanged) _safeNotifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  播放控制操作 (Playback Controls)
  // ═══════════════════════════════════════════════════════════

  /// 切换 播放/暂停
  void togglePlay() {
    player.playing ? player.pause() : player.play();
    _safeNotifyListeners();
  }

  /// 切换播放模式（顺序、随机、单曲循环等）
  void togglePlayMode() {
    _playbackQueue.togglePlayMode();
    _safeNotifyListeners();
  }

  /// 下一曲（用户手动触发）
  Future<void> playNext() => _playNext(trigger: PlayTrigger.user);

  /// 上一曲
  Future<void> playPrev() => _playPrev();

  /// 内部计算并播放下一曲
  Future<void> _playNext({PlayTrigger trigger = PlayTrigger.auto}) async {
    final nextIndex = _playbackQueue.computeNextIndex(trigger: trigger);
    if (nextIndex < 0) return;

    if (_playbackQueue.playMode == PlayMode.repeat &&
        trigger == PlayTrigger.auto) {
      // 单曲循环自动播放完时重置进度
      await player.seek(Duration.zero);
      player.play();
    } else if (_playbackQueue.playMode == PlayMode.sequence &&
        nextIndex == _playbackQueue.currentIndex &&
        trigger == PlayTrigger.auto) {
      // 顺序播放到列表末尾时停止并重置进度
      await player.seek(Duration.zero);
    } else {
      await playByIndex(nextIndex);
    }
  }

  /// 内部计算并播放上一曲
  Future<void> _playPrev() async {
    final prevIndex = _playbackQueue.computePrevIndex();
    if (prevIndex >= 0) {
      await playByIndex(prevIndex);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  网络歌曲处理 (Network Songs)
  // ═══════════════════════════════════════════════════════════

  /// 从媒体库或当前队列中查找特定 ID 的歌曲
  Music? getSongById(String id) =>
      _repository.getSongById(id, _library, _playbackQueue.queue);

  /// 将网络搜索结果导入并替换当前队列进行播放
  Future<void> playNetworkSearchResults({
    required List<Map<String, String?>> songs,
    required int startIndex,
    bool autoPlay = true,
    String? queueName,
  }) async {
    if (songs.isEmpty) return;

    final (musicList, _) = _repository.importNetworkSearchResults(songs);
    await replaceQueue(
      musicList,
      startIndex: startIndex,
      autoPlay: autoPlay,
      queueName: queueName ?? '搜索结果队列',
    );
  }

  /// 播放单首网络歌曲
  Future<void> playNetworkSong({
    required String url,
    required String id,
    required String title,
    required String artist,
    String? coverUrl,
    String? lyricContent,
  }) async {
    final musicId = 'net_$id';
    final music = Music(
      id: musicId,
      title: title,
      artist: artist,
      duration: Duration.zero,
      coverBytes: null,
      lyrics: lyricContent,
      album: null,
      source: MusicSource.network,
    );

    // 注册网络歌曲元数据
    _repository.registerNetworkSong(
      musicId: musicId,
      url: url,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
      lyricContent: lyricContent,
    );

    final effectiveLyrics =
        lyricContent ?? _repository.getCachedLyrics(musicId);
    _currentLyrics = await _parseLrc(effectiveLyrics);

    if (effectiveLyrics != null) {
      _repository.updateLyricContent(musicId, effectiveLyrics);
    }

    if (!_playbackQueue.contains(musicId)) {
      _playbackQueue.add(music);
    }
    _playbackQueue.setCurrentIndex(
      _playbackQueue.queue.indexWhere((m) => m.id == musicId),
    );

    _safeNotifyListeners();
    onMusicPlayed?.call(music);

    // 防抖持久化网络歌曲信息
    _repository.debouncePersistNetworkSong(
      music,
      url,
      coverUrl,
      effectiveLyrics,
    );

    // 优先播放音频（无封面）
    await audioHandler.playFromUrl(
      url,
      id: musicId,
      title: title,
      artist: artist,
      coverUrl: null,
      autoPlay: true,
    );

    // 后台获取安全封面代理并更新
    final currentPlayingId = music.id;
    _repository.getSafeArtUri(coverUrl).then((safeCoverUrl) {
      final currentCover = getCoverUrl(currentPlayingId);
      if (currentCover == safeCoverUrl) return;
      if (safeCoverUrl != null &&
          _playbackQueue.currentIndex >= 0 &&
          _playbackQueue.queue[_playbackQueue.currentIndex].id == musicId) {
        debugPrint('--- [MusicProvider] 后台封面预缓存成功，动态热更新通知栏 ---');
        audioHandler.playFromUrl(
          url,
          id: musicId,
          title: title,
          artist: artist,
          coverUrl: safeCoverUrl,
          autoPlay: player.playing,
          updateAudioSource: false,
        );
      }
    });
  }

  /// 加载本地存储的历史网络歌曲缓存
  Future<void> loadPersistedNetworkSongs() async {
    await _repository.loadPersistedNetworkSongs();
  }

  // ═══════════════════════════════════════════════════════════
  //  后台歌词抓取 (Background Lyrics Fetching)
  // ═══════════════════════════════════════════════════════════

  /// 在后台异步获取歌词，并在属于当前播放歌曲时刷新 UI
  void _fetchLyricsInBackground(Music music) {
    _repository.fetchAndCacheLyrics(music).then((lrc) {
      if (lrc != null &&
          _playbackQueue.currentIndex >= 0 &&
          _playbackQueue.queue[_playbackQueue.currentIndex].id == music.id) {
        _parseLrc(lrc).then((parsed) {
          _currentLyrics = parsed;
          _safeNotifyListeners();
        });
      }
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  播放进度流 (Position Stream)
  // ═══════════════════════════════════════════════════════════

  /// 结合播放位置、缓冲位置与总时长，组合成专用的 Rx 进度流
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  // ═══════════════════════════════════════════════════════════
  //  生命周期管理 (Lifecycle)
  // ═══════════════════════════════════════════════════════════

  @override
  void dispose() {
    _repository.dispose();
    _stateSubscription?.cancel();
    _stateSubscription2?.cancel();
    player.dispose();
    super.dispose();
  }
}
