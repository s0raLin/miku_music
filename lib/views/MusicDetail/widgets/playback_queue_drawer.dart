// ─── 右侧边栏播放队列组件 ──────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class PlaybackQueueDrawer extends StatelessWidget {
  const PlaybackQueueDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width * 0.85;
    final finalWidth = width.clamp(280.0, 360.0);

    return SizedBox(
      width: finalWidth,
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
        ),
        backgroundColor: cs.surface,
        child: SafeArea(
          child: Consumer<MusicProvider>(
            builder: (context, mp, _) {
              final songs = mp.queue;
              final currentId = mp.currentMusic?.id;

              return Column(
                children: [
                  _QueueHeader(
                    count: songs.length,
                    playMode: mp.playMode,
                    onToggleMode: mp.togglePlayMode,
                    onClear: songs.isEmpty ? null : mp.clearQueue,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: songs.isEmpty
                        ? const _EmptyQueue()
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                            itemCount: songs.length,
                            onReorderItem: mp.reorderQueue,
                            buildDefaultDragHandles: false, // 关掉默认右边拖拽手柄
                            proxyDecorator: (child, index, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (context, child) {
                                  final elevation = Tween<double>(
                                    begin: 0,
                                    end: 6,
                                  ).animate(animation).value;
                                  return Material(
                                    elevation: elevation,
                                    borderRadius: BorderRadius.circular(16),
                                    color: cs.surfaceContainerHigh,
                                    child: child,
                                  );
                                },
                                child: child,
                              );
                            },
                            itemBuilder: (context, index) {
                              final song = songs[index];
                              final isPlaying = currentId == song.id;

                              return _QueueTile(
                                key: ValueKey('queue_${song.id}_$index'),
                                index: index,
                                title: song.title,
                                artist: song.artist,
                                isPlaying: isPlaying,
                                onTap: () => mp.playByIndex(index),
                                onRemove: () => mp.removeFromQueue(index),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────
class _QueueHeader extends StatelessWidget {
  const _QueueHeader({
    required this.count,
    required this.playMode,
    required this.onToggleMode,
    required this.onClear,
  });

  final int count;
  final PlayMode playMode;
  final VoidCallback onToggleMode;
  final VoidCallback? onClear;

  IconData get _modeIcon => switch (playMode) {
    PlayMode.sequence => Icons.repeat_rounded,
    PlayMode.shuffle => Icons.shuffle_rounded,
    PlayMode.repeat => Icons.repeat_one_rounded,
  };

  String get _modeTooltip => switch (playMode) {
    PlayMode.sequence => '顺序播放',
    PlayMode.shuffle => '随机播放',
    PlayMode.repeat => '单曲循环',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前播放',
                  style: tt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '共 $count 首',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleMode,
            tooltip: _modeTooltip,
            icon: Icon(_modeIcon, size: 22),
            visualDensity: VisualDensity.compact,
          ),
          if (onClear != null)
            IconButton(
              onPressed: onClear,
              tooltip: '清空队列',
              icon: const Icon(Icons.delete_outline_rounded, size: 22),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// List Tile
// ─────────────────────────────────────────────────────────────
class _QueueTile extends StatelessWidget {
  const _QueueTile({
    super.key,
    required this.index,
    required this.title,
    required this.artist,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
  });

  final int index;
  final String title;
  final String artist;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isPlaying
            ? cs.primaryContainer.withValues(alpha: 0.35)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                // 左侧拖拽手柄（唯一）
                ReorderableDragStartListener(
                  index: index,
                  child: SizedBox(
                    width: 28,
                    child: Icon(
                      isPlaying
                          ? Icons.equalizer_rounded
                          : Icons.drag_handle_rounded,
                      size: 20,
                      color: isPlaying
                          ? cs.primary
                          : cs.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 标题 + 歌手
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isPlaying
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isPlaying ? cs.primary : cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isPlaying
                              ? cs.primary.withValues(alpha: 0.75)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // 移除按钮
                IconButton(
                  onPressed: onRemove,
                  tooltip: '移除',
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  visualDensity: VisualDensity.compact,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────
class _EmptyQueue extends StatelessWidget {
  const _EmptyQueue();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 48,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            '播放队列为空',
            style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            '添加歌曲后会显示在这里',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
