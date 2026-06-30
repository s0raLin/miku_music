import 'dart:math' as math;

import 'package:flutter/material.dart';

class _SliderSettings {
  static const double hPadding = 16.0;
  static const double componentHeight = 44.0;
  static const double trackHeight = 6.0;
  static const double thumbWidth = 4.0;
  static const double thumbHeight = 20.0;
  static const double thumbRadius = 2.0;
}

class WavySlider extends StatefulWidget {
  final double value;
  final double max;
  final bool isWaving;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  const WavySlider({
    super.key,
    required this.value,
    required this.max,
    required this.isWaving,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<WavySlider> createState() => _WavySliderState();
}

class _WavySliderState extends State<WavySlider>
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
  void didUpdateWidget(covariant WavySlider oldWidget) {
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

  double _clamp(double v) {
    final safeMax = widget.max > 0 ? widget.max : 0.0;
    return v.clamp(0.0, safeMax);
  }

  double _xToValue(double x, double totalWidth) {
    final trackWidth = totalWidth - _SliderSettings.hPadding * 2;
    if (trackWidth <= 0) return 0.0;
    final ratio = ((x - _SliderSettings.hPadding) / trackWidth).clamp(0.0, 1.0);
    return ratio * widget.max;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localX = box.globalToLocal(d.globalPosition).dx;
            widget.onChanged(_clamp(_xToValue(localX, totalWidth)));
          },
          onHorizontalDragEnd: (d) {
            widget.onChangeEnd?.call(_clamp(widget.value));
          },
          onTapDown: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localX = box.globalToLocal(d.globalPosition).dx;
            final v = _clamp(_xToValue(localX, totalWidth));
            widget.onChanged(v);
            widget.onChangeEnd?.call(v);
          },
          child: AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return SizedBox(
                height: _SliderSettings.componentHeight,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _WavySliderPainter(
                    value: widget.value,
                    max: widget.max,
                    phase: _waveController.value * 2 * math.pi,
                    activeColor: cs.primary,
                    inactiveColor: cs.surfaceContainerHighest,
                    hPadding: _SliderSettings.hPadding,
                  ),
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
  final double value;
  final double max;
  final double phase;
  final Color activeColor;
  final Color inactiveColor;
  final double hPadding;

  _WavySliderPainter({
    required this.value,
    required this.max,
    required this.phase,
    required this.activeColor,
    required this.inactiveColor,
    required this.hPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final safeMax = max > 0 ? max : 1.0;
    final progress = (value / safeMax).clamp(0.0, 1.0);

    final double midY = size.height / 2;
    final double trackLeft = hPadding;
    final double trackRight = size.width - hPadding;
    final double trackWidth = (trackRight - trackLeft).clamp(
      0.0,
      double.infinity,
    );
    final double thumbX = trackLeft + trackWidth * progress;

    if (trackWidth <= 0) return;

    // 1. inactive track from right edge of thumb to track end
    final double inactiveStartX = (thumbX + _SliderSettings.thumbWidth / 2)
        .clamp(trackLeft, trackRight);
    if (inactiveStartX < trackRight) {
      canvas.drawLine(
        Offset(inactiveStartX, midY),
        Offset(trackRight, midY),
        Paint()
          ..color = inactiveColor
          ..strokeWidth = _SliderSettings.trackHeight
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    // 2. active region - wave sine curve
    final double waveMaxX = (thumbX - _SliderSettings.thumbWidth / 2).clamp(
      trackLeft,
      trackRight,
    );

    if (waveMaxX > trackLeft) {
      final path = Path();
      path.moveTo(trackLeft, midY);

      const double maxAmplitude = 3.5;
      const double waveLength = 48.0;

      for (double x = trackLeft; x <= waveMaxX; x += 1.0) {
        final double relativeX = (x - trackLeft) / waveLength;

        final double fadeInFactor = ((x - trackLeft) / 32.0).clamp(0.0, 1.0);
        final double distanceFromThumb = waveMaxX - x;
        final double fadeOutFactor = (distanceFromThumb / 32.0).clamp(0.0, 1.0);
        final double currentAmplitude =
            maxAmplitude * fadeInFactor * fadeOutFactor;

        final double y =
            midY + math.sin(relativeX * 2 * math.pi - phase) * currentAmplitude;
        path.lineTo(x, y);
      }
      path.lineTo(waveMaxX, midY);

      canvas.drawPath(
        path,
        Paint()
          ..color = activeColor
          ..strokeWidth = _SliderSettings.trackHeight
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }

    // 3. capsule thumb
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          thumbX - _SliderSettings.thumbWidth / 2,
          midY - _SliderSettings.thumbHeight / 2,
          _SliderSettings.thumbWidth,
          _SliderSettings.thumbHeight,
        ),
        const Radius.circular(_SliderSettings.thumbRadius),
      ),
      Paint()..color = activeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _WavySliderPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.max != max ||
        oldDelegate.phase != phase ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
