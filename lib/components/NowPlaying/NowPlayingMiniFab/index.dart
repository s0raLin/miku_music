import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class NowPlayingMiniFab extends StatelessWidget {
  const NowPlayingMiniFab({super.key});

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;
    final music = mp.currentMusic;

    // 1. 无歌曲播放时直接消失
    if (music == null) return const SizedBox.shrink();

    final isPlaying = mp.player.playing;

    return Tooltip(
      message: isPlaying ? '长按恢复播放条' : '播放/暂停',
      child: GestureDetector(
        // M3 推荐：双击进入详情页，长按切换 Mini 模式，单击控制播放
        onLongPress: () {
          mp.setMiniMode(false);
          Feedback.forLongPress(context);
        },
        onDoubleTap: () => context.push('/music-detail'),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 2. 环绕在最外圈的 M3 进度条
              const _FabCircularProgress(),

              // 3. 核心 M3 按钮：使用 FilledTonalIconButton（色调图标按钮），比标准 primaryContainer 更温和现代
              IconButton.filledTonal(
                onPressed: () => mp.togglePlay(),
                style: IconButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  maximumSize: const Size(44, 44),
                  backgroundColor: cs.primaryContainer,
                  foregroundColor: cs.onPrimaryContainer,
                  elevation: 3, // 赋予轻微悬浮感
                ),
                // 使用带有平滑缩放过渡的图标切换
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isPlaying
                        ? Icons.music_note_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey<bool>(isPlaying),
                    size: 22,
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
// 统一收纳的 M3 环绕式进度条
// ============================================================
class _FabCircularProgress extends StatelessWidget {
  const _FabCircularProgress();

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

        return SizedBox(
          width: 54, // 刚好包裹在 44dp 按钮外侧，形成精美外环
          height: 54,
          child: CircularProgressIndicator(
            value: value,
            strokeWidth: 2.5, // 稍微加粗，符合 M3 明确的几何线条感
            color: cs.primary,
            backgroundColor: cs.primary.withValues(alpha: 0.12),
            strokeCap: StrokeCap.round, // 圆头进度条，视觉极佳
          ),
        );
      },
    );
  }
}
