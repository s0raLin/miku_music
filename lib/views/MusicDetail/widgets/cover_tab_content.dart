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

        // 💡 仅用于包裹进度条与时间文本的 StreamBuilder
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
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // 【核心修改位置】将控制台移出 StreamBuilder 外层，独立渲染
        _PlaybackControls(provider: provider),
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

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (thumbX > 0) {
      final path = Path();
      path.moveTo(0, midY);

      const double maxAmplitude = 3.0;
      const double waveLength = 54.0;

      for (double x = 0; x <= thumbX; x += 1.0) {
        final double relativeX = x / waveLength;
        final double fadeInFactor = (x / 48.0).clamp(0.0, 1.0);
        final double distanceFromThumb = thumbX - x;
        final double fadeOutFactor = (distanceFromThumb / 32.0).clamp(0.0, 1.0);
        final double currentAmplitude =
            maxAmplitude * fadeInFactor * fadeOutFactor;

        final double y =
            midY + math.sin(relativeX * 2 * math.pi - phase) * currentAmplitude;
        path.lineTo(x, y);
      }
      path.lineTo(thumbX, midY);
      canvas.drawPath(path, activePaint);
    }

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

// ─── 播放控制按钮组 ─────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  final MusicProvider provider;

  const _PlaybackControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    // 💡 使用 watch 监听 MusicProvider，以便播放模式或状态改变时能及时重新渲染
    final mp = context.watch<MusicProvider>();
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
            IconButton(
              onPressed: mp.togglePlayMode,
              icon: Icon(modeIcon(mp.playMode)),
              color: cs.onSurfaceVariant,
              tooltip: modeTooltip(mp.playMode),
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: mp.playPrev,
              tooltip: '上一首',
              icon: const Icon(Icons.skip_previous_rounded, size: 32),
              color: cs.onSurface,
            ),
            const SizedBox(width: 20),
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
                    onPressed: mp.togglePlay,
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
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: mp.playNext,
              tooltip: '下一首',
              icon: const Icon(Icons.skip_next_rounded, size: 32),
              color: cs.onSurface,
            ),
            const SizedBox(width: 20),
            _VolumeButton(provider: mp),
          ],
        );
      },
    );
  }
}

// ─── 音量按钮 ────────────────────────────────────────────────────
class _VolumeButton extends StatefulWidget {
  final MusicProvider provider;
  const _VolumeButton({required this.provider});

  @override
  State<_VolumeButton> createState() => _VolumeButtonState();
}
class _VolumeButtonState extends State<_VolumeButton>
    with SingleTickerProviderStateMixin {
  // ── Overlay 定位 ──
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayCtrl = OverlayPortalController();

  bool _visible = false;
  Timer? _hideTimer;
  double _lastNonZeroVolume = 1.0;

  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(
    parent: _animCtrl,
    curve: Curves.easeOut,
  );

  void _show() {
    if (!_visible) {
      _overlayCtrl.show();
      setState(() => _visible = true);
      _animCtrl.forward();
    }
    _resetTimer();
  }

  void _hide() {
    _animCtrl.reverse().then((_) {
      if (mounted) {
        _overlayCtrl.hide();
        setState(() => _visible = false);
      }
    });
  }

  void _resetTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), _hide);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

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

        return CompositedTransformTarget(
          link: _layerLink,
          child: OverlayPortal(
            controller: _overlayCtrl,
            overlayChildBuilder: (context) {
              return CompositedTransformFollower(
                link: _layerLink,
                // 胶囊底部对齐按钮顶部，水平居中
                followerAnchor: Alignment.bottomCenter,
                targetAnchor: Alignment.topCenter,
                offset: const Offset(0, -8),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.85, end: 1.0).animate(_fadeAnim),
                      alignment: Alignment.bottomCenter,
                      child: _VolumeCapsule(
                        volume: volume,
                        onChanged: (v) {
                          widget.provider.setVolume(v);
                          _resetTimer();
                        },
                        onInteract: _resetTimer,
                      ),
                    ),
                  ),
                ),
              );
            },
            child: IconButton(
              tooltip: '点击调音',
              icon: Icon(icon),
              color: cs.onSurfaceVariant,
              onPressed: () {
                if (!_visible) {
                  _show();
                } else {
                  // 胶囊已显示时点击图标：静音 / 恢复
                  final target = volume == 0 ? _lastNonZeroVolume : 0.0;
                  widget.provider.setVolume(target);
                  _resetTimer();
                }
              },
            ),
          ),
        );
      },
    );
  }
}

// ── 胶囊本体 ──────────────────────────────────────────────────────────────────

class _VolumeCapsule extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onChanged;
  final VoidCallback onInteract;

  const _VolumeCapsule({
    required this.volume,
    required this.onChanged,
    required this.onInteract,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const double capsuleW = 44;
    const double capsuleH = 180;

    return GestureDetector(
      onVerticalDragUpdate: (d) {
        final delta = -d.delta.dy / capsuleH;
        onChanged((volume + delta).clamp(0.0, 1.0));
      },
      onTap: onInteract,
      child: Container(
        width: capsuleW,
        height: capsuleH,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(capsuleW / 2),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // 填充
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 80),
              heightFactor: volume.clamp(0.0, 1.0),
              widthFactor: 1.0,
              child: Container(color: cs.primary.withValues(alpha: 0.28)),
            ),
            // 图标
            Positioned(
              bottom: 12,
              child: Icon(
                volume == 0
                    ? Icons.volume_off_rounded
                    : volume < 0.5
                    ? Icons.volume_down_rounded
                    : Icons.volume_up_rounded,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
