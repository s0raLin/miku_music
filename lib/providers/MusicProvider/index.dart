import 'dart:async';
import 'dart:math';
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

  const _NetworkSongMeta({
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

  final Set<String> _loadingCoverIds = {};
  final Set<String> _noCoverIds = {};

  MusicProvider({required this.audioHandler}) {
    _stateSubscription = player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _playNext();
    });

    _stateSubscription2 = player.playingStream.listen((_) {
      // 💡 优化 1：流监听通知属于外部事件，必须走安全期调度
      _safeNotifyListeners();
    });
  }

  /// 核心防御防线：提供一个绝对安全的通知机制，规避 Build 期的各种背压与撞车
  void _safeNotifyListeners() {
    final binding = WidgetsBinding.instance;
    // 如果当前正处于 Build 阶段，把通知任务放到下一帧结束时的微任务/宏任务队列中
    if (binding.schedulerPhase == SchedulerPhase.midFrameMicrotasks ||
        binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }

  Future<void> bootstrap({
    required List<Music> scannedSongs,
    void Function(String module, String detail)? onProgress,
  }) async {
    //快捷键
    HotkeyService().init(
      onNextTrack: () => playNext(),
      onTogglePlay: () => togglePlay(),
      onPrevTrack: () => playPrev(),
    );

    onProgress?.call('恢复媒体库', '已载入 ${scannedSongs.length} 首歌曲');
    _library
      ..clear()
      ..addAll(scannedSongs);
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
        list.sort((a, b) => (a.title).compareTo(b.title));
        break;
      case SongSortType.nameDesc:
        list.sort((a, b) => (b.title).compareTo(a.title));
        break;
      case SongSortType.artistAsc:
        list.sort((a, b) => (a.artist).compareTo(b.artist));
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

  bool isInQueue(String id) => _queue.any((m) => m.id == id);

  void addToQueue(Music music) {
    _queue.add(music);
    _safeNotifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    final playingMusic = currentMusic;

    if (newIndex > oldIndex) {
      newIndex += 1;
    }

    final song = _queue.removeAt(oldIndex);
    final targetIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    _queue.insert(targetIndex.clamp(0, _queue.length), song);

    if (playingMusic != null) {
      _currentIndex = _queue.indexWhere((m) => m.id == playingMusic.id);
    }
    _safeNotifyListeners();
  }

  void removeFromQueue(int index) {
    if (index == _currentIndex) return;
    _queue.removeAt(index);
    if (index < _currentIndex) _currentIndex--;
    _safeNotifyListeners();
  }

  void clearQueue() {
    _queue.clear();
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
    _safeNotifyListeners(); // 这里已经通过安全机制发出通知

    if (music.coverBytes == null || music.coverBytes!.isEmpty) {
      // 💡 优化 2：切歌时的解析同样需要受控，直接重用规范的懒加载方法
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadCoverLazy(music.id);
      });
    }

    // 检查是否为网络歌曲：有 _networkMeta 记录的说明需要用 URL 播放
    final netMeta = _networkMeta[music.id];
    if (netMeta != null) {
      // 网络歌曲：使用 URL 播放
      if (autoPlay) {
        onMusicPlayed?.call(music);
        await audioHandler.playFromUrl(
          netMeta.url,
          id: music.id,
          title: netMeta.title,
          artist: netMeta.artist,
          coverUrl: netMeta.coverUrl,
          autoPlay: true,
        );
      } else {
        await audioHandler.playFromUrl(
          netMeta.url,
          id: music.id,
          title: netMeta.title,
          artist: netMeta.artist,
          coverUrl: netMeta.coverUrl,
          autoPlay: false,
        );
      }
    } else {
      // 本地歌曲：使用文件路径播放
      if (autoPlay) {
        onMusicPlayed?.call(music);
        audioHandler.playMusic(music);
      } else {
        audioHandler.playMusic(music, autoPlay: false);
      }
    }
  }

  bool isCoverLoading(String musicId) => _loadingCoverIds.contains(musicId);
  bool hasNoCover(String musicId) => _noCoverIds.contains(musicId);

  Future<void> loadCoverLazy(String musicId) async {
    if (_noCoverIds.contains(musicId)) return;
    if (_loadingCoverIds.contains(musicId)) return;

    _loadingCoverIds.add(musicId);
    _safeNotifyListeners(); // 💡 改用安全通知

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
      _safeNotifyListeners(); // 💡 改用安全通知
    }
  }

  void _updateCoverBytes(String musicId, Uint8List? coverBytes) {
    if (coverBytes == null || coverBytes.isEmpty) return;

    bool hasChanged = false;
    void patch(List<Music> list) {
      final index = list.indexWhere((m) => m.id == musicId);
      if (index != -1) {
        if (list[index].coverBytes == null ||
            list[index].coverBytes!.isNotEmpty == false) {
          list[index].coverBytes = coverBytes;
          hasChanged = true;
        }
      }
    }

    patch(_library);
    patch(_queue);

    if (hasChanged) {
      _safeNotifyListeners(); // 💡 封面突变更新，改用安全通知
    }
  }

  void togglePlay() {
    player.playing ? player.pause() : player.play();
    _safeNotifyListeners();
  }

  /// Map to store network URLs for songs added via playNetworkSong
  final Map<String, _NetworkSongMeta> _networkMeta = {};

  /// Get the cover URL for a network song, if available.
  String? getCoverUrl(String musicId) => _networkMeta[musicId]?.coverUrl;

  /// Play a network song (e.g. from Netease cloud search).
  /// Adds a synthetic Music to the queue so currentMusic + detail page work.
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
    );

    // Store network metadata for later playback (prev/next)
    _networkMeta[musicId] = _NetworkSongMeta(
      url: url,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
    );

    _currentLyrics = await _parseLrc(lyricContent);

    // Add to queue if not already there
    if (!_queue.any((m) => m.id == musicId)) {
      _queue.add(music);
    }
    _currentIndex = _queue.indexWhere((m) => m.id == musicId);

    _safeNotifyListeners();

    await audioHandler.playFromUrl(
      url,
      id: musicId,
      title: title,
      artist: artist,
      coverUrl: coverUrl,
      autoPlay: true,
    );
  }

  /// Set lyrics directly (for network playback without queue)
  Future<void> setLyricsDirectly(String lrcContent) async {
    _currentLyrics = await _parseLrc(lrcContent);
    _safeNotifyListeners();
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
    _stateSubscription?.cancel();
    _stateSubscription2?.cancel();
    player.dispose();
    super.dispose();
  }
}
