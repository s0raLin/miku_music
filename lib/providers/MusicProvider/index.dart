import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Audio/index.dart';
import 'package:myapp/service/Hotkeys/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/service/NetworkSongStore/index.dart';
import 'package:myapp/src/rust/api/audio_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  const PositionData(this.position, this.bufferedPosition, this.duration);
}

enum SongSortType { auto, nameAsc, nameDesc, artistAsc }

enum AlbumSortType { nameAsc, nameDesc, songCountDesc }

enum PlayMode { sequence, shuffle, repeat }

enum PlayTrigger { user, auto }

class _NetworkSongMeta {
  final String url;
  final String title;
  final String artist;
  final String? coverUrl;
  String? lyricContent;

  _NetworkSongMeta({
    required this.url,
    required this.title,
    required this.artist,
    this.coverUrl,
  });
}

class MusicProvider extends ChangeNotifier {
  final MyAudioHandler audioHandler;

  AudioPlayer get player => audioHandler.player;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _stateSubscription2;

  PackageInfo? _appInfo;
  PackageInfo? get appInfo => _appInfo;
  String get appVersion => _appInfo?.version ?? '加载中...';
  String get buildNumber => _appInfo?.buildNumber ?? '';

  List<Music> _library = [];
  List<Music> get library => _library;

  List<Music> _queue = [];
  List<Music> get queue => _queue;

  int _currentIndex = -1;

  // 优化 2：用 Map 缓存队列中的 ID 到索引的映射，把查找开销降为 O(1)
  Map<String, int> _queueIndexMap = {};

  Music? get currentMusic {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  List<LyricLine> _currentLyrics = [];
  List<LyricLine> get currentLyrics => _currentLyrics;

  bool _isMiniMode = false;
  bool get isMiniMode => _isMiniMode;

  final Set<String> _loadingCoverIds = {};
  final Set<String> _noCoverIds = {};

  // 持久化防抖缓存队列
  final List<NetworkSongMeta> _persistQueue = [];
  Timer? _persistTimer;

  MusicProvider({required this.audioHandler}) {
    // Wire notification prev/next buttons to MusicProvider's play logic
    audioHandler.onSkipToNext = () => playNext();
    audioHandler.onSkipToPrevious = () => playPrev();

    _stateSubscription = player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _playNext();
    });

    _stateSubscription2 = player.playingStream.listen((playing) {
      _safeNotifyListeners();
    });
  }

  /// 核心防御防线：确保在生命周期安全且不在 Build 期时通知 UI
  void _safeNotifyListeners() {
    // 优化 3：异步回调安全拦截，防止 Dispose 后抛出异常
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

  // 刷新 O(1) 索引表
  void _refreshQueueIndexMap() {
    _queueIndexMap = {for (int i = 0; i < _queue.length; i++) _queue[i].id: i};
  }

  Future<void> bootstrap({
    required List<Music> scannedSongs,
    void Function(String module, String detail)? onProgress,
  }) async {
    HotkeyService().init(
      onNextTrack: () => playNext(),
      onTogglePlay: () => togglePlay(),
      onPrevTrack: () => playPrev(),
    );

    onProgress?.call('恢复媒体库', '已载入 ${scannedSongs.length} 首歌曲');
    _library = List.from(scannedSongs);
    _safeNotifyListeners();

    onProgress?.call('读取应用信息', '正在获取版本号');
    await _loadAppInfo();
  }

  void updateLibrary(List<Music> scannedSongs) {
    final Map<String, Music> uniqueMap = {
      for (var song in _library) song.id: song,
    };

    for (var newSong in scannedSongs) {
      final oldSong = uniqueMap[newSong.id];
      if (oldSong != null) {
        final hasOldCover =
            oldSong.coverBytes != null && oldSong.coverBytes!.isNotEmpty;
        final hasNewCover =
            newSong.coverBytes != null && newSong.coverBytes!.isNotEmpty;

        if (hasOldCover && !hasNewCover) {
          uniqueMap[newSong.id] = newSong.copyWith(
            coverBytes: oldSong.coverBytes,
            lyrics: (newSong.lyrics == null || newSong.lyrics!.isEmpty)
                ? oldSong.lyrics
                : newSong.lyrics,
          );
          continue;
        }
      }
      uniqueMap[newSong.id] = newSong;
    }

    _library = uniqueMap.values.toList();
    _safeNotifyListeners();
  }

  void setMiniMode(bool value) {
    _isMiniMode = value;
    _safeNotifyListeners();
  }

  SongSortType _songSortType = SongSortType.auto;
  AlbumSortType _albumSortType = AlbumSortType.nameAsc;

  SongSortType get songSortType => _songSortType;
  AlbumSortType get albumSortType => _albumSortType;

  Future<void> setSongSortType(SongSortType type) async {
    _songSortType = type;
    _safeNotifyListeners();
  }

  Future<void> setAlbumSortType(AlbumSortType type) async {
    _albumSortType = type;
    _safeNotifyListeners();
  }

  List<Music> getSortedLibrary() {
    final list = List<Music>.from(_library);
    switch (_songSortType) {
      case SongSortType.nameAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SongSortType.nameDesc:
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
      case SongSortType.artistAsc:
        list.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case SongSortType.auto:
        break;
    }
    return list;
  }

  List<MapEntry<String, List<Music>>> getSortedAlbums() {
    final sortedSongs = getSortedLibrary();
    final map = <String, List<Music>>{};

    for (final song in sortedSongs) {
      final albumName = song.album ?? "未知专辑";
      map.putIfAbsent(albumName, () => []).add(song);
    }

    final entries = map.entries.toList();
    switch (_albumSortType) {
      case AlbumSortType.nameAsc:
        entries.sort((a, b) => a.key.compareTo(b.key));
        break;
      case AlbumSortType.nameDesc:
        entries.sort((a, b) => b.key.compareTo(a.key));
        break;
      case AlbumSortType.songCountDesc:
        entries.sort((a, b) => b.value.length.compareTo(a.value.length));
        break;
    }
    return entries;
  }

  Future<List<LyricLine>> _parseLrc(String? lrcContent) async {
    if (lrcContent == null || lrcContent.isEmpty) return [];
    return await MusicService.parseLyrics(lrcContent);
  }

  Future<void> setCurrentLrc(String? lrcContent) async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;
    _queue[_currentIndex].lyrics = lrcContent;
    final curMusic = _queue[_currentIndex];
    _currentLyrics = await _parseLrc(lrcContent);
    _safeNotifyListeners();
    await MusicService.saveLyrics(lrcContent, curMusic.id);
  }

  // 优化 2：基于 Map，查找速度从 O(N) 变为 O(1)
  bool isInQueue(String id) => _queueIndexMap.containsKey(id);

  void addToQueue(Music music) {
    _queue.add(music);
    _queueIndexMap[music.id] = _queue.length - 1;
    _safeNotifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final playingMusic = currentMusic;

    if (newIndex > oldIndex) newIndex += 1;

    final song = _queue.removeAt(oldIndex);
    final targetIndex = (newIndex > oldIndex ? newIndex - 1 : newIndex).clamp(
      0,
      _queue.length,
    );
    _queue.insert(targetIndex, song);

    _refreshQueueIndexMap();

    if (playingMusic != null) {
      _currentIndex = _queueIndexMap[playingMusic.id] ?? -1;
    }
    _safeNotifyListeners();
  }

  void removeFromQueue(int index) {
    if (index == _currentIndex || index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) _currentIndex--;
    _refreshQueueIndexMap();
    _safeNotifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _queueIndexMap.clear();
    _currentIndex = -1;
    player.stop();
    _safeNotifyListeners();
  }

  void Function(Music song)? onMusicPlayed;

  Future<void> replaceQueue(
    List<Music> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;
    _queue = List.from(songs);
    _refreshQueueIndexMap();
    _currentIndex = -1;
    await player.stop();
    await playByIndex(startIndex, autoPlay: autoPlay);
  }

  void playFromLibrary(Music music, {bool autoPlay = true}) {
    if (_currentIndex != -1 && _queue[_currentIndex].id == music.id) return;

    final existingIndex = _queueIndexMap[music.id] ?? -1;
    if (existingIndex != -1) {
      playByIndex(existingIndex, autoPlay: autoPlay);
    } else {
      _queue.add(music);
      _queueIndexMap[music.id] = _queue.length - 1;
      playByIndex(_queue.length - 1, autoPlay: autoPlay);
    }
  }

  //用于缓存网络封面 URL 对应的本地安全的 file:// 路径，避免同一首歌甚至不同歌用相同封面时重复下载
  final Map<String, String> _safeCoverCache = {};

  /// 将潜在的网易云网络封面预缓存，并转换为安全的本地 file:// URI（加入去重和智能锁）
  Future<String?> _getSafeArtUri(String? coverUrl) async {
    if (coverUrl == null || coverUrl.isEmpty) return null;

    // 🛡️ 关卡 1：如果在内存字典中已经有了，直接返回，不再浪费 I/O 和网络开销
    if (_safeCoverCache.containsKey(coverUrl)) {
      // debugPrint('--- [MusicProvider] 封面命中内存缓存，秒回路径 ---');
      return _safeCoverCache[coverUrl];
    }

    if (coverUrl.contains('music.126.net')) {
      String targetUrl = coverUrl
          .replaceAll('http://', 'https://')
          .replaceAll('p2.music.126.net', 'p1.music.126.net');

      try {
        // 关卡 2：改用 getSingleFile，它会自动利用本地 http 缓存协议，不会盲目生成新 UUID 文件
        final file = await DefaultCacheManager().getSingleFile(
          targetUrl,
          headers: const {
            'User-Agent':
                'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': 'https://music.163.com/',
          },
        );

        final safePath = Uri.file(file.path).toString();

        // 塞入缓存字典
        _safeCoverCache[coverUrl] = safePath;
        return safePath;
      } catch (e) {
        debugPrint('--- [MusicProvider] 预缓存网易云封面失败: $e ---');

        // 降级策略
        try {
          final fallbackFile = await DefaultCacheManager().getSingleFile(
            targetUrl,
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          );
          final safePath = Uri.file(fallbackFile.path).toString();
          _safeCoverCache[coverUrl] = safePath;
          return safePath;
        } catch (_) {
          return null;
        }
      }
    }
    return coverUrl;
  }

  Future<void> playByIndex(int index, {bool autoPlay = true}) async {
    if (index < 0 || index >= _queue.length) return;
    if (index == _currentIndex && player.playing && autoPlay) return;

    _currentIndex = index;
    final music = _queue[index];
    final effectiveLyrics =
        _networkMeta[music.id]?.lyricContent ?? music.lyrics;
    _currentLyrics = await _parseLrc(effectiveLyrics);
    _safeNotifyListeners();

    if (effectiveLyrics == null && music.source == MusicSource.network) {
      _fetchLyricsInBackground(music);
    }

    if (music.source != MusicSource.network &&
        (music.coverBytes == null || music.coverBytes!.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadCoverLazy(music.id);
      });
    }

    final netMeta = _networkMeta[music.id];

    if (netMeta != null) {
      String playUrl = netMeta.url;

      // ======= 🔮 完整保留并缝合原 NeteaseApi.getRealUrl 刷新逻辑 =======
      if (music.id.startsWith('net_')) {
        final numericId = music.id.substring(4);
        try {
          final freshUrl = await NeteaseApi.getRealUrl(
            numericId,
            source: 'netease',
          );
          if (freshUrl != null && freshUrl.isNotEmpty) {
            playUrl = freshUrl;
            _networkMeta[music.id] = _NetworkSongMeta(
              url: freshUrl,
              title: netMeta.title,
              artist: netMeta.artist,
              coverUrl: netMeta.coverUrl,
            )..lyricContent = netMeta.lyricContent;
          }
        } catch (_) {
          debugPrint('刷新网络歌曲URL失败，使用缓存URL');
        }
      }
      // ===============================================================

      if (autoPlay) onMusicPlayed?.call(music);

      // 第一次：音频流先走，封面传 null，防止底层偷偷请求引发 403 连环炸弹
      await audioHandler.playFromUrl(
        playUrl,
        id: music.id,
        title: netMeta.title,
        artist: netMeta.artist,
        coverUrl: null, // 必须为 null
        autoPlay: autoPlay,
      );

      // ⚡ 后台异步抓取安全封面，不 await 阻塞主流程
      final currentPlayingId = music.id; // 闭包精准捕获 ID 副本，防止下载期间用户切歌
      _getSafeArtUri(netMeta.coverUrl).then((safeCoverUrl) {
        // 确保下载完后，用户还没有切走，依然在播当前这首歌
        if (safeCoverUrl != null &&
            _currentIndex >= 0 &&
            _queue[_currentIndex].id == currentPlayingId) {
          // 防御屏障：通过 getCoverUrl 查一下，如果发现当前 Provider 里的封面已经变成本地 file:// 了，说明已经热更新过了，坚决不准重复调用 playFromUrl！
          final currentCover = getCoverUrl(currentPlayingId);
          if (currentCover == safeCoverUrl) {
            // 已是最新的安全路径，直接拦截，拒绝再次调用
            return;
          }
          debugPrint('--- [MusicProvider] 安全封面热更新: $safeCoverUrl ---');
          // 第二次：仅更新通知栏封面元数据，硬编码 updateAudioSource: false，绝不打断 MPV 的加载
          audioHandler.playFromUrl(
            playUrl,
            id: currentPlayingId,
            title: netMeta.title,
            artist: netMeta.artist,
            coverUrl: safeCoverUrl,
            autoPlay: player.playing,
            updateAudioSource: false, // 强制不戳播放器音频源
          );
        }
      });
    } else {
      if (autoPlay) onMusicPlayed?.call(music);
      await audioHandler.playMusic(music, autoPlay: autoPlay);
    }
  }

  bool isCoverLoading(String musicId) => _loadingCoverIds.contains(musicId);
  bool hasNoCover(String musicId) => _noCoverIds.contains(musicId);

  Future<void> loadCoverLazy(String musicId) async {
    if (isNetworkSong(musicId) ||
        _noCoverIds.contains(musicId) ||
        _loadingCoverIds.contains(musicId))
      return;

    _loadingCoverIds.add(musicId);
    _safeNotifyListeners();

    try {
      final updated = await MusicService.parse(musicId);
      if (updated.coverBytes != null && updated.coverBytes!.isNotEmpty) {
        _updateCoverBytes(musicId, updated.coverBytes);
      } else {
        _noCoverIds.add(musicId);
      }
    } catch (e) {
      debugPrint('懒加载音频封面失败 [$musicId]: $e');
      _noCoverIds.add(musicId);
    } finally {
      _loadingCoverIds.remove(musicId);
      _safeNotifyListeners();
    }
  }

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
    patch(_queue);

    if (hasChanged) _safeNotifyListeners();
  }

  void togglePlay() {
    player.playing ? player.pause() : player.play();
    _safeNotifyListeners();
  }

  final Map<String, _NetworkSongMeta> _networkMeta = {};

  String? getCoverUrl(String musicId) => _networkMeta[musicId]?.coverUrl;

  Music? getSongById(String id) {
    final local = _library.where((m) => m.id == id).firstOrNull;
    if (local != null) return local;

    final queued = _queue.where((m) => m.id == id).firstOrNull;
    if (queued != null) return queued;

    final netMeta = _networkMeta[id];
    if (netMeta != null) {
      return Music(
        id: id,
        title: netMeta.title,
        artist: netMeta.artist,
        duration: Duration.zero,
        coverBytes: null,
        lyrics: netMeta.lyricContent,
        album: null,
        source: MusicSource.network,
      );
    }
    return null;
  }

  bool isNetworkSong(String musicId) => _networkMeta.containsKey(musicId);
  Set<String> get networkSongIds => _networkMeta.keys.toSet();

  Future<void> playNetworkSearchResults({
    required List<Map<String, String?>> songs,
    required int startIndex,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty) return;

    final List<Music> newQueue = [];
    final List<NetworkSongMeta> storeMetas = [];

    for (final s in songs) {
      final musicId = 'net_${s['id']}';
      final title = s['title'] ?? '';
      final artist = s['artist'] ?? '';
      final url = s['url'] ?? '';
      final coverUrl = s['coverUrl'];
      final lyrics = s['lyrics'];

      final music = Music(
        id: musicId,
        title: title,
        artist: artist,
        duration: Duration.zero,
        coverBytes: null,
        lyrics: lyrics,
        album: null,
        source: MusicSource.network,
      );

      _networkMeta[musicId] = _NetworkSongMeta(
        url: url,
        title: title,
        artist: artist,
        coverUrl: coverUrl,
      )..lyricContent = lyrics;

      storeMetas.add(
        NetworkSongMeta(
          id: musicId,
          title: title,
          artist: artist,
          url: url,
          coverUrl: coverUrl,
          lyrics: lyrics,
          durationMs: 0,
        ),
      );

      newQueue.add(music);
    }

    NetworkSongStore().upsertAll(storeMetas);
    await replaceQueue(newQueue, startIndex: startIndex, autoPlay: autoPlay);
  }

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

    _networkMeta[musicId] = _NetworkSongMeta(
      url: url,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
    );

    final existingIndex = _queueIndexMap[musicId] ?? -1;
    final effectiveLyrics =
        lyricContent ??
        (existingIndex != -1 ? _queue[existingIndex].lyrics : null);

    _currentLyrics = await _parseLrc(effectiveLyrics);

    if (effectiveLyrics != null) {
      _networkMeta[musicId]?.lyricContent = effectiveLyrics;
    }

    if (existingIndex == -1) {
      _queue.add(music);
      _queueIndexMap[musicId] = _queue.length - 1;
    }
    _currentIndex = _queueIndexMap[musicId]!;

    _safeNotifyListeners();
    onMusicPlayed?.call(music);

    _debouncePersistNetworkSong(music, url, coverUrl, effectiveLyrics);

    // 第一次：音频流先走，封面传 null（防止403），updateAudioSource 保持默认的 true
    await audioHandler.playFromUrl(
      url,
      id: musicId,
      title: title,
      artist: artist,
      coverUrl: null,
      autoPlay: true,
    );

    // ⚡ 后台异步抓取安全封面
    final currentPlayingId = music.id;
    // 后台安全预缓存
    _getSafeArtUri(coverUrl).then((safeCoverUrl) {
      // 防御屏障：通过 getCoverUrl 查一下，如果发现当前 Provider 里的封面已经变成本地 file:// 了，说明已经热更新过了，坚决不准重复调用 playFromUrl！
      final currentCover = getCoverUrl(currentPlayingId);
      if (currentCover == safeCoverUrl) {
        // 已是最新的安全路径，直接拦截，拒绝再次调用
        return;
      }
      // 如果下载成功，且用户此时还没有切走歌（依然是当前这首歌）
      if (safeCoverUrl != null &&
          _currentIndex >= 0 &&
          _queue[_currentIndex].id == musicId) {
        debugPrint('--- [MusicProvider] 后台封面预缓存成功，动态热更新通知栏 ---');
        // 热更新底层通知栏的封面为本地 file://
        audioHandler.playFromUrl(
          url,
          id: musicId,
          title: title,
          artist: artist,
          coverUrl: safeCoverUrl,
          autoPlay: player.playing, // 保持当前的播放状态
          updateAudioSource: false, // 关键：不打断底层正在 loading 的音频流
        );
      }
    });
  }

  // 优化 1 的辅佐：500ms 防抖批处理写入
  void _debouncePersistNetworkSong(
    Music music,
    String url,
    String? coverUrl,
    String? lyrics,
  ) {
    final meta = NetworkSongMeta(
      id: music.id,
      title: music.title,
      artist: music.artist,
      url: url,
      coverUrl: coverUrl,
      lyrics: lyrics,
      durationMs: music.duration.inMilliseconds,
    );

    _persistQueue.removeWhere((item) => item.id == meta.id);
    _persistQueue.add(meta);

    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 500), () {
      if (_persistQueue.isNotEmpty) {
        NetworkSongStore().upsertAll(List.from(_persistQueue));
        _persistQueue.clear();
      }
    });
  }

  Future<void> loadPersistedNetworkSongs() async {
    try {
      final metas = await NetworkSongStore().loadAll();
      for (final meta in metas) {
        _networkMeta[meta.id] = _NetworkSongMeta(
          url: meta.url,
          title: meta.title,
          artist: meta.artist,
          coverUrl: meta.coverUrl,
        );
        if (meta.lyrics != null && meta.lyrics!.isNotEmpty) {
          _networkMeta[meta.id]?.lyricContent = meta.lyrics;
        }
      }
      debugPrint('Loaded ${metas.length} persisted network songs');
    } catch (e) {
      debugPrint('Failed to load persisted network songs: $e');
    }
  }

  Future<void> setLyricsDirectly(String lrcContent) async {
    _currentLyrics = await _parseLrc(lrcContent);
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      final music = _queue[_currentIndex];
      _networkMeta[music.id]?.lyricContent = lrcContent;
      music.lyrics = lrcContent;
    }
    _safeNotifyListeners();
  }

  String? getCachedLyrics(String musicId) =>
      _networkMeta[musicId]?.lyricContent;

  void _fetchLyricsInBackground(Music music) {
    Future<(String, bool)> lyricFuture;
    if (music.id.startsWith('net_')) {
      final numericId = music.id.substring(4);
      lyricFuture = NeteaseApi.getLyric(numericId).then((map) {
        final lrc = map['lyric'];
        return (lrc ?? '', lrc != null && lrc.isNotEmpty);
      });
    } else {
      lyricFuture = MusicApi.searchLyrics(music.artist, music.title);
    }

    lyricFuture
        .then((result) {
          final (lrc, found) = result;
          if (found && lrc.isNotEmpty) {
            _networkMeta[music.id]?.lyricContent = lrc;
            music.lyrics = lrc;

            _debouncePersistNetworkSong(
              music,
              _networkMeta[music.id]?.url ?? '',
              _networkMeta[music.id]?.coverUrl,
              lrc,
            );

            if (_currentIndex >= 0 &&
                _currentIndex < _queue.length &&
                _queue[_currentIndex].id == music.id) {
              _parseLrc(lrc).then((parsed) {
                _currentLyrics = parsed;
                _safeNotifyListeners(); // 💡 优化 3：此时内部已安全拦截 dispose
              });
            }
          }
        })
        .catchError((_) {});
  }

  PlayMode _playMode = PlayMode.sequence;
  PlayMode get playMode => _playMode;

  void togglePlayMode() {
    _playMode = switch (_playMode) {
      PlayMode.sequence => PlayMode.shuffle,
      PlayMode.shuffle => PlayMode.repeat,
      PlayMode.repeat => PlayMode.sequence,
    };
    _safeNotifyListeners();
  }

  Future<void> playNext() => _playNext(trigger: PlayTrigger.user);
  Future<void> playPrev() => _playPrev();

  Future<void> _playNext({PlayTrigger trigger = PlayTrigger.auto}) async {
    if (_queue.isEmpty) return;
    switch (_playMode) {
      case PlayMode.repeat:
        if (trigger == PlayTrigger.user) {
          await playByIndex((_currentIndex + 1) % _queue.length);
        } else {
          await player.seek(Duration.zero);
          player.play();
        }
      case PlayMode.shuffle:
        if (_queue.length <= 1) {
          await player.seek(Duration.zero);
          return;
        }
        int nextIndex = _currentIndex;
        while (nextIndex == _currentIndex) {
          nextIndex = Random().nextInt(_queue.length);
        }
        await playByIndex(nextIndex);
      case PlayMode.sequence:
        if (_currentIndex < _queue.length - 1) {
          await playByIndex(_currentIndex + 1);
        } else {
          if (trigger == PlayTrigger.user) {
            await playByIndex(0);
          } else {
            await player.seek(Duration.zero);
          }
        }
    }
  }

  Future<void> _playPrev() async {
    if (_queue.isEmpty) return;
    final prevIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await playByIndex(prevIndex);
  }

  Future<void> _loadAppInfo() async {
    _appInfo = await PackageInfo.fromPlatform();
    _safeNotifyListeners();
  }

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  @override
  void dispose() {
    _persistTimer?.cancel();
    _stateSubscription?.cancel();
    _stateSubscription2?.cancel();
    player.dispose();
    super.dispose();
  }
}
