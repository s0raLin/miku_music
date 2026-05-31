// ─── 封面 + 元信息 + 控制台 ───────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:provider/provider.dart';

class CoverTabContent extends StatefulWidget {
  final Music music;

  const CoverTabContent({super.key, required this.music});

  @override
  State<CoverTabContent> createState() => _CoverTabContentState();
}

class _CoverTabContentState extends State<CoverTabContent> {
  double? _draggingValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString();
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    final isLiked = playlistProvider
        .getPlaylistSongs(
          PlaylistProvider.favoritesPlaylistId,
          musicProvider.library,
        )
        .any((m) => m.id == widget.music.id);

    return Column(
      children: [
        const SizedBox(height: 20),
        // 封面区域
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxHeight.clamp(
                0.0,
                constraints.maxWidth,
              );
              return Center(
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      color: cs.surfaceContainerHighest,
                      child: widget.music.coverBytes?.isNotEmpty == true
                          ? Image.memory(
                              widget.music.coverBytes!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.music_note_rounded,
                              size: size * 0.3,
                              color: cs.primary.withValues(alpha: 0.5),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),

        // 歌曲元信息区域
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.music.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.music.artist} · ${widget.music.album}',
                    style: TextStyle(
                      fontSize: 15,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                // 1. 在取反之前，先获取“当前”是否已经是喜欢状态
                final wasLiked = playlistProvider
                    .getPlaylistSongs(
                      PlaylistProvider.favoritesPlaylistId,
                      musicProvider.library,
                    )
                    .any((m) => m.id == widget.music.id);

                // 2. 执行切换
                playlistProvider.toggleMusicFavorite(widget.music);

                // 3. 根据切换前的状态（wasLiked）来提示：如果以前是喜欢，那现在就是取消了；反之亦然。
                AppToast.neutral(
                  context,
                  message: wasLiked ? '已取消收藏' : '已添加到喜欢',
                );
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey<bool>(isLiked),
                  color: isLiked ? cs.primary : cs.onSurfaceVariant,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 仅用于包裹进度条与时间文本的 StreamBuilder
        StreamBuilder<PositionData>(
          stream: musicProvider.positionDataStream,
          builder: (context, snapshot) {
            final data =
                snapshot.data ??
                PositionData(Duration.zero, Duration.zero, Duration.zero);
            final totalMs = data.duration.inMilliseconds.toDouble();
            final currentPosMs = data.position.inMilliseconds.toDouble().clamp(
              0.0,
              totalMs,
            );
            final safeTotal = totalMs > 0 ? totalMs : 1.0;

            final sliderValue = _draggingValue ?? currentPosMs;
            // 只有当音乐正在播放，且用户不在拖拽进度条时，波浪才会起伏
            final isWaving =
                musicProvider.player.playing && _draggingValue == null;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: WavySlider(
                    value: sliderValue.clamp(0.0, safeTotal),
                    max: safeTotal,
                    isWaving: isWaving,
                    onChanged: (v) {
                      setState(() {
                        _draggingValue = v;
                      });
                    },
                    onChangeEnd: (v) async {
                      await musicProvider.player.seek(
                        Duration(milliseconds: v.toInt()),
                      );
                      setState(() {
                        _draggingValue = null;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _draggingValue != null
                            ? _formatDuration(
                                Duration(milliseconds: _draggingValue!.toInt()),
                              )
                            : _formatDuration(data.position),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDuration(data.duration),
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        _PlaybackControls(mp: musicProvider),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ─── 播放控制按钮组 ─────────────────────────────────────
class _PlaybackControls extends StatelessWidget {
  final MusicProvider mp;
  const _PlaybackControls({required this.mp});

  @override
  Widget build(BuildContext context) {
    final pageContext = context;
    // final mp = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    IconData modeIcon(PlayMode mode) => switch (mode) {
      PlayMode.sequence => Icons.repeat_rounded,
      PlayMode.shuffle => Icons.shuffle_rounded,
      PlayMode.repeat => Icons.repeat_one_rounded,
    };

    String modeTooltip(PlayMode mode) => switch (mode) {
      PlayMode.sequence => "顺序播放",
      PlayMode.shuffle => "随机播放",
      PlayMode.repeat => "单曲循环",
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        // 可用宽度分五个按钮：模式 + 上一首 + 播放 + 下一首 + 音量
        // 播放按钮比其他按钮大 1.5 倍，其余四个等宽
        // 总宽 = 4 * btnSize + 1.5 * btnSize + 4 * gap
        // 解方程：btnSize = w / (5.5 + 4 * gapRatio)
        // 这里固定 gapRatio = 0.4（gap = 0.4 * btnSize），上限 btnSize 48
        const double gapRatio = 0.4;
        final double btnSize = (w / (5.5 + 4 * gapRatio)).clamp(28.0, 48.0);
        final double gap = btnSize * gapRatio;
        final double playSize = (btnSize * 1.5).clamp(42.0, 72.0);
        final double iconSize = btnSize * 0.65;
        final double playIconSize = playSize * 0.5;

        return StreamBuilder<ProcessingState>(
          stream: mp.player.processingStateStream,
          builder: (context, snapshot) {
            final state = snapshot.data ?? ProcessingState.idle;
            final playing = mp.player.playing;
            final isLoading =
                state == ProcessingState.loading ||
                state == ProcessingState.buffering;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 播放模式
                _CtrlButton(
                  size: btnSize,
                  onPressed: mp.togglePlayMode,
                  tooltip: modeTooltip(mp.playMode),
                  child: Icon(
                    modeIcon(mp.playMode),
                    size: iconSize,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                SizedBox(width: gap),

                // 上一首
                _CtrlButton(
                  size: btnSize,
                  onPressed: mp.playPrev,
                  tooltip: '上一首',
                  child: Icon(
                    Icons.skip_previous_rounded,
                    size: iconSize * 1.1,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(width: gap),

                // 播放 / 暂停
                SizedBox(
                  width: playSize,
                  height: playSize,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none, // 允许微调的外圈指示器稍微溢出一点
                    children: [
                      // 1. 底层放实心按钮
                      FilledButton(
                        onPressed: mp.togglePlay,
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primaryContainer,
                          foregroundColor: cs.onPrimaryContainer,
                          minimumSize: Size(playSize, playSize),
                          maximumSize: Size(playSize, playSize),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              playSize * 0.28,
                            ),
                          ),
                          elevation: 0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 150),
                          child: Icon(
                            playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey<bool>(playing),
                            size: playIconSize,
                          ),
                        ),
                      ),

                      // 2. 顶层放加载圈，并往外扩张 4 像素，形成优雅的“外环包裹”效果
                      if (isLoading)
                        Positioned.fill(
                          top: -2,
                          bottom: -2,
                          left: -2,
                          right: -2,
                          child: IgnorePointer(
                            // 防止阻挡按钮的点击事件
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: cs.primary,
                              // 稍微带有一点平滑边缘
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: gap),

                // 下一首
                _CtrlButton(
                  size: btnSize,
                  onPressed: mp.playNext,
                  tooltip: '下一首',
                  child: Icon(
                    Icons.skip_next_rounded,
                    size: iconSize * 1.1,
                    color: cs.onSurface,
                  ),
                ),
                SizedBox(width: gap),

                _CtrlButton(
                  size: btnSize,
                  tooltip: '当前播放队列',
                  onPressed: () {
                    Scaffold.of(pageContext).openEndDrawer();
                  },
                  child: Icon(
                    Icons.queue_music_rounded,
                    size: iconSize,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── 统一尺寸的控制按钮 ────────────────────────────────────────────────────────
class _CtrlButton extends StatelessWidget {
  final double size;
  final VoidCallback onPressed;
  final String tooltip;
  final Widget child;

  const _CtrlButton({
    required this.size,
    required this.onPressed,
    required this.tooltip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}
