import 'dart:math';
import 'dart:typed_data';

import 'package:myapp/model/Music/index.dart';

/// 播放模式枚举
enum PlayMode {
  /// 顺序播放 / 列表循环
  sequence,

  /// 随机播放
  shuffle,

  /// 单曲循环
  repeat,
}

/// 触发播放切换的来源枚举
enum PlayTrigger {
  /// 用户手动点击切换（如点击下一曲按钮）
  user,

  /// 系统自动播放完成触发切换
  auto,
}

/// 播放队列的历史快照实体类
class QueueSnapshot {
  final String id;
  final String name;
  final List<Music> songs;
  final int currentIndex;
  final DateTime createdAt;

  QueueSnapshot({
    required this.id,
    required this.name,
    required List<Music> songs, // 改为深度拷贝，防止外部引用修改
    required this.currentIndex,
    DateTime? createdAt,
  }) : songs = List.unmodifiable(List.from(songs)), // 强制只读防污染
       createdAt = createdAt ?? DateTime.now();
}

/// 音乐播放队列管理核心类
class MusicQueue {
  /// 当前播放队列中的歌曲列表
  final List<Music> _queue = [];

  /// 历史队列快照列表
  final List<QueueSnapshot> _history = [];

  /// 歌曲 ID 到队列索引位置的映射表（用于 O(1) 快速检索）
  Map<String, int> _queueIndexMap = {};

  /// 当前正在播放的歌曲索引（-1 表示无播放项）
  int _currentIndex = -1;

  /// 当前播放模式，默认为顺序播放
  PlayMode _playMode = PlayMode.sequence;

  /// 最多允许保留的历史队列数量
  static const int maxHistorySize = 20;

  // ── 只读属性访问器 (Read-only accessors) ──

  /// 获取当前播放队列（只读列表）
  List<Music> get queue => List.unmodifiable(_queue);

  /// 获取当前播放索引位置
  int get currentIndex => _currentIndex;

  /// 获取当前播放模式
  PlayMode get playMode => _playMode;

  /// 获取历史队列列表（只读列表）
  List<QueueSnapshot> get history => List.unmodifiable(_history);

  /// 获取当前正在播放的歌曲对象，若无则返回 null
  Music? get currentMusic {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return null;
    return _queue[_currentIndex];
  }

  /// 检查当前队列是否为空
  bool get isEmpty => _queue.isEmpty;

  /// 检查当前队列是否有歌曲
  bool get isNotEmpty => _queue.isNotEmpty;

  /// 获取当前队列的歌曲总数
  int get length => _queue.length;

  // ── O(1) 高效查找 ──

  /// 根据歌曲 ID 检查当前队列中是否存在该歌曲
  bool contains(String id) => _queueIndexMap.containsKey(id);

  /// 将当前队列作为快照保存到历史记录中
  QueueSnapshot? saveCurrentToHistory({String? queueName}) {
    // 核心防御 1：当前队列为空，或者所有歌曲无效，直接拦截，绝对不存历史
    if (_queue.isEmpty) return null;

    // 防重校验：如果最新快照的歌曲列表 ID 与当前一致，且当前播放索引也一致，则不重复保存
    if (_history.isNotEmpty) {
      final lastSnapshot = _history.first;
      if (_isQueueSame(lastSnapshot.songs, _queue) &&
          lastSnapshot.currentIndex == _currentIndex) {
        return null;
      }
    }

    final snapshot = QueueSnapshot(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: queueName ?? '历史播放队列 (${_queue.length}首)',
      songs: List.from(_queue),
      currentIndex: _currentIndex >= 0 ? _currentIndex : 0,
    );

    _history.insert(0, snapshot);
    if (_history.length > maxHistorySize) {
      _history.removeLast();
    }

    return snapshot;
  }

  /// 使用新的歌曲列表替换当前播放队列
  List<Music> replace(
    List<Music> songs, {
    String? queueName,
    bool saveToHistory = true,
  }) {
    // 核心防御 2：如果打算用一个“空歌单”来替换当前队列，
    // 通常意味着播放被重置或加载失败，不应该将旧队列归档为历史快照
    if (songs.isEmpty) {
      _queue.clear();
      _queueIndexMap.clear();
      _currentIndex = -1;
      return _queue;
    }

    // 只有当待替换的新歌曲列表不为空、且旧队列也不为空时，才保存旧队列到历史
    if (saveToHistory && _queue.isNotEmpty) {
      saveCurrentToHistory(queueName: queueName);
    }

    _queue
      ..clear()
      ..addAll(songs);
    _refreshIndexMap();
    _currentIndex = -1;
    return _queue;
  }

  /// 从历史快照恢复队列
  int restoreFromSnapshot(QueueSnapshot snapshot) {
    _queue
      ..clear()
      ..addAll(snapshot.songs); // 从快照深拷贝恢复内存队列
    _refreshIndexMap();

    _currentIndex =
        (snapshot.currentIndex >= 0 && snapshot.currentIndex < _queue.length)
        ? snapshot.currentIndex
        : 0;

    // 移除旧的重复快照记录，并将当前状态作为最新记录置顶
    _history.removeWhere((s) => s.id == snapshot.id);

    // 重新为当前状态生成一个新的 snapshot 置顶，确保 currentIndex 准确
    saveCurrentToHistory(queueName: snapshot.name);

    return _currentIndex;
  }

  /// 批量载入数据库历史快照（通常在 App 启动或初始化时调用）
  void loadHistory(List<QueueSnapshot> snapshots) {
    _history.clear();
    _history.addAll(snapshots);
    // 保持最大容量限制
    if (_history.length > maxHistorySize) {
      _history.removeRange(maxHistorySize, _history.length);
    }
  }

  /// 内部比对辅助方法：判断两个歌曲列表的 ID 序列是否一致
  bool _isQueueSame(List<Music> listA, List<Music> listB) {
    if (listA.length != listB.length) return false;
    for (int i = 0; i < listA.length; i++) {
      if (listA[i].id != listB[i].id) return false;
    }
    return true;
  }

  /// 清空所有历史队列记录
  void clearHistory() {
    _history.clear();
  }

  // ── 索引计算辅助方法 (Index helpers) ──

  /// 根据当前播放模式与触发源计算下一首歌曲的索引位置（不会改变内部状态）
  ///
  /// [trigger] 标记触发来源：[PlayTrigger.auto] 为自动切歌，[PlayTrigger.user] 为用户手动切歌
  int computeNextIndex({PlayTrigger trigger = PlayTrigger.auto}) {
    if (_queue.isEmpty) return -1;
    switch (_playMode) {
      case PlayMode.repeat:
        if (trigger == PlayTrigger.user) {
          return (_currentIndex + 1) % _queue.length;
        }
        return _currentIndex; // 单曲循环自动播放完时，返回原索引（调用方处理 Seek 到 0）
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
        return _currentIndex; // 顺序播放到最后一首时，自动切歌维持在末尾（或由播放器停止）
    }
  }

  /// 根据快照 ID 删除指定的历史队列记录
  void removeHistoryById(String id) {
    _history.removeWhere((snapshot) => snapshot.id == id);
  }

  /// 计算上一首歌曲的索引位置
  int computePrevIndex() {
    if (_queue.isEmpty) return -1;
    return (_currentIndex - 1 + _queue.length) % _queue.length;
  }

  // ── 队列变更方法 (Mutations) ──

  /// 设置当前播放的歌曲索引
  void setCurrentIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
    }
  }

  /// 向队列末尾添加一首歌曲
  void add(Music music) {
    _queue.add(music);
    _queueIndexMap[music.id] = _queue.length - 1;
  }

  /// 将歌曲插入到「当前播放曲的下一首」位置
  /// 若当前无播放项，则等同于 add（追加到末尾）
  /// 返回插入后的索引
  int insertNext(Music music) {
    if (_queue.isEmpty || _currentIndex < 0) {
      add(music);
      return _queue.length - 1;
    }
    final insertIndex = _currentIndex + 1;
    _queue.insert(insertIndex, music);
    _refreshIndexMap();
    return insertIndex;
  }

  /// 移除指定索引位置 [index] 的歌曲
  /// 若移除的索引位于当前播放歌曲之前，会自动修正 [_currentIndex] 避免错位
  void removeAt(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) _currentIndex--;
    _refreshIndexMap();
  }

  /// 将歌曲从原索引 [oldIndex] 拖拽/移动至新索引 [newIndex]
  /// 返回移动后当前正在播放的歌曲在新队列中的索引位置，若无播放曲目则返回 -1
  int reorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return _currentIndex;
    final playingMusic = currentMusic;

    if (newIndex > oldIndex) newIndex += 1;

    final song = _queue.removeAt(oldIndex);
    final targetIndex = (newIndex > oldIndex ? newIndex - 1 : newIndex).clamp(
      0,
      _queue.length,
    );
    _queue.insert(targetIndex, song);

    _refreshIndexMap();

    if (playingMusic != null) {
      _currentIndex = _queueIndexMap[playingMusic.id] ?? -1;
    }
    return _currentIndex;
  }

  /// 清空当前播放队列并重置播放状态
  void clear() {
    _queue.clear();
    _queueIndexMap.clear();
    _currentIndex = -1;
  }

  /// 循环切换播放模式（顺序 -> 随机 -> 单曲循环 -> 顺序）
  PlayMode togglePlayMode() {
    _playMode = switch (_playMode) {
      PlayMode.sequence => PlayMode.shuffle,
      PlayMode.shuffle => PlayMode.repeat,
      PlayMode.repeat => PlayMode.sequence,
    };
    return _playMode;
  }

  /// 动态更新指定 [musicId] 歌曲的封面数据 [coverBytes]
  /// 只有当歌曲缺少封面或封面为空时才会更新，更新成功返回 true
  bool updateCoverBytes(String musicId, Uint8List coverBytes) {
    final idx = _queueIndexMap[musicId];
    if (idx != null &&
        (_queue[idx].coverBytes == null || _queue[idx].coverBytes!.isEmpty)) {
      _queue[idx].coverBytes = coverBytes;
      return true;
    }
    return false;
  }

  // ── 内部辅助方法 (Internal) ──

  /// 重新刷新 `歌曲 ID -> 队列索引` 的快速映射表
  void _refreshIndexMap() {
    _queueIndexMap = {for (int i = 0; i < _queue.length; i++) _queue[i].id: i};
  }
}
