// ─── 右侧边栏播放队列组件 ──────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class PlaybackQueueDrawer extends StatelessWidget {
  const PlaybackQueueDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 让侧边栏在手机上占屏幕 85%，在宽屏/平板上固定最大 360 像素
    final double drawerWidth = MediaQuery.of(context).size.width * 0.85;
    final double finalWidth = drawerWidth.clamp(280.0, 360.0);

    return SizedBox(
      width: finalWidth,
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
        ),
        backgroundColor: cs.surface,
        child: SafeArea(
          child: Consumer<MusicProvider>(
            builder: (context, mp, child) {
              // 💡 关键点 1：每次 notifyListeners 被调用时，Consumer 会在这里精准拿到排序后的最新 queue
              final songs = mp.queue;
              final currentMusic = mp.currentMusic;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 头部标题栏
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "当前播放",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "共 ${songs.length} 首歌曲",
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        if (songs.isNotEmpty)
                          IconButton(
                            tooltip: '清空队列',
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => mp.clearQueue(),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  // 2. 完美的排序列表
                  Expanded(
                    child: songs.isEmpty
                        ? Center(
                            child: Text(
                              "播放队列为空",
                              style: TextStyle(color: cs.onSurfaceVariant),
                            ),
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: songs.length,
                            onReorderItem: (int oldIndex, int newIndex) {
                              mp.reorderQueue(oldIndex, newIndex);
                            },
                            itemBuilder: (context, index) {
                              final song = songs[index];
                              final isPlaying = currentMusic?.id == song.id;

                              return ListTile(
                                // 升级复合稳定 Key，混入 index，杜绝同歌多加时的渲染混乱
                                key: ValueKey('queue_${song.id}_$index'),
                                dense: true,
                                selected: isPlaying,
                                selectedTileColor: cs.primaryContainer
                                    .withValues(alpha: 0.25),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                
                                title: Text(
                                  song.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isPlaying
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isPlaying
                                        ? cs.primary
                                        : cs.onSurface,
                                  ),
                                ),
                                subtitle: Text(
                                  song.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isPlaying
                                        ? cs.primary.withValues(alpha: 0.7)
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                                leading: Icon(
                                  isPlaying
                                      ? Icons.volume_up_rounded
                                      : Icons.music_note_rounded,
                                  color: isPlaying
                                      ? cs.primary
                                      : cs.onSurfaceVariant,
                                  size: 20,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    context.pop();
                                    mp.removeFromQueue(index);
                                  },
                                ),
                                onTap: () => mp.playByIndex(index),
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
