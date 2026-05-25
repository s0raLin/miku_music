// ─── 封面 + 元信息 + 控制台 ───────────────────────────────────────────────────

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class CoverTabContent extends StatefulWidget {
  final MusicInfo music;
  final bool isLiked;

  const CoverTabContent({
    super.key,
    required this.music,
    required this.isLiked,
  });

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
    final provider = context.read<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

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

        // 歌曲元信息区域（M3 风格对齐）
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
                provider.toggleFav(widget.music);
                final isFav = provider.favList.any(
                  (m) => m.id == widget.music.id,
                );
                AppToast.neutral(context, message: isFav ? '已添加到喜欢' : '已取消收藏');
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  widget.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  key: ValueKey<bool>(widget.isLiked),
                  color: widget.isLiked ? cs.primary : cs.onSurfaceVariant,
                  size: 28,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: cs.onSurfaceVariant,
                size: 24,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'add', child: Text('添加到歌单')),
              ],
              onSelected: (_) => _showAddToPlaylistSheet(context, widget.music),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 进度条与播放控制流（更换为蛇形 M3 滑条）
        StreamBuilder<PositionData>(
          stream: provider.positionDataStream,
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
            // 当音乐正在播放且用户没有拖动时，激活蛇形波浪动画
            final isWaving = provider.player.playing && _draggingValue == null;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: M3WavySlider(
                    value: sliderValue.clamp(0.0, safeTotal),
                    max: safeTotal,
                    isWaving: isWaving,
                    onChanged: (v) {
                      setState(() {
                        _draggingValue = v;
                      });
                    },
                    onChangeEnd: (v) async {
                      await provider.player.seek(
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
                const SizedBox(height: 20),
                _PlaybackControls(provider: provider),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Future<void> _showAddToPlaylistSheet(
    BuildContext context,
    MusicInfo song,
  ) async {
    // TODO
  }
}

// ─── 智能动画蛇形进度条组件 ──────────────────────────────────────────────────────

class M3WavySlider extends StatefulWidget {
  final double value;
  final double max;
  final bool isWaving;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const M3WavySlider({
    super.key,
    required this.value,
    required this.max,
    required this.isWaving,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<M3WavySlider> createState() => _M3WavySliderState();
}

class _M3WavySliderState extends State<M3WavySlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    // 1. 【速度优化】将时间拉长到 2500ms（原 800ms），让波浪流动变得非常极其舒缓、平滑
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.isWaving) _waveController.repeat();
  }

  @override
  void didUpdateWidget(covariant M3WavySlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWaving && !_waveController.isAnimating) {
      _waveController.repeat();
    } else if (!widget.isWaving && _waveController.isAnimating) {
      _waveController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _handleDrag(DragUpdateDetails details, double maxWidth) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final percent = (localPosition.dx / maxWidth).clamp(0.0, 1.0);
    widget.onChanged(percent * widget.max);
  }

  void _handleTap(TapUpDetails details, double maxWidth) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final percent = (localPosition.dx / maxWidth).clamp(0.0, 1.0);
    widget.onChanged(percent * widget.max);
    widget.onChangeEnd?.call(percent * widget.max);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final percent = widget.max > 0
            ? (widget.value / widget.max).clamp(0.0, 1.0)
            : 0.0;

        return GestureDetector(
          onHorizontalDragUpdate: (details) => _handleDrag(details, maxWidth),
          onHorizontalDragEnd: (details) =>
              widget.onChangeEnd?.call(widget.value),
          onTapUp: (details) => _handleTap(details, maxWidth),
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(double.infinity, 32),
                painter: _WavySliderPainter(
                  percent: percent,
                  phase: _waveController.value * 2 * math.pi,
                  activeColor: cs.primary,
                  inactiveColor: cs.primary.withValues(alpha: 0.15),
                  thumbColor: cs.primary,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _WavySliderPainter extends CustomPainter {
  final double percent;
  final double phase;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  _WavySliderPainter({
    required this.percent,
    required this.phase,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double thumbX = size.width * percent;

    // 1. 绘制后端（未播放部分：保持纯直线轨道）
    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (thumbX < size.width) {
      canvas.drawLine(
        Offset(thumbX, midY),
        Offset(size.width, midY),
        inactivePaint,
      );
    }

    // 2. 绘制前端（已播放部分：双端收敛的完美呼吸波浪）
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (thumbX > 0) {
      final path = Path();
      path.moveTo(0, midY);

      const double maxAmplitude = 3.0; // 适当恢复一点振幅，因为两头收敛了，中间需要看得清
      const double waveLength = 54.0;

      for (double x = 0; x <= thumbX; x += 1.0) {
        final double relativeX = x / waveLength;

        // 【左端收敛】靠近 0 的时候，振幅淡入 (0 ~ 48px 之间)
        final double fadeInFactor = (x / 48.0).clamp(0.0, 1.0);

        // 【右端收敛】靠近滑块 thumbX 的时候，振幅淡出 (在距离滑块最后 32px 内收敛为 0)
        final double distanceFromThumb = thumbX - x;
        final double fadeOutFactor = (distanceFromThumb / 32.0).clamp(0.0, 1.0);

        // 结合双端系数，计算当前点真正的振幅
        final double currentAmplitude =
            maxAmplitude * fadeInFactor * fadeOutFactor;

        final double y =
            midY + math.sin(relativeX * 2 * math.pi - phase) * currentAmplitude;
        path.lineTo(x, y);
      }
      path.lineTo(thumbX, midY); // 确保最后一行完美对齐滑块中心线
      canvas.drawPath(path, activePaint);
    }

    // 3. 绘制圆形滑块（Thumb）
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(thumbX, midY), 6, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WavySliderPainter oldDelegate) {
    return oldDelegate.percent != percent ||
        oldDelegate.phase != phase ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

// ─── 播放控制按钮组（全面采用 M3 自带系统图标） ─────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  final MusicProvider provider;

  const _PlaybackControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 完全使用 Flutter M3 自带的图标系统，免去图片断联风险
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

    return StreamBuilder<ProcessingState>(
      stream: provider.player.processingStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? ProcessingState.idle;
        final playing = provider.player.playing;

        final isLoading =
            state == ProcessingState.loading ||
            state == ProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: provider.togglePlayMode,
              icon: Icon(modeIcon(provider.playMode)),
              color: cs.onSurfaceVariant,
              tooltip: modeTooltip(provider.playMode),
            ),
            const SizedBox(width: 20),
            // 使用系统自带 M3 上一首图标
            IconButton(
              onPressed: provider.playPrev,
              tooltip: '上一首',
              icon: const Icon(Icons.skip_previous_rounded, size: 32),
              color: cs.onSurface,
            ),
            const SizedBox(width: 20),

            // 播放/暂停大按钮（标准 M3 FilledIconButton 变体）
            SizedBox(
              width: 72,
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isLoading)
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        strokeWidth: 3.5,
                        color: cs.primary,
                      ),
                    ),
                  IconButton.filled(
                    onPressed: provider.togglePlay,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey<bool>(playing),
                        size: 36,
                      ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.primaryContainer,
                      foregroundColor: cs.onPrimaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0, // M3 默认推荐扁平容器色，如果喜欢悬浮可以给 2
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // 使用系统自带 M3 下一首图标
            IconButton(
              onPressed: provider.playNext,
              tooltip: '下一首',
              icon: const Icon(Icons.skip_next_rounded, size: 32),
              color: cs.onSurface,
            ),
            const SizedBox(width: 20),
            _VolumeButton(provider: provider),
          ],
        );
      },
    );
  }
}

// ─── 音量按钮（M3 风格化） ────────────────────────────────────────────────────

class _VolumeButton extends StatefulWidget {
  final MusicProvider provider;

  const _VolumeButton({required this.provider});

  @override
  State<_VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<_VolumeButton> {
  final MenuController _menuController = MenuController();
  double _lastNonZeroVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<double>(
      stream: widget.provider.player.volumeStream,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? widget.provider.volume;
        if (volume > 0) _lastNonZeroVolume = volume;

        final icon = volume == 0
            ? Icons.volume_off_rounded
            : volume < 0.5
            ? Icons.volume_down_rounded
            : Icons.volume_up_rounded;

        return MenuAnchor(
          controller: _menuController,
          alignmentOffset: const Offset(-10, -10),
          style: MenuStyle(
            backgroundColor: WidgetStateProperty.all(cs.surfaceContainerHigh),
            elevation: WidgetStateProperty.all(6),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          menuChildren: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SizedBox(
                height: 140,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      inactiveTrackColor: cs.primary.withValues(alpha: 0.1),
                      activeTrackColor: cs.primary,
                      thumbColor: cs.primary,
                    ),
                    child: Slider(
                      value: volume.clamp(0.0, 1.0),
                      onChanged: (v) => widget.provider.setVolume(v),
                    ),
                  ),
                ),
              ),
            ),
          ],
          child: GestureDetector(
            onLongPress: () => _menuController.open(),
            child: IconButton(
              tooltip: '单击静音/长按调音',
              onPressed: () async {
                final targetVol = volume == 0
                    ? _lastNonZeroVolume.clamp(0.0, 1.0)
                    : 0.0;
                await widget.provider.setVolume(targetVol);
              },
              icon: Icon(icon),
              style: IconButton.styleFrom(
                foregroundColor: cs.onSurfaceVariant,
                backgroundColor: _menuController.isOpen
                    ? cs.surfaceContainerHighest
                    : Colors.transparent,
              ),
            ),
          ),
        );
      },
    );
  }
}
