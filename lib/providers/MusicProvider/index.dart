import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
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
  final List<MusicInfo> _library = [];
  List<MusicInfo> get library => _library;

  List<MusicInfo> _queue = [];
  int _currentIndex = -1;
  List<MusicInfo> get queue => _queue;

  MusicInfo? get currentMusic {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  // ───────────────────────────
  // 基础状态持久化（仅用于直接切歌/打星收藏）
  // ───────────────────────────
  // static const _historyKey = 'play_history';
  // static const _favListKey = 'fav_list';

  // List<MusicInfo> _history = [];
  // List<MusicInfo> get history => _history;

  // List<MusicInfo> _favList = [];
  // List<MusicInfo> get favList => _favList;

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
    required List<MusicInfo> scannedSongs,
    void Function(String module, String detail)? onProgress,
  }) async {
    onProgress?.call('恢复媒体库', '已载入 ${scannedSongs.length} 首歌曲');
    _library
      ..clear()
      ..addAll(scannedSongs);
    notifyListeners();

    // onProgress?.call('恢复播放历史', '正在读取历史记录');
    // await _loadHistory();

    // onProgress?.call('恢复收藏列表', '正在读取我喜欢列表');
    // await _loadFavList();

    onProgress?.call('恢复音量设置', '正在同步播放器音量');
    await _loadVolume();

    onProgress?.call('读取应用信息', '正在获取版本号');
    await _loadAppInfo();
  }

  void updateLibrary(List<MusicInfo> scannedSongs) {
    final Map<String, MusicInfo> uniqueMap = {};
    for (var song in _library) {
      uniqueMap[song.id] = song;
    }
    for (var song in scannedSongs) {
      uniqueMap[song.id] = song;
    }
    _library
      ..clear()
      ..addAll(uniqueMap.values);
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

  void addToQueue(MusicInfo music) {
    _queue.add(music);
    notifyListeners();
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
  void Function(MusicInfo song)? onMusicPlayed;

  Future<void> replaceQueue(
    List<MusicInfo> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;
    _queue = List.from(songs);
    _currentIndex = -1;
    await player.stop();
    await playByIndex(startIndex, autoPlay: autoPlay);
  }

  void playFromLibrary(MusicInfo music, {bool autoPlay = true}) {
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
            // 🌟 触发封面更新方法
            updateCoverBytes(music.id, updated.coverBytes);
          })
          .catchError((_) {});
    }

    if (autoPlay) {
      // _addToHistory(music);
      // 🌟 核心：触发外部钩子，通知最近播放列表
      onMusicPlayed?.call(music);
      audioHandler.playMusic(music);
      audioHandler.playMusic(music);
    } else {
      audioHandler.playMusic(music, autoPlay: false);
    }
  }

  void updateCoverBytes(String musicId, Uint8List? coverBytes) {
    if (coverBytes == null || coverBytes.isEmpty) return;
    void patch(List<MusicInfo> list) {
      final index = list.indexWhere((m) => m.id == musicId);
      if (index != -1) list[index].coverBytes = coverBytes;
    }

    patch(_library);
    patch(_queue);
    // patch(_history);
    // patch(_favList);
    notifyListeners();
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

  // ─────────────────────────────────────────────
  // 喜好与历史基础存储
  // ─────────────────────────────────────────────
  // Future<void> toggleFav(MusicInfo music) async {
  //   final isExist = _favList.any((m) => m.id == music.id);
  //   if (isExist) {
  //     _favList.removeWhere((m) => m.id == music.id);
  //   } else {
  //     _favList.add(music);
  //   }
  //   notifyListeners();
  // }

  // Future<void> _loadFavList() async {
  //   final pfs = await SharedPreferences.getInstance();
  //   final ids = pfs.getStringList(_favListKey) ?? [];
  //   _favList = ids
  //       .map((id) => _library.firstWhereOrNull((m) => m.id == id))
  //       .whereType<MusicInfo>()
  //       .toList();
  //   notifyListeners();
  // }

  // Future<void> _loadHistory() async {
  //   final pfs = await SharedPreferences.getInstance();
  //   final ids = pfs.getStringList(_historyKey) ?? [];
  //   _history = ids
  //       .map((id) => _library.firstWhereOrNull((m) => m.id == id))
  //       .whereType<MusicInfo>()
  //       .toList();
  //   notifyListeners();
  // }

  // Future<void> _addToHistory(MusicInfo music) async {
  //   _history.removeWhere((m) => m.id == music.id);
  //   _history.insert(0, music);
  //   if (_history.length > 200) _history.removeLast();
  //   await _saveHistory();
  //   notifyListeners();
  // }

  // Future<void> _saveHistory() async {
  //   final pfs = await SharedPreferences.getInstance();
  //   await pfs.setStringList(_historyKey, _history.map((m) => m.id).toList());
  // }

  // Future<void> clearHistory() async {
  //   _history.clear();
  //   final pfs = await SharedPreferences.getInstance();
  //   await pfs.remove(_historyKey);
  //   notifyListeners();
  // }

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
