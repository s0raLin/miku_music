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

import 'library_service.dart';
import 'music_repository.dart';
import 'playback_queue.dart';

// ── Re-export for existing callers (no import changes needed) ──
export 'library_service.dart' show SongSortType, AlbumSortType;
export 'playback_queue.dart' show PlayMode, PlayTrigger;

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  const PositionData(this.position, this.bufferedPosition, this.duration);
}

class MusicProvider extends ChangeNotifier {
  final MyAudioHandler audioHandler;

  AudioPlayer get player => audioHandler.player;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _stateSubscription2;

  // ── delegates ──
  final PlaybackQueue _playbackQueue = PlaybackQueue();
  final LibraryService _libraryService = LibraryService();
  final MusicRepository _repository = MusicRepository();

  // ── library ──
  List<Music> _library = [];
  List<Music> get library => _library;

  // ── sort preferences ──
  SongSortType _songSortType = SongSortType.auto;
  AlbumSortType _albumSortType = AlbumSortType.nameAsc;

  SongSortType get songSortType => _songSortType;
  AlbumSortType get albumSortType => _albumSortType;

  // ── queue accessors (pass-through) ──
  List<Music> get queue => _playbackQueue.queue;
  Music? get currentMusic => _playbackQueue.currentMusic;
  bool isInQueue(String id) => _playbackQueue.contains(id);
  PlayMode get playMode => _playbackQueue.playMode;

  // ── lyrics ──
  List<LyricLine> _currentLyrics = [];
  List<LyricLine> get currentLyrics => _currentLyrics;

  // ── mini mode ──
  bool _isMiniMode = false;
  bool get isMiniMode => _isMiniMode;

  // ── app info (pass-through) ──
  PackageInfo? get appInfo => _repository.appInfo;
  String get appVersion => _repository.appVersion;
  String get buildNumber => _repository.buildNumber;

  // ── cover helpers (pass-through) ──
  bool isCoverLoading(String musicId) => _repository.isCoverLoading(musicId);
  bool hasNoCover(String musicId) => _repository.hasNoCover(musicId);

  // ── network meta (pass-through) ──
  String? getCoverUrl(String musicId) => _repository.getCoverUrl(musicId);
  bool isNetworkSong(String musicId) => _repository.isNetworkSong(musicId);
  Set<String> get networkSongIds => _repository.networkSongIds;
  String? getCachedLyrics(String musicId) =>
      _repository.getCachedLyrics(musicId);

  /// Callback invoked when a song starts playing (for history tracking, etc.)
  void Function(Music song)? onMusicPlayed;

  MusicProvider({required this.audioHandler}) {
    audioHandler.onSkipToNext = () => playNext();
    audioHandler.onSkipToPrevious = () => playPrev();

    _repository.onNotify = _safeNotifyListeners;

    _stateSubscription = player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) _playNext();
    });

    _stateSubscription2 = player.playingStream.listen((playing) {
      _safeNotifyListeners();
    });
  }

  // ═══════════════════════════════════════════════════════════
  //  Safe notify
  // ═══════════════════════════════════════════════════════════

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
  //  Bootstrap & library management
  // ═══════════════════════════════════════════════════════════

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
    await _repository.loadAppInfo();
    _safeNotifyListeners();
  }

  void updateLibrary(List<Music> scannedSongs) {
    _library = _libraryService.mergeLibrary(_library, scannedSongs);
    _safeNotifyListeners();
  }

  void setMiniMode(bool value) {
    _isMiniMode = value;
    _safeNotifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  Sorting (delegated to LibraryService)
  // ═══════════════════════════════════════════════════════════

  Future<void> setSongSortType(SongSortType type) async {
    _songSortType = type;
    _safeNotifyListeners();
  }

  Future<void> setAlbumSortType(AlbumSortType type) async {
    _albumSortType = type;
    _safeNotifyListeners();
  }

  List<Music> getSortedLibrary() {
    return _libraryService.getSortedLibrary(_library, sortType: _songSortType);
  }

  List<MapEntry<String, List<Music>>> getSortedAlbums() {
    return _libraryService.getSortedAlbums(
      _library,
      songSortType: _songSortType,
      albumSortType: _albumSortType,
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  Lyrics
  // ═══════════════════════════════════════════════════════════

  Future<List<LyricLine>> _parseLrc(String? lrcContent) async {
    if (lrcContent == null || lrcContent.isEmpty) return [];
    return await MusicService.parseLyrics(lrcContent);
  }

  Future<void> setCurrentLrc(String? lrcContent) async {
    final music = _playbackQueue.currentMusic;
    if (music == null) return;
    music.lyrics = lrcContent;
    _currentLyrics = await _parseLrc(lrcContent);
    _safeNotifyListeners();
    await MusicService.saveLyrics(lrcContent, music.id);
  }

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
  //  Queue management (delegated to PlaybackQueue)
  // ═══════════════════════════════════════════════════════════

  void addToQueue(Music music) {
    _playbackQueue.add(music);
    _safeNotifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    _playbackQueue.reorder(oldIndex, newIndex);
    _safeNotifyListeners();
  }

  void removeFromQueue(int index) {
    if (index == _playbackQueue.currentIndex ||
        index < 0 ||
        index >= _playbackQueue.length) {
      return;
    }
    _playbackQueue.removeAt(index);
    _safeNotifyListeners();
  }

  void clearQueue() {
    _playbackQueue.clear();
    player.stop();
    _safeNotifyListeners();
  }

  Future<void> replaceQueue(
    List<Music> songs, {
    int startIndex = 0,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;
    _playbackQueue.replace(songs);
    await player.stop();
    await playByIndex(startIndex, autoPlay: autoPlay);
  }

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
  //  Core playback
  // ═══════════════════════════════════════════════════════════

  Future<void> playByIndex(int index, {bool autoPlay = true}) async {
    final queue = _playbackQueue.queue;
    if (index < 0 || index >= queue.length) return;
    if (index == _playbackQueue.currentIndex && player.playing && autoPlay) {
      return;
    }

    _playbackQueue.setCurrentIndex(index);
    final music = queue[index];
    final effectiveLyrics =
        _repository.getCachedLyrics(music.id) ?? music.lyrics;
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

    if (_repository.isNetworkSong(music.id)) {
      // Get URL from the network metadata cache
      String? playUrl = _repository.getNetworkUrl(music.id);

      // Refresh netease URL if needed
      if (music.id.startsWith('net_')) {
        final freshUrl = await _repository.refreshNeteaseUrl(music.id);
        if (freshUrl != null) playUrl = freshUrl;
      }

      if (playUrl == null || playUrl.isEmpty) return;

      if (autoPlay) onMusicPlayed?.call(music);

      // First: play audio without cover to avoid 403
      await audioHandler.playFromUrl(
        playUrl,
        id: music.id,
        title: music.title,
        artist: music.artist,
        coverUrl: null,
        autoPlay: autoPlay,
      );

      // Background: fetch safe cover and hot-update notification
      final coverUrl = _repository.getCoverUrl(music.id);
      final currentPlayingId = music.id;
      // Capture playUrl as non-nullable for the closure (null check is above)
      final safePlayUrl = playUrl;
      _repository.getSafeArtUri(coverUrl).then((safeCoverUrl) {
        if (safeCoverUrl != null &&
            _playbackQueue.currentIndex >= 0 &&
            _playbackQueue.queue[_playbackQueue.currentIndex].id ==
                currentPlayingId) {
          final currentCover = getCoverUrl(currentPlayingId);
          if (currentCover == safeCoverUrl) return;
          debugPrint(
            '--- [MusicProvider] 安全封面热更新: $safeCoverUrl ---',
          );
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
      if (autoPlay) onMusicPlayed?.call(music);
      await audioHandler.playMusic(music, autoPlay: autoPlay);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  Cover loading (delegated to MusicRepository)
  // ═══════════════════════════════════════════════════════════

  Future<void> loadCoverLazy(String musicId) async {
    final coverBytes = await _repository.loadCoverLazy(musicId);
    if (coverBytes != null) {
      _updateCoverBytes(musicId, coverBytes);
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
    _playbackQueue.updateCoverBytes(musicId, coverBytes);

    if (hasChanged) _safeNotifyListeners();
  }

  // ═══════════════════════════════════════════════════════════
  //  Playback controls
  // ═══════════════════════════════════════════════════════════

  void togglePlay() {
    player.playing ? player.pause() : player.play();
    _safeNotifyListeners();
  }

  void togglePlayMode() {
    _playbackQueue.togglePlayMode();
    _safeNotifyListeners();
  }

  Future<void> playNext() => _playNext(trigger: PlayTrigger.user);
  Future<void> playPrev() => _playPrev();

  Future<void> _playNext({PlayTrigger trigger = PlayTrigger.auto}) async {
    final nextIndex = _playbackQueue.computeNextIndex(trigger: trigger);
    if (nextIndex < 0) return;

    if (_playbackQueue.playMode == PlayMode.repeat &&
        trigger == PlayTrigger.auto) {
      await player.seek(Duration.zero);
      player.play();
    } else if (_playbackQueue.playMode == PlayMode.sequence &&
        nextIndex == _playbackQueue.currentIndex &&
        trigger == PlayTrigger.auto) {
      await player.seek(Duration.zero);
    } else {
      await playByIndex(nextIndex);
    }
  }

  Future<void> _playPrev() async {
    final prevIndex = _playbackQueue.computePrevIndex();
    if (prevIndex >= 0) {
      await playByIndex(prevIndex);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  Network songs
  // ═══════════════════════════════════════════════════════════

  Music? getSongById(String id) =>
      _repository.getSongById(id, _library, _playbackQueue.queue);

  Future<void> playNetworkSearchResults({
    required List<Map<String, String?>> songs,
    required int startIndex,
    bool autoPlay = true,
  }) async {
    if (songs.isEmpty) return;

    final (musicList, _) = _repository.importNetworkSearchResults(songs);
    await replaceQueue(musicList, startIndex: startIndex, autoPlay: autoPlay);
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

    _repository.debouncePersistNetworkSong(
      music,
      url,
      coverUrl,
      effectiveLyrics,
    );

    // First: play audio without cover to avoid 403
    await audioHandler.playFromUrl(
      url,
      id: musicId,
      title: title,
      artist: artist,
      coverUrl: null,
      autoPlay: true,
    );

    // Background: fetch safe cover
    final currentPlayingId = music.id;
    _repository.getSafeArtUri(coverUrl).then((safeCoverUrl) {
      final currentCover = getCoverUrl(currentPlayingId);
      if (currentCover == safeCoverUrl) return;
      if (safeCoverUrl != null &&
          _playbackQueue.currentIndex >= 0 &&
          _playbackQueue.queue[_playbackQueue.currentIndex].id == musicId) {
        debugPrint(
          '--- [MusicProvider] 后台封面预缓存成功，动态热更新通知栏 ---',
        );
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

  Future<void> loadPersistedNetworkSongs() async {
    await _repository.loadPersistedNetworkSongs();
  }

  // ═══════════════════════════════════════════════════════════
  //  Background lyrics fetching
  // ═══════════════════════════════════════════════════════════

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
  //  Position stream
  // ═══════════════════════════════════════════════════════════

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        player.positionStream,
        player.bufferedPositionStream,
        player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  // ═══════════════════════════════════════════════════════════
  //  Lifecycle
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
