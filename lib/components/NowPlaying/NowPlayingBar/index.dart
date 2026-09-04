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
//  播放队列 & 历史快照 Bottom Sheet
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
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Column(
            children: [
              // 顶端 Handle 抓手标志
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // Tab 切换栏
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TabBar(
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: tt.titleSmall,
                  tabs: [
                    Tab(text: '当前队列 (${songs.length})'),
                    Tab(text: '历史快照 (${historyList.length})'),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 0.5),

              // Tab 页面内容展示
              Expanded(
                child: TabBarView(
                  children: [
                    // ── Tab 1: 当前播放队列 ──
                    _buildCurrentQueue(
                      context,
                      mp,
                      songs,
                      currentMusic,
                      cs,
                      tt,
                    ),

                    // ── Tab 2: 队列历史快照 ──
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

  /// 当前队列列表构件
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
        child: Text(
          '播放队列为空',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        // 队列操作工具栏
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: mp.togglePlayMode,
                tooltip: modeTooltip(mp.playMode),
                icon: Icon(modeIcon(mp.playMode)),
                color: cs.onSurfaceVariant,
              ),
              IconButton(
                tooltip: '清空队列',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: mp.clearQueue,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: songs.length,
            onReorder: mp.reorderQueue,
            buildDefaultDragHandles: false,
            itemBuilder: (context, index) {
              final m = songs[index];
              final isCurrent = currentMusic?.id == m.id;

              return ListTile(
                key: ValueKey('queue_${m.id}_$index'),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: isCurrent
                        ? Icon(
                            Icons.volume_up_rounded,
                            size: 20,
                            color: cs.primary,
                          )
                        : Icon(
                            Icons.drag_handle_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                  ),
                ),
                title: Text(
                  m.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyLarge?.copyWith(
                    color: isCurrent ? cs.primary : cs.onSurface,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  m.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(
                    color: isCurrent
                        ? cs.primary.withValues(alpha: 0.8)
                        : cs.onSurfaceVariant,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => mp.removeFromQueue(index),
                  color: cs.onSurfaceVariant,
                  tooltip: '从队列移除',
                ),
                selected: isCurrent,
                onTap: () => mp.playByIndex(index),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 历史快照列表构件
  Widget _buildQueueHistory(
    BuildContext context,
    MusicProvider mp,
    List<QueueSnapshot> history,
    ColorScheme cs,
    TextTheme tt,
  ) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          '暂无队列历史记录',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    return Column(
      children: [
        // 历史栏操作栏
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: '清空历史快照',
                icon: const Icon(Icons.delete_sweep_rounded),
                onPressed: mp.clearQueueHistory,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: history.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final snapshot = history[index];
              final titleName = snapshot.name;

              return Card(
                elevation: 0,
                color: cs.surfaceContainer,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  title: Text(
                    titleName,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '包含 ${snapshot.songs.length} 首歌曲',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () {
                      mp.restoreQueueFromHistory(snapshot);
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('恢复并播放'),
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
