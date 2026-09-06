import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

// ════════════════════════════════════════════════════════════════
//  NowPlayingBar — MD3 胶囊岛形式，悬浮在底部内容之上
// ════════════════════════════════════════════════════════════════
class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.select<MusicProvider, Music?>((p) => p.currentMusic);
    if (music == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: _CapsuleBar(music: music),
    );
  }
}

class _CapsuleBar extends StatelessWidget {
  final Music music;
  const _CapsuleBar({required this.music});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () => context.push('/music-detail'),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      top: 6,
                      right: 12,
                      bottom: 8,
                    ),
                    child: Row(
                      children: [
                        _CapsuleCover(music: music),
                        const SizedBox(width: 12),
                        Expanded(child: _CapsuleTrackInfo(music: music)),
                        const SizedBox(width: 8),
                        const _CapsuleControls(),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CapsuleProgressBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 封面组件 ──
class _CapsuleCover extends StatelessWidget {
  final Music music;
  const _CapsuleCover({required this.music});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mp = context.read<MusicProvider>();
    final coverUrl = mp.getCoverUrl(music.id);

    Widget image;
    if (music.coverBytes?.isNotEmpty == true) {
      image = Image.memory(
        music.coverBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else if (coverUrl != null && coverUrl.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: coverUrl,
        fit: BoxFit.cover,
        httpHeaders: coverUrl.contains('music.126.net')
            ? const {'Referer': 'https://music.163.com/'}
            : const {},
        placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
        errorWidget: (_, __, ___) => _fallback(cs),
      );
    } else {
      image = _fallback(cs);
    }

    return Hero(
      tag: 'music_cover_${music.id}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(width: 48, height: 48, child: image),
      ),
    );
  }

  Widget _fallback(ColorScheme cs) => Container(
    color: cs.primaryContainer,
    child: Icon(
      Icons.music_note_rounded,
      size: 22,
      color: cs.onPrimaryContainer,
    ),
  );
}

// ── 标题 + 歌手 ──
class _CapsuleTrackInfo extends StatelessWidget {
  final Music music;
  const _CapsuleTrackInfo({required this.music});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          music.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          music.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── 控制按钮组 ──
class _CapsuleControls extends StatelessWidget {
  const _CapsuleControls();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mp = context.read<MusicProvider>();
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 22,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: mp.playPrev,
          color: cs.onSurface,
          tooltip: '上一首',
        ),
        const SizedBox(width: 4),
        IconButton.filled(
          style: IconButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            minimumSize: const Size(38, 38),
            padding: EdgeInsets.zero,
          ),
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 22,
          ),
          onPressed: mp.togglePlay,
          tooltip: isPlaying ? '暂停' : '播放',
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 22,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: mp.playNext,
          color: cs.onSurface,
          tooltip: '下一首',
        ),
        IconButton(
          icon: const Icon(Icons.queue_music_rounded),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => _showQueue(context),
          color: cs.onSurfaceVariant,
          tooltip: '播放队列与历史',
        ),
      ],
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _QueueSheet(),
    );
  }
}

// ── 贴底胶囊进度条 ──
class _CapsuleProgressBar extends StatelessWidget {
  const _CapsuleProgressBar();

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<PositionData>(
      stream: mp.positionDataStream,
      builder: (context, snap) {
        final pos =
            snap.data ??
            const PositionData(Duration.zero, Duration.zero, Duration.zero);
        final value = pos.duration.inMilliseconds > 0
            ? (pos.position.inMilliseconds / pos.duration.inMilliseconds).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null || pos.duration.inMilliseconds <= 0) return;
            final dx = (details.localPosition.dx / box.size.width).clamp(
              0.0,
              1.0,
            );
            mp.player.seek(
              Duration(
                milliseconds: (pos.duration.inMilliseconds * dx).toInt(),
              ),
            );
          },
          child: SizedBox(
            height: 3,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: cs.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              valueColor: AlwaysStoppedAnimation(cs.primary),
              borderRadius: BorderRadius.zero,
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  播放队列 & 历史快照 Bottom Sheet（美化版 & 支持单项删除）
// ════════════════════════════════════════════════════════════════
// ════════════════════════════════════════════════════════════════
//  播放队列 & 历史快照 Bottom Sheet（优化版）
// ════════════════════════════════════════════════════════════════
class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  IconData modeIcon(PlayMode mode) => switch (mode) {
    PlayMode.sequence => Icons.repeat_rounded,
    PlayMode.shuffle => Icons.shuffle_rounded,
    PlayMode.repeat => Icons.repeat_one_rounded,
  };

  String modeTooltip(PlayMode mode) => switch (mode) {
    PlayMode.sequence => '顺序播放',
    PlayMode.shuffle => '随机播放',
    PlayMode.repeat => '单曲循环',
  };

  String _formatDateTime(DateTime dt) {
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mp = context.watch<MusicProvider>();

    final songs = mp.queue;
    final historyList = mp.history;
    final currentMusic = mp.currentMusic;

    return DefaultTabController(
      length: 2,
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.68,
          child: Column(
            children: [
              // 顶部拖拽指示条
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Tab 切换（MD3 药丸风格）
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelColor: cs.onPrimaryContainer,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    labelStyle: tt.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: tt.labelLarge,
                    tabs: [
                      Tab(text: '当前队列 (${songs.length})'),
                      Tab(text: '历史快照 (${historyList.length})'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Expanded(
                child: TabBarView(
                  children: [
                    _buildCurrentQueue(
                      context,
                      mp,
                      songs,
                      currentMusic,
                      cs,
                      tt,
                    ),
                    _buildQueueHistory(context, mp, historyList, cs, tt),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────
  // 当前播放队列
  // ────────────────────────────────────────────────
  Widget _buildCurrentQueue(
    BuildContext context,
    MusicProvider mp,
    List<Music> songs,
    Music? currentMusic,
    ColorScheme cs,
    TextTheme tt,
  ) {
    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music_rounded, size: 48, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(
              '播放队列为空',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              '添加歌曲后会显示在这里',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // 顶部操作栏
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
          child: Row(
            children: [
              Text(
                '播放模式',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: mp.togglePlayMode,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(modeIcon(mp.playMode), size: 18, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        modeTooltip(mp.playMode),
                        style: tt.labelMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: mp.clearQueue,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('清空'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.error,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
            itemCount: songs.length,
            buildDefaultDragHandles: false,
            onReorderItem: mp.reorderQueue,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final t = Curves.easeOut.transform(animation.value);
                  return Material(
                    elevation: 6 * t,
                    borderRadius: BorderRadius.circular(14),
                    color: cs.surfaceContainerHigh,
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final m = songs[index];
              final isCurrent = currentMusic?.id == m.id;

              return Padding(
                key: ValueKey('queue_${m.id}_$index'),
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Material(
                  color: isCurrent
                      ? cs.primaryContainer.withValues(alpha: 0.35)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => mp.playByIndex(index),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
                      child: Row(
                        children: [
                          // 拖拽手柄
                          ReorderableDragStartListener(
                            index: index,
                            child: SizedBox(
                              width: 32,
                              child: Icon(
                                isCurrent
                                    ? Icons.equalizer_rounded
                                    : Icons.drag_handle_rounded,
                                size: 20,
                                color: isCurrent
                                    ? cs.primary
                                    : cs.onSurfaceVariant.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // 标题 + 歌手
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrent
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? cs.primary
                                        : cs.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  m.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isCurrent
                                        ? cs.primary.withValues(alpha: 0.75)
                                        : cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 移除
                          IconButton(
                            onPressed: () => mp.removeFromQueue(index),
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
            },
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────
  // 历史快照
  // ────────────────────────────────────────────────
  Widget _buildQueueHistory(
    BuildContext context,
    MusicProvider mp,
    List<QueueSnapshot> history,
    ColorScheme cs,
    TextTheme tt,
  ) {
    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 48, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(
              '暂无队列历史记录',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
          child: Row(
            children: [
              Text(
                '自动保存的播放快照',
                style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('清空历史'),
                      content: const Text('确定要清空所有队列历史快照吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('清空'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    mp.clearQueueHistory();
                  }
                },
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('全部清空'),
                style: TextButton.styleFrom(
                  foregroundColor: cs.error,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final snapshot = history[index];
              final titleName = snapshot.name;
              final songCount = snapshot.songs.length;
              final timeStr = _formatDateTime(snapshot.createdAt);
              final previewSongs = snapshot.songs
                  .take(2)
                  .map((m) => m.title)
                  .join(' / ');

              return Dismissible(
                key: ValueKey('history_snapshot_${snapshot.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: cs.onErrorContainer,
                  ),
                ),
                onDismissed: (_) {
                  mp.deleteQueueSnapshot(snapshot.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('已删除: $titleName'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Card(
                  elevation: 0,
                  color: cs.surfaceContainerLow,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Icon(
                              Icons.playlist_play_rounded,
                              size: 20,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                titleName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 2),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              color: cs.onSurfaceVariant,
                              tooltip: '删除此记录',
                              onPressed: () =>
                                  mp.deleteQueueSnapshot(snapshot.id),
                            ),
                          ],
                        ),

                        if (previewSongs.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            previewSongs,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Footer
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$songCount 首曲目',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const Spacer(),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                mp.restoreQueueFromHistory(snapshot);
                                Navigator.of(context).pop();
                              },
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: const Text('恢复并播放'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
