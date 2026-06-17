import 'dart:math';
import 'dart:typed_data';

import 'package:myapp/model/Music/index.dart';

enum PlayMode { sequence, shuffle, repeat }

enum PlayTrigger { user, auto }

class MusicQueue {
  final List<Music> _queue = [];
  Map<String, int> _queueIndexMap = {};
  int _currentIndex = -1;
  PlayMode _playMode = PlayMode.sequence;

  // ── read-only accessors ──

  List<Music> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  PlayMode get playMode => _playMode;

  Music? get currentMusic {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  bool get isEmpty => _queue.isEmpty;
  bool get isNotEmpty => _queue.isNotEmpty;
  int get length => _queue.length;

  // ── O(1) lookup ──

  bool contains(String id) => _queueIndexMap.containsKey(id);

  // ── index helpers ──

  /// Returns the (possibly wrapped) next index without mutating state.
  int computeNextIndex({PlayTrigger trigger = PlayTrigger.auto}) {
    if (_queue.isEmpty) return -1;
    switch (_playMode) {
      case PlayMode.repeat:
        if (trigger == PlayTrigger.user) {
          return (_currentIndex + 1) % _queue.length;
        }
        return _currentIndex; // caller should seek to 0
      case PlayMode.shuffle:
        if (_queue.length <= 1) return _currentIndex;
        int next = _currentIndex;
        while (next == _currentIndex) {
          next = Random().nextInt(_queue.length);
        }
        return next;
      case PlayMode.sequence:
        if (_currentIndex < _queue.length - 1) {
          return _currentIndex + 1;
        }
        if (trigger == PlayTrigger.user) return 0;
        return _currentIndex; // caller should seek to 0
    }
  }

  int computePrevIndex() {
    if (_queue.isEmpty) return -1;
    return (_currentIndex - 1 + _queue.length) % _queue.length;
  }

  // ── mutations ──

  void setCurrentIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
    }
  }

  void add(Music music) {
    _queue.add(music);
    _queueIndexMap[music.id] = _queue.length - 1;
  }

  /// Remove the item at [index]. Returns true if the current index needed
  /// adjustment (caller must update _currentIndex).
  void removeAt(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) _currentIndex--;
    _refreshIndexMap();
  }

  /// Reorder the item at [oldIndex] to [newIndex].
  /// Returns the new index of the previously-current track, or -1.
  int reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return _currentIndex;
    final playingMusic = currentMusic;

    if (newIndex > oldIndex) newIndex += 1;

    final song = _queue.removeAt(oldIndex);
    final targetIndex = (newIndex > oldIndex ? newIndex - 1 : newIndex)
        .clamp(0, _queue.length);
    _queue.insert(targetIndex, song);

    _refreshIndexMap();

    if (playingMusic != null) {
      _currentIndex = _queueIndexMap[playingMusic.id] ?? -1;
    }
    return _currentIndex;
  }

  void clear() {
    _queue.clear();
    _queueIndexMap.clear();
    _currentIndex = -1;
  }

  /// Replace the entire queue. Returns the new list and suggested start index.
  List<Music> replace(List<Music> songs) {
    _queue
      ..clear()
      ..addAll(songs);
    _refreshIndexMap();
    _currentIndex = -1;
    return _queue;
  }

  PlayMode togglePlayMode() {
    _playMode = switch (_playMode) {
      PlayMode.sequence => PlayMode.shuffle,
      PlayMode.shuffle => PlayMode.repeat,
      PlayMode.repeat => PlayMode.sequence,
    };
    return _playMode;
  }

  /// Patch cover bytes onto the Music object at the given id.
  /// Returns true if a match was found and updated.
  bool updateCoverBytes(String musicId, Uint8List coverBytes) {
    final idx = _queueIndexMap[musicId];
    if (idx != null &&
        (_queue[idx].coverBytes == null || _queue[idx].coverBytes!.isEmpty)) {
      _queue[idx].coverBytes = coverBytes;
      return true;
    }
    return false;
  }

  // ── internal ──

  void _refreshIndexMap() {
    _queueIndexMap = {
      for (int i = 0; i < _queue.length; i++) _queue[i].id: i,
    };
  }
}
