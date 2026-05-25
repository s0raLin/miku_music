// queue_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class QueuePage extends StatelessWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MusicProvider>();
    final queue = mp.queue;
    final currentIndex = queue.indexWhere((m) => m.id == mp.currentMusic?.id);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        scrolledUnderElevation: 0,
        // leading: IconButton(
        //   icon: const Icon(Icons.keyboard_arrow_down_rounded),
        //   onPressed: () => context.pop(),
        // ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('播放队列', style: tt.titleMedium),
            Text(
              '${queue.length} 首歌曲',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (queue.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: '清空队列',
              onPressed: () => _confirmClear(context, mp),
            ),
        ],
      ),
      body: queue.isEmpty
          ? _buildEmpty(context)
          : Column(
              children: [
                // ── 当前播放 ──
                if (currentIndex != -1)
                  _NowPlayingBanner(
                    music: queue[currentIndex],
                    onTap: () => context.push('/music-detail'),
                  ),

                // ── 接下来播放 ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '接下来播放',
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: queue.length,
                    // 跳过当前正在播放的那首
                    buildDefaultDragHandles: false,
                    onReorder: (oldIndex, newIndex) {
                      // ReorderableListView 包含了全部 itemCount 条目
                      // 需要手动跳过 currentIndex
                      _reorder(mp, currentIndex, oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      if (index == currentIndex) {
                        // 占位，让 currentIndex 的位置不显示在列表里
                        return const SizedBox.shrink(
                          key: ValueKey('current-placeholder'),
                        );
                      }
                      final music = queue[index];
                      return _QueueTile(
                        key: ValueKey(music.id),
                        music: music,
                        index: index,
                        onTap: () {
                          mp.playByIndex(index);
                          context.push('/music-detail');
                        },
                        onRemove: () => mp.removeFromQueue(index),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _reorder(
    MusicProvider mp,
    int currentIndex,
    int oldIndex,
    int newIndex,
  ) {
    // ReorderableListView 在向后移动时 newIndex 会多 1
    if (newIndex > oldIndex) newIndex--;

    // 不允许移动到当前播放位置
    if (newIndex == currentIndex) return;

    final queue = List<MusicInfo>.from(mp.queue);
    final item = queue.removeAt(oldIndex);
    queue.insert(newIndex, item);
    mp.replaceQueue(queue, startIndex: currentIndex, autoPlay: false);
  }

  Future<void> _confirmClear(BuildContext context, MusicProvider mp) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空队列'),
        content: const Text('确定要清空播放队列吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    if (confirmed == true) mp.clearQueue();
  }

  Widget _buildEmpty(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.queue_music_rounded,
            size: 64,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '队列为空',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ── 当前播放横幅 ──────────────────────────────────────────────────────────────

class _NowPlayingBanner extends StatelessWidget {
  final MusicInfo music;
  final VoidCallback onTap;

  const _NowPlayingBanner({required this.music, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        elevation: 0,
        color: cs.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: music.coverBytes?.isNotEmpty == true
                        ? Image.memory(music.coverBytes!, fit: BoxFit.cover)
                        : Container(
                            color: cs.primary.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.music_note_rounded,
                              color: cs.primary,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // 信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        music.title,
                        style: tt.titleSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        music.artist,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onPrimaryContainer.withValues(alpha: 0.75),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '正在播放',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  Icons.open_in_full_rounded,
                  size: 18,
                  color: cs.onPrimaryContainer.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 队列条目 ──────────────────────────────────────────────────────────────────

class _QueueTile extends StatelessWidget {
  final MusicInfo music;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueTile({
    super.key,
    required this.music,
    required this.index,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: onTap,
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖动手柄
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.drag_handle_rounded,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          // 封面
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44,
              height: 44,
              child: music.coverBytes?.isNotEmpty == true
                  ? Image.memory(music.coverBytes!, fit: BoxFit.cover)
                  : Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 20,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
        ],
      ),
      title: Text(
        music.title,
        style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        music.artist,
        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.close_rounded,
          size: 18,
          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        onPressed: onRemove,
      ),
    );
  }
}
