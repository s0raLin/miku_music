import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final music = context.select<MusicProvider, Music?>((p) => p.currentMusic);

    // 如果没有播放歌曲，彻底隐藏
    if (music == null) return const SizedBox.shrink();

    return Material(
      // 采用 M3 规范的 surfaceContainer 颜色
      color: cs.surfaceContainer,

      child: InkWell(
          onTap: () => context.push("/music-detail"),
          child: SizedBox(
            height: 72 ,
            child: Stack(
              children: [
                // 1. 全端统一：顶部的迷你触控进度条（吸附在容器上边缘）
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _MiniProgressBar(),
                ),

                // 2. 主体内容行：弹性自适应，不再用 width 判断宽度
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Row(
                      children: [
                        // 左侧：歌曲信息（自动占据剩余空间的最左侧）
                        Expanded(child: _TrackInfoTile(music: music)),
                        const SizedBox(width: 16),

                        // 右侧：M3 精致控制按钮组合（在手机上紧凑，在桌面上自然靠右）
                        const _PlaybackControlsSection(),
                      ],
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

// ============================================================
// 歌曲信息块（支持响应式挤压缩略）
// ============================================================
class _TrackInfoTile extends StatelessWidget {
  final Music music;
  const _TrackInfoTile({required this.music});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Hero(
          tag: 'music_cover_${music.id}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: music.coverBytes != null && music.coverBytes!.isNotEmpty
                ? Image.memory(
                    music.coverBytes!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      Icons.music_note_rounded,
                      size: 28,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        // Flexible 防止文本过长撑爆 Row 导致溢出报错
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                music.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                music.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 统一的控制按钮区域
// ============================================================
class _PlaybackControlsSection extends StatelessWidget {
  const _PlaybackControlsSection();

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 上一首 (在大屏/桌面端更舒适，窄屏下也会优雅贴合)
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          iconSize: 24,
          tooltip: '上一首',
          onPressed: mp.playPrev,
        ),
        const SizedBox(width: 4),

        // 核心播放按钮：采用 M3 FilledIconButton 规范（44x44dp）
        IconButton.filled(
          onPressed: () => mp.togglePlay(),
          style: IconButton.styleFrom(
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            minimumSize: const Size(44, 44),
            maximumSize: const Size(44, 44),
          ),
          tooltip: isPlaying ? '暂停' : '播放',
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 26,
          ),
        ),
        const SizedBox(width: 4),

        // 下一首
        IconButton(
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 24,
          tooltip: '下一首',
          onPressed: mp.playNext,
        ),
        const SizedBox(width: 4),

        // 队列按钮
        IconButton(
          icon: const Icon(Icons.queue_music_rounded),
          iconSize: 22,
          tooltip: '播放队列',
          onPressed: () => _showQueue(context),
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

// ============================================================
// 顶部触控迷你进度条
// ============================================================
class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar();

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
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
              minHeight: 4,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// 播放队列 Bottom Sheet
// ============================================================
class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mp = context.watch<MusicProvider>();

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
                  color: cs.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('播放队列 (${mp.queue.length})', style: tt.titleMedium),
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: mp.queue.length,
                itemBuilder: (context, index) {
                  final m = mp.queue[index];
                  final isCurrent = mp.currentMusic?.id == m.id;

                  return ListTile(
                    leading: isCurrent
                        ? Lottie.asset(
                            MyAssets.equalizer,
                            width: 20,
                            height: 20,
                            animate: mp.player.playing,
                          )
                        : Icon(
                            Icons.music_note_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                    title: Text(
                      m.title,
                      style: tt.bodyLarge?.copyWith(
                        color: isCurrent ? cs.primary : null,
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      m.artist,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
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
