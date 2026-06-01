import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Audio/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/src/rust/api/audio_info.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  const PositionData(this.position, this.bufferedPosition, this.duration);
}

enum PlayMode { sequence, shuffle, repeat }

enum PlayTrigger { user, auto }

class MusicProvider extends ChangeNotifier {
  final MyAudioHandler audioHandler;

  AudioPlayer get player => audioHandler.player;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _stateSubscription2;

  PackageInfo? _appInfo;
  PackageInfo? get appInfo => _appInfo;
  String get appVersion => _appInfo?.version ?? '加载中...';
  String get buildNumber => _appInfo?.buildNumber ?? '';

  double _volume = 1.0;
  double get volume => _volume;

  // ───────────────────────────
  // 歌曲库 & 核心播放队列
  // ───────────────────────────
  List<Music> _library = [];
  List<Music> get library => _library;

  List<Music> _queue = [];
  int _currentIndex = -1;
  List<Music> get queue => _queue;

  Music? get currentMusic {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  List<LyricLine> _currentLyrics = [];
  List<LyricLine> get currentLyrics => _currentLyrics;

  bool _isMiniMode = false;
  bool get isMiniMode => _isMiniMode;

  MusicProvider({required this.audioHandler}) {
    _stateSubscription = player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _playNext();
    });
    _stateSubscription2 = player.playingStream.listen((_) {
      notifyListeners();
    });
  }

  Future<void> bootstrap({
    required List<Music> scannedSongs,
    void Function(String module, String detail)? onProgress,
  }) async {
    onProgress?.call('恢复媒体库', '已载入 ${scannedSongs.length} 首歌曲');
    _library
      ..clear()
      ..addAll(scannedSongs);
    notifyListeners();

    onProgress?.call('恢复音量设置', '正在同步播放器音量');
    await _loadVolume();

    onProgress?.call('读取应用信息', '正在获取版本号');
    await _loadAppInfo();
  }

  /// 全局更新与合并歌曲库（彻底解决流式扫描与按需懒加载的冲突）
  void updateLibrary(List<Music> scannedSongs) {
    // 1. 先把现有的、内存里【已经饱含懒加载封面】的旧歌存入 Map
    final Map<String, Music> uniqueMap = {
      for (var song in _library) song.id: song,
    };

    // 2. 遍历新扫出来的歌曲
    for (var newSong in scannedSongs) {
      final oldSong = uniqueMap[newSong.id];

      if (oldSong != null) {
        // 提取旧歌和新歌的封面状态
        final hasOldCover =
            oldSong.coverBytes != null && oldSong.coverBytes!.isNotEmpty;
        final hasNewCover =
            newSong.coverBytes != null && newSong.coverBytes!.isNotEmpty;

        // 核心保护：如果内存中的老歌已经有了封面（不管是播放时洗出来的，还是滑到可见区域懒加载出来的）
        // 而新扫出来的对象封面是 null，绝对不允许覆盖！利用 copyWith 让新歌继承原有的封面。
        if (hasOldCover && !hasNewCover) {
          uniqueMap[newSong.id] = newSong.copyWith(
            coverBytes: oldSong.coverBytes,
            // 同理：如果旧歌已经有了懒加载的歌词，新歌没有，也可以顺手保留
            lyrics: (newSong.lyrics == null || newSong.lyrics!.isEmpty)
                ? oldSong.lyrics
                : newSong.lyrics,
          );
          continue; // 封面已完美继承，直接跳过后面的无脑覆盖
        }
      }

      // 只有当这是首全新歌，或者新歌确实带了新封面时，才允许写入/覆盖
      uniqueMap[newSong.id] = newSong;
    }

    // 3. 直接赋新引用，触发 context.select 粒度化重绘
    _library = uniqueMap.values.toList();
    notifyListeners();
  }

  void setMiniMode(bool value) {
    _isMiniMode = value;
    notifyListeners();
  }

  // ─────────────────────────────────────────────
  // 音频业务控制
  // ─────────────────────────────────────────────
  Future<void> _loadVolume() async {
    final pfs = await SharedPreferences.getInstance();
    _volume = pfs.getDouble('volume') ?? 1.0;
    player.setVolume(_volume);
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await player.setVolume(_volume);
    final pfs = await SharedPreferences.getInstance();
    await pfs.setDouble('volume', _volume);
    notifyListeners();
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
    notifyListeners();
    await MusicService.saveLyrics(lrcContent, curMusic.id);
  }

  bool isInQueue(String id) => _queue.any((m) => m.id == id);

  void addToQueue(Music music) {
    _queue.add(music);
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    // 1. 记住当前正在播放的歌曲实例
    final playingMusic = currentMusic;

    // 2. 核心：如果从上往下拖动，说明目标位置在旧位置后面。
    // 由于底层组件已经帮你为“移除老元素”扣掉了一位，导致 newIndex 偏小，
    // 我们在这里强行 +1 纠正，把它推到你眼睛看到的那个元素的“后面”。
    if (newIndex > oldIndex) {
      newIndex += 1;
    }

    // 3. 执行标准的取出、插入动作
    final song = _queue.removeAt(oldIndex);

    // 安全边界处理：确保 insert 的位置不会越界
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _queue.insert(targetIndex.clamp(0, _queue.length), song);

    // 4. 重新死死咬住当前播放歌曲的指针，确保封面、状态绝不错乱
    if (playingMusic != null) {
      _currentIndex = _queue.indexWhere((m) => m.id == playingMusic.id);
    }

    notifyListeners(); // 5. 刷新全局 UI
  }

  void removeFromQueue(int index) {
    if (index == _currentIndex) return;
    _queue.removeAt(index);
    if (index < _currentIndex) _currentIndex--;
    notifyListeners();
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    player.stop();
    notifyListeners();
  }

  // 1. 定义一个切歌时的通知钩子
  void Function(Music song)? onMusicPlayed;

  Future<void> replaceQueue(
    List<Music> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;
    _queue = List.from(songs);
    _currentIndex = -1;
    await player.stop();
    await playByIndex(startIndex, autoPlay: autoPlay);
  }

  void playFromLibrary(Music music, {bool autoPlay = true}) {
    final isCurrentMusic =
        _currentIndex != -1 && _queue[_currentIndex].id == music.id;
    if (isCurrentMusic) return;

    final existingIndex = _queue.indexWhere((m) => m.id == music.id);
    if (existingIndex != -1) {
      playByIndex(existingIndex, autoPlay: autoPlay);
    } else {
      _queue.add(music);
      playByIndex(_queue.length - 1, autoPlay: autoPlay);
    }
  }

  Future<void> playByIndex(int index, {bool autoPlay = true}) async {
    if (index < 0 || index >= _queue.length) return;
    if (index == _currentIndex && player.playing && autoPlay) return;

    _currentIndex = index;
    final music = _queue[index];
    _currentLyrics = await _parseLrc(music.lyrics);
    notifyListeners();

    if (music.coverBytes == null || music.coverBytes!.isEmpty) {
      MusicService.parse(music.id)
          .then((updated) {
            // 触发封面更新方法
            _updateCoverBytes(music.id, updated.coverBytes);
          })
          .catchError((_) {});
    }

    if (autoPlay) {
      // _addToHistory(music);
      // 核心：触发外部钩子，通知最近播放列表
      onMusicPlayed?.call(music);
      audioHandler.playMusic(music);
    } else {
      audioHandler.playMusic(music, autoPlay: false);
    }
  }

  // ==========================================
  // 1. 在 MusicProvider 内部添加解析锁集合
  // ==========================================
  final Set<String> _loadingCoverIds = {};

  /// 查询某首歌曲当前是否正在后台解析封面
  bool isCoverLoading(String musicId) {
    return _loadingCoverIds.contains(musicId);
  }

  // MusicProvider 里加一个"已经尝试过、但确实没有封面"的集合
  final Set<String> _noCoverIds = {};

  bool hasNoCover(String musicId) => _noCoverIds.contains(musicId);

  Future<void> loadCoverLazy(String musicId) async {
    // 新增：已确认无封面的歌曲，直接放行，不再重试
    if (_noCoverIds.contains(musicId)) return;
    if (_loadingCoverIds.contains(musicId)) return;

    _loadingCoverIds.add(musicId);
    notifyListeners(); // 让 isLoading 立即变 true

    try {
      final updated = await MusicService.parse(musicId);
      if (updated.coverBytes != null && updated.coverBytes!.isNotEmpty) {
        _updateCoverBytes(musicId, updated.coverBytes);
      } else {
        // 解析完了，但确实没有封面，记录进黑名单，不再重试
        _noCoverIds.add(musicId);
      }
    } catch (e) {
      debugPrint('懒加载音频封面失败 [$musicId]: $e');
      // 失败也加入黑名单，避免每次 build 都重试
      _noCoverIds.add(musicId);
    } finally {
      _loadingCoverIds.remove(musicId);
      notifyListeners();
    }
  }

  void _updateCoverBytes(String musicId, Uint8List? coverBytes) {
    if (coverBytes == null || coverBytes.isEmpty) return;

    bool hasChanged = false;

    void patch(List<Music> list) {
      final index = list.indexWhere((m) => m.id == musicId);
      if (index != -1) {
        // 只有在真的没有封面时才赋值，避免无意义的指针覆盖
        if (list[index].coverBytes == null || list[index].coverBytes!.isEmpty) {
          list[index].coverBytes = coverBytes;
          hasChanged = true;
        }
      }
    }

    patch(_library);
    patch(_queue);

    // 只有数据真正被动过，才通知视图刷新，防止切歌或高频更新时的全局无效重绘
    if (hasChanged) {
      notifyListeners();
    }
  }

  void togglePlay() {
    player.playing ? player.pause() : player.play();
    notifyListeners();
  }

  PlayMode _playMode = PlayMode.sequence;
  PlayMode get playMode => _playMode;

  void togglePlayMode() {
    _playMode = switch (_playMode) {
      PlayMode.sequence => PlayMode.shuffle,
      PlayMode.shuffle => PlayMode.repeat,
      PlayMode.repeat => PlayMode.sequence,
    };
    notifyListeners();
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
        final candidates = List.generate(_queue.length, (i) => i)
          ..remove(_currentIndex);
        if (candidates.isEmpty) return;
        await playByIndex(candidates[Random().nextInt(candidates.length)]);
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

  /// 异步加载应用版本信息，完成后通知 UI。
  Future<void> _loadAppInfo() async {
    _appInfo = await PackageInfo.fromPlatform();
    notifyListeners();
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
    _stateSubscription?.cancel();
    _stateSubscription2?.cancel();
    player.dispose();
    super.dispose();
  }
}
