import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

// ════════════════════════════════════════════════════════════════
//  NowPlayingBar — MD3 胶囊岛形式，悬浮在底部内容之上
//  使用方式：在外部 Stack 中用 Positioned 定位，底部留出导航栏高度
// ════════════════════════════════════════════════════════════════
class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context) {
    final music = context.select<MusicProvider, Music?>((p) => p.currentMusic);
    if (music == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
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
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // 进度条
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CapsuleProgressBar(),
              ),
              // 内容
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(32),
                  onTap: () => context.push('/music-detail'),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      6,
                      6,
                      8,
                      8 + bottomInset,
                    ), // 只保留必要的底部
                    child: Row(
                      children: [
                        _CapsuleCover(music: music),
                        const SizedBox(width: 10),
                        Expanded(child: _CapsuleTrackInfo(music: music)),
                        const _CapsuleControls(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 封面 ──
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
      image = Image.memory(music.coverBytes!, fit: BoxFit.cover);
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
          style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 1),
        Text(
          music.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── 控制按钮 ──
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
        // 上一首
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 22,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          onPressed: mp.playPrev,
          color: cs.onSurface,
        ),
        // 播放/暂停 — 填充圆形按钮
        GestureDetector(
          onTap: mp.togglePlay,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22,
              color: cs.onPrimary,
            ),
          ),
        ),
        // 下一首
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 22,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          onPressed: mp.playNext,
          color: cs.onSurface,
        ),
        // 队列
        IconButton(
          icon: const Icon(Icons.queue_music_rounded),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.all(4),
          onPressed: () => _showQueue(context),
          color: cs.onSurfaceVariant,
        ),
      ],
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _QueueSheet(),
    );
  }
}

// ── 胶囊进度条（贴底 3px）──
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
            PositionData(Duration.zero, Duration.zero, Duration.zero);
        final value = pos.duration.inMilliseconds > 0
            ? (pos.position.inMilliseconds / pos.duration.inMilliseconds).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final dx = details.localPosition.dx / box.size.width;
            mp.player.seek(
              Duration(
                milliseconds: (pos.duration.inMilliseconds * dx).toInt(),
              ),
            );
          },
          child: LinearProgressIndicator(
            value: value,
            minHeight: 3,
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.6),
            valueColor: AlwaysStoppedAnimation(
              cs.primary.withValues(alpha: 0.8),
            ),
            borderRadius: BorderRadius.zero,
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  播放队列 Bottom Sheet
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
    final currentMusic = mp.currentMusic;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('播放队列 (${songs.length})', style: tt.titleMedium),
                if (songs.isNotEmpty)
                  Row(
                    children: [
                      IconButton(
                        onPressed: mp.togglePlayMode,
                        tooltip: modeTooltip(mp.playMode),
                        icon: Icon(modeIcon(mp.playMode)),
                      ),
                      IconButton(
                        tooltip: '清空队列',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: mp.clearQueue,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (songs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                '播放队列为空',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          const Divider(height: 1),
          if (songs.isNotEmpty)
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                ),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: songs.length,
                  onReorderItem: mp.reorderQueue,
                  buildDefaultDragHandles: false,
                  itemBuilder: (context, index) {
                    final m = songs[index];
                    final isCurrent = currentMusic?.id == m.id;
                    return ListTile(
                      key: ValueKey('queue_${m.id}_$index'),
                      leading: ReorderableDragStartListener(
                        index: index,
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
                      title: Text(
                        m.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyLarge?.copyWith(
                          color: isCurrent ? cs.primary : null,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        m.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => mp.removeFromQueue(index),
                      ),
                      selected: isCurrent,
                      onTap: () => mp.playByIndex(index),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
