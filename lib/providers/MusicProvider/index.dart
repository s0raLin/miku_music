import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/service/Audio/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// 数据模型
// ─────────────────────────────────────────────

/// 封装播放器的实时位置信息，供进度条 UI 使用。
class PositionData {
  /// 当前播放位置
  final Duration position;

  /// 已缓冲到的位置
  final Duration bufferedPosition;

  /// 歌曲总时长
  final Duration duration;

  const PositionData(this.position, this.bufferedPosition, this.duration);
}

/// 播放模式枚举
enum PlayMode {
  /// 顺序播放：播完最后一首停止
  sequence,

  /// 随机播放：从队列中随机选取下一首（不重复当前）
  shuffle,

  /// 单曲循环：当前歌曲播完后重新从头播放
  repeat,
}

/// 切歌触发来源枚举，用于区分用户主动操作和系统自动切换
enum PlayTrigger {
  /// 用户点击"上一首/下一首"触发
  user,

  /// 歌曲播放完毕，系统自动触发
  auto,
}

// ─────────────────────────────────────────────
// MusicProvider — 全局音乐播放状态管理
// ─────────────────────────────────────────────

/// 应用的核心音乐播放器 Provider。
///
/// 职责范围：
/// - 音频播放控制（播放、暂停、上一首、下一首、音量）
/// - 播放队列管理（增删、替换、随机/顺序/循环模式）
/// - 歌曲库与收藏列表维护
/// - 播放历史记录（最多 300 条，持久化到本地）
/// - 用户歌单 CRUD（含系统歌单：我喜欢、最近播放）
/// - LRC 歌词解析
/// - 应用版本信息加载
class MusicProvider extends ChangeNotifier {
  final MyAudioHandler audioHandler;
  // ───────────────────────────
  // 播放器核心
  // ───────────────────────────

  /// just_audio 播放器实例，整个 Provider 生命周期内唯一。
  // final AudioPlayer player = AudioPlayer();
  // 不再独立创建 AudioPlayer，而是直接共享后台服务的播放器
  AudioPlayer get player => audioHandler.player;

  /// 监听 [ProcessingState]，当 [ProcessingState.completed] 时自动切歌。
  StreamSubscription? _stateSubscription;

  /// 监听 [playingStream]，播放/暂停状态变化时通知 UI 刷新。
  StreamSubscription? _stateSubscription2;

  // ───────────────────────────
  // 应用信息
  // ───────────────────────────

  PackageInfo? _appInfo;

  PackageInfo? get appInfo => _appInfo;

  /// 当前应用版本号，未加载完成时显示占位文本。
  String get appVersion => _appInfo?.version ?? '加载中...';

  String get buildNumber => _appInfo?.buildNumber ?? '';

  /// 异步加载应用版本信息，完成后通知 UI。
  Future<void> _loadAppInfo() async {
    _appInfo = await PackageInfo.fromPlatform();
    notifyListeners();
  }

  // ───────────────────────────
  // 音量
  // ───────────────────────────

  double _volume = 1.0;

  /// 当前音量，范围 [0.0, 1.0]。
  double get volume => _volume;

  // ───────────────────────────
  // 歌曲库 & 队列
  // ───────────────────────────

  /// 全局歌曲库（从本地扫描或导入的所有歌曲）。
  final List<MusicInfo> _library = [];
  List<MusicInfo> get library => _library;

  /// 当前播放队列。
  List<MusicInfo> _queue = [];

  /// 当前正在播放的歌曲在队列中的下标，-1 表示未播放。
  int _currentIndex = -1;

  List<MusicInfo> get queue => _queue;

  /// 当前正在播放的歌曲，若队列为空或下标越界则返回 null。
  MusicInfo? get currentMusic {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  // ───────────────────────────
  // 播放历史
  // ───────────────────────────

  static const _historyKey = 'play_history';

  /// 播放历史列表，最新的在最前，最多保留 200 条。
  List<MusicInfo> _history = [];
  List<MusicInfo> get history => _history;

  // ───────────────────────────
  // 收藏列表
  // ───────────────────────────

  static const _favListKey = 'fav_list';

  List<MusicInfo> _favList = [];
  List<MusicInfo> get favList => _favList;

  // ───────────────────────────
  // 歌单管理
  // ───────────────────────────

  static const _playlistsKey = 'user_playlists';

  /// 系统歌单：我喜欢
  static const String _favoritesPlaylistId = 'system_favorites';

  /// 系统歌单：最近播放
  static const String _recentPlaylistId = 'system_recent';

  final List<Playlist> _playlists = [];

  List<Playlist> get playlists => _playlists;

  String get favoritesPlaylistId => _favoritesPlaylistId;
  String get recentPlaylistId => _recentPlaylistId;

  /// 用户自建歌单（排除系统歌单）。
  List<Playlist> get userPlaylists =>
      _playlists.where((p) => !p.isSystem).toList();

  /// 系统歌单列表。
  List<Playlist> get systemPlaylists =>
      _playlists.where((p) => p.isSystem).toList();

  /// 获取"我喜欢"系统歌单对象。
  Playlist? get favoritesPlaylist =>
      _playlists.firstWhere((p) => p.id == _favoritesPlaylistId);

  // ───────────────────────────
  // 歌词
  // ───────────────────────────

  /// 当前歌曲的歌词列表，每项包含 `time`（Duration）和 `text`（String）。
  List<Map<String, dynamic>> _currentLyrics = [];
  List<Map<String, dynamic>> get currentLyrics => _currentLyrics;

  // ─────────────────────────────────────────────
  // 构造函数
  // ─────────────────────────────────────────────

  MusicProvider({required this.audioHandler}) {
    // 歌曲播放完毕时自动切换到下一首
    _stateSubscription = player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _playNext();
    });

    // 播放状态（playing/paused）变化时刷新 UI
    _stateSubscription2 = player.playingStream.listen((_) {
      notifyListeners();
    });
  }

  Future<void> bootstrap({
    required List<MusicInfo> scannedSongs,
    void Function(String module, String detail)? onProgress,
  }) async {
    onProgress?.call('恢复媒体库', '已载入 ${scannedSongs.length} 首歌曲');
    _library
      ..clear()
      ..addAll(scannedSongs);
    notifyListeners();

    onProgress?.call('恢复播放历史', '正在读取历史记录');
    await _loadHistory();

    onProgress?.call('恢复收藏列表', '正在读取我喜欢列表');
    await _loadFavList();

    onProgress?.call('恢复用户歌单', '正在恢复歌单结构');
    await _loadPlaylists();

    _syncFavoritesPlaylist();
    notifyListeners();

    onProgress?.call('恢复音量设置', '正在同步播放器音量');
    await _loadVolume();

    onProgress?.call('读取应用信息', '正在获取版本号');
    await _loadAppInfo();
  }

  // 迷你播放栏
  bool _isMiniMode = false;
  bool get isMiniMode => _isMiniMode;

  void setMiniMode(bool value) {
    _isMiniMode = value;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 生命周期
  // ─────────────────────────────────────────────

  @override
  void dispose() {
    _stateSubscription?.cancel(); // 释放流订阅，避免内存泄漏
    _stateSubscription2?.cancel();
    player.dispose(); // 释放底层音频资源
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // 音量控制
  // ─────────────────────────────────────────────

  /// 从 SharedPreferences 读取上次保存的音量并应用到播放器。
  Future<void> _loadVolume() async {
    final pfs = await SharedPreferences.getInstance();
    _volume = pfs.getDouble('volume') ?? 1.0;
    player.setVolume(_volume);
    notifyListeners();
  }

  /// 设置音量并持久化，值会被钳制到 [0.0, 1.0]。
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await player.setVolume(_volume);
    final pfs = await SharedPreferences.getInstance();
    await pfs.setDouble('volume', _volume);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 歌词解析
  // ─────────────────────────────────────────────

  /// 将 LRC 格式歌词字符串解析为结构化列表。
  ///
  /// 支持标准 `[MM:SS.xx]` 时间标签格式，解析结果按时间升序排列。
  /// 若 [lrcContent] 为空则返回空列表。
  List<Map<String, dynamic>> _parseLrc(String? lrcContent) {
    if (lrcContent == null || lrcContent.isEmpty) return [];

    final lyrics = <Map<String, dynamic>>[];
    final regExp = RegExp(r'\[(\d+):(\d+\.\d+)\](.*)');

    for (final line in lrcContent.split('\n')) {
      final match = regExp.firstMatch(line);
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = double.parse(match.group(2)!);
        final text = match.group(3)!.trim();

        lyrics.add({
          'time': Duration(milliseconds: (min * 60000 + sec * 1000).toInt()),
          'text': text,
        });
      }
    }

    // 防止歌词文件中时间标签乱序
    lyrics.sort(
      (a, b) => (a['time'] as Duration).compareTo(b['time'] as Duration),
    );

    return lyrics;
  }

  Future<void> setCurrentLrc(String? lrcContent) async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;

    _queue[_currentIndex].lyrics = lrcContent;
    final currentMusic = _queue[_currentIndex];

    //调用解析器,将String转化成List<Map>
    _currentLyrics = _parseLrc(lrcContent);

    notifyListeners();

    //将歌词保存到歌曲目录,同名文件.lrc
    await MusicService.saveLyrics(lrcContent, currentMusic.id);
  }

  // ─────────────────────────────────────────────
  // 播放队列操作
  // ─────────────────────────────────────────────

  /// 检查指定歌曲是否已在播放队列中。
  bool isInQueue(String id) => _queue.any((m) => m.id == id);

  /// 将歌曲追加到队列末尾。
  void addToQueue(MusicInfo music) {
    _queue.add(music);
    notifyListeners();
  }

  /// 从队列中移除指定位置的歌曲。
  ///
  /// 不允许移除当前正在播放的歌曲。
  /// 若被移除的歌曲在当前播放位置之前，则同步更新 [_currentIndex]。
  void removeFromQueue(int index) {
    if (index == _currentIndex) return;
    _queue.removeAt(index);
    if (index < _currentIndex) _currentIndex--;
    notifyListeners();
  }

  /// 清空队列并停止播放。
  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    player.stop();
    notifyListeners();
  }

  /// 用新歌曲列表替换当前队列，并从 [startIndex] 开始播放。
  Future<void> replaceQueue(
    List<MusicInfo> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    // 1. 安全边界检查
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    // 真正需要换队列的情况
    _queue = List.from(songs);
    _currentIndex = -1;

    // 停止旧歌（注意：这里不要盲目立刻 notify，等新歌状态就绪一起通知，防止 UI 频繁重绘抖动）
    await player.stop();

    // 4. 载入或播放新队列中的目标歌曲
    await playByIndex(startIndex, autoPlay: autoPlay);
  }

  // ─────────────────────────────────────────────
  // 播放控制
  // ─────────────────────────────────────────────

  /// 从歌曲库中播放指定歌曲。
  ///
  /// - 若歌曲已在队列中，直接跳转至对应位置；
  /// - 否则追加到队尾后播放。
  void playFromLibrary(MusicInfo music, {bool autoPlay = true}) {
    // 检查这首歌是否就是当前队列中正在激活的歌
    final isCurrentMusic =
        _currentIndex != -1 && _queue[_currentIndex].id == music.id;

    if (isCurrentMusic) {
      // if (autoPlay) {
      //   if (player.playing) {
      //     togglePlay(); // 如果正在播放，直接暂停
      //   } else {
      //     togglePlay(); // 如果暂停了，直接让它继续播放
      //   }
      // }
      // 如果 autoPlay 为 false 且是同一首歌，什么都不做，直接退出，防止切歌断音
      return;
    }

    // 如果不是当前正在播放的歌，走原有的逻辑
    final existingIndex = _queue.indexWhere((m) => m.id == music.id);

    if (existingIndex != -1) {
      playByIndex(existingIndex, autoPlay: autoPlay);
    } else {
      _queue.add(music);
      playByIndex(_queue.length - 1, autoPlay: autoPlay);
    }
  }

  /// 按队列下标播放歌曲。
  ///
  /// 同时负责：
  /// 1. 更新 [_currentIndex]
  /// 2. 解析并更新歌词 [_currentLyrics]
  /// 3. 将歌曲写入播放历史
  /// 4. 加载音频文件并开始播放
  Future<void> playByIndex(int index, {bool autoPlay = true}) async {
    if (index < 0 || index >= _queue.length) return;
    // 同一首歌且正在播放时不重复操作
    if (index == _currentIndex && player.playing && autoPlay) return;

    _currentIndex = index;
    final music = _queue[index];

    // 解析歌词（必须创建新列表实例，确保 Provider selector 能检测到变化）
    _currentLyrics = _parseLrc(music.lyrics);

    // 先通知 UI 更新歌词，再执行耗时的音频加载
    notifyListeners();

    if (autoPlay) {
      _addToHistory(music);
      audioHandler.playMusic(music);
    } else {
      audioHandler.playMusic(music, autoPlay: false);
    }
  }

  /// 切换播放 / 暂停状态。
  void togglePlay() {
    if (player.playing) {
      player.pause(); // 如果正在播放，直接暂停
    } else {
      player.play(); // 如果暂停了，直接让它继续播放
    }

    notifyListeners();
  }

  // ───────────────────────────
  // 播放模式
  // ───────────────────────────

  PlayMode _playMode = PlayMode.sequence;

  /// 当前播放模式。
  PlayMode get playMode => _playMode;

  /// 循环切换播放模式：顺序 → 随机 → 单曲循环 → 顺序。
  void togglePlayMode() {
    _playMode = switch (_playMode) {
      PlayMode.sequence => PlayMode.shuffle,
      PlayMode.shuffle => PlayMode.repeat,
      PlayMode.repeat => PlayMode.sequence,
    };
    notifyListeners();
  }

  // ───────────────────────────
  // 上一首 / 下一首
  // ───────────────────────────

  /// 播放下一首（用户主动触发）。
  Future<void> playNext() => _playNext(trigger: PlayTrigger.user);

  /// 播放上一首。
  Future<void> playPrev() => _playPrev();

  /// 切换到下一首的内部实现，行为受 [PlayMode] 和 [trigger] 共同决定：
  ///
  /// - [PlayMode.repeat]：
  ///   - 自动触发 → 从头循环当前歌曲
  ///   - 用户触发 → 播放队列中的下一首
  /// - [PlayMode.shuffle]：从剩余歌曲中随机选取一首
  /// - [PlayMode.sequence]：
  ///   - 未到末尾 → 顺序播放下一首
  ///   - 已是末尾 & 用户触发 → 跳回第一首
  ///   - 已是末尾 & 自动触发 → 停止播放
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
        // 排除当前歌曲后随机选取
        final candidates = List.generate(_queue.length, (i) => i)
          ..remove(_currentIndex);
        if (candidates.isEmpty) return;
        await playByIndex(candidates[Random().nextInt(candidates.length)]);

      case PlayMode.sequence:
        if (_currentIndex < _queue.length - 1) {
          await playByIndex(_currentIndex + 1);
        } else {
          if (trigger == PlayTrigger.user) {
            await playByIndex(0); // 用户点击：跳回第一首
          } else {
            await player.seek(Duration.zero); // 自动触发：停在末尾
          }
        }
    }
  }

  /// 播放上一首，支持循环回到队列末尾。
  Future<void> _playPrev() async {
    if (_queue.isEmpty) return;
    final prevIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    await playByIndex(prevIndex);
  }

  // ─────────────────────────────────────────────
  // 收藏列表
  // ─────────────────────────────────────────────

  /// 切换歌曲收藏状态：已收藏则取消，未收藏则加入。
  Future<void> toggleFav(MusicInfo music) async {
    final isExist = _favList.any((m) => m.id == music.id);

    if (isExist) {
      _favList.removeWhere((m) => m.id == music.id);
    } else {
      _favList.add(music);
    }

    await _saveFavList();
    notifyListeners();
  }

  /// 将收藏列表 ID 持久化，并同步更新"我喜欢"系统歌单。
  Future<void> _saveFavList() async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setStringList(_favListKey, _favList.map((m) => m.id).toList());
    _syncFavoritesPlaylist();
  }

  Future<void> _loadFavList() async {
    final pfs = await SharedPreferences.getInstance();
    final ids = pfs.getStringList(_favListKey) ?? [];

    _favList = ids
        .map((id) => _library.firstWhereOrNull((m) => m.id == id))
        .whereType<MusicInfo>()
        .toList();

    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 播放历史
  // ─────────────────────────────────────────────

  /// 从 SharedPreferences 读取历史 ID 并映射到歌曲库中的对象。
  /// 歌曲已被删除时自动过滤。
  Future<void> _loadHistory() async {
    final pfs = await SharedPreferences.getInstance();
    final ids = pfs.getStringList(_historyKey) ?? [];

    _history = ids
        .map((id) => _library.firstWhereOrNull((m) => m.id == id))
        .whereType<MusicInfo>()
        .toList();

    notifyListeners();
  }

  /// 将歌曲追加到历史列表头部，自动去重并限制上限为 200 条。
  Future<void> _addToHistory(MusicInfo music) async {
    _history.removeWhere((m) => m.id == music.id);
    _history.insert(0, music);
    if (_history.length > 200) _history.removeLast();
    await _saveHistory();
    notifyListeners();
  }

  /// 持久化历史 ID 列表到本地。
  Future<void> _saveHistory() async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setStringList(_historyKey, _history.map((m) => m.id).toList());
  }

  /// 清空播放历史并从本地存储中删除。
  Future<void> clearHistory() async {
    _history.clear();
    final pfs = await SharedPreferences.getInstance();
    await pfs.remove(_historyKey);
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 歌单管理
  // ─────────────────────────────────────────────

  void addNetworkPlaylists(List<Playlist> playlists) {
    _playlists.addAll(playlists);
    notifyListeners();
  }

  /// 从 SharedPreferences 读取所有歌单，并确保系统歌单存在。
  Future<void> _loadPlaylists() async {
    final pfs = await SharedPreferences.getInstance();
    final playlistStrings = pfs.getStringList(_playlistsKey) ?? [];

    _playlists.clear();
    for (final str in playlistStrings) {
      try {
        _playlists.add(Playlist.fromSerializedString(str));
      } catch (_) {
        // 跳过格式损坏的歌单数据
      }
    }

    _ensureSystemPlaylists();
    notifyListeners();
  }

  /// 将所有歌单序列化并持久化到本地。
  Future<void> _savePlaylists() async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setStringList(
      _playlistsKey,
      _playlists.map((p) => p.toSerializedString()).toList(),
    );
  }

  /// 确保"我喜欢"和"最近播放"两个系统歌单始终存在。
  void _ensureSystemPlaylists() {
    if (!_playlists.any((p) => p.id == _favoritesPlaylistId)) {
      _playlists.add(
        Playlist(
          id: _favoritesPlaylistId,
          name: '我喜欢',
          description: '收藏的歌曲',
          isSystem: true,
          songIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (!_playlists.any((p) => p.id == _recentPlaylistId)) {
      _playlists.add(
        Playlist(
          id: _recentPlaylistId,
          name: '最近播放',
          description: '最近播放的歌曲',
          isSystem: true,
          songIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  /// 将"我喜欢"系统歌单的 songIds 与 [_favList] 保持同步。
  void _syncFavoritesPlaylist() {
    final index = _playlists.indexWhere((p) => p.id == _favoritesPlaylistId);
    if (index == -1) return;

    _playlists[index] = _playlists[index].copyWith(
      songIds: _favList.map((m) => m.id).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// 将"历史"系统歌单的 songIds 与 [_favList] 保持同步。

  /// 创建一个新用户歌单，返回生成的歌单 ID。
  String createPlaylist(String name, {String? description}) {
    final id = 'user_${DateTime.now().microsecondsSinceEpoch}';
    _playlists.add(
      Playlist(
        id: id,
        name: name,
        description: description,
        isSystem: false,
        songIds: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    _savePlaylists();
    notifyListeners();
    return id;
  }

  /// 删除指定歌单。系统歌单（如"我喜欢"）不可删除。
  void deletePlaylist(String id) {
    if (id == _favoritesPlaylistId) return;
    _playlists.removeWhere((p) => p.id == id);
    _savePlaylists();
    notifyListeners();
  }

  /// 重命名指定歌单。
  void renamePlaylist(String id, String newName) {
    final index = _playlists.indexWhere((p) => p.id == id);
    if (index == -1) return;

    _playlists[index] = _playlists[index].copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );
    _savePlaylists();
    notifyListeners();
  }

  /// 将歌曲添加到指定歌单，已存在则跳过（去重）。
  void addToPlaylist(String playlistId, MusicInfo music) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];
    if (playlist.songIds.contains(music.id)) return;

    _playlists[index] = playlist.copyWith(
      songIds: [...playlist.songIds, music.id],
      updatedAt: DateTime.now(),
    );
    _savePlaylists();
    notifyListeners();
  }

  /// 从指定歌单中移除歌曲。
  void removeFromPlaylist(String playlistId, String musicId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return;

    final playlist = _playlists[index];
    _playlists[index] = playlist.copyWith(
      songIds: playlist.songIds.where((id) => id != musicId).toList(),
      updatedAt: DateTime.now(),
    );
    _savePlaylists();
    notifyListeners();
  }

  /// 获取指定歌单中的歌曲对象列表。
  ///
  /// 系统歌单直接返回对应内存列表；用户歌单从歌曲库映射，已删除的歌曲自动过滤。
  List<MusicInfo> getPlaylistSongs(String playlistId) {
    final playlist = _playlists.firstWhere((p) => p.id == playlistId);

    if (playlist.isSystem) {
      if (playlistId == _favoritesPlaylistId) return _favList;
      if (playlistId == _recentPlaylistId) return _history;
    }

    return playlist.songIds
        .map((id) => _library.firstWhereOrNull((m) => m.id == id))
        .whereType<MusicInfo>()
        .toList();
  }

  /// 通过 ID 查找歌单，未找到返回 null。
  Playlist? getPlaylistById(String id) {
    try {
      return _playlists.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────
  // 响应式数据流
  // ─────────────────────────────────────────────

  /// 合并播放位置、缓冲位置、总时长三路流，输出 [PositionData]，供进度条组件订阅。
  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );
}
