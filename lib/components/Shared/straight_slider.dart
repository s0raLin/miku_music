import 'package:flutter/material.dart';

class _SliderSettings {
  static const double hPadding = 16.0;
  static const double componentHeight = 44.0;
  static const double trackHeight = 6.0;
  static const double thumbWidth = 4.0;
  static const double thumbHeight = 20.0;
  static const double thumbRadius = 2.0;
}

class StraightSlider extends StatefulWidget {
  final double value;
  final double max;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const StraightSlider({
    super.key,
    required this.value,
    required this.max,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  State<StraightSlider> createState() => _StraightSliderState();
}

class _StraightSliderState extends State<StraightSlider> {
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
            widget.onChanged?.call(_clamp(_xToValue(localX, totalWidth)));
          },
          onHorizontalDragEnd: (d) {
            widget.onChangeEnd?.call(_clamp(widget.value));
          },
          onTapDown: (d) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localX = box.globalToLocal(d.globalPosition).dx;
            final v = _clamp(_xToValue(localX, totalWidth));
            widget.onChanged?.call(v);
            widget.onChangeEnd?.call(v);
          },
          child: SizedBox(
            height: _SliderSettings.componentHeight,
            child: CustomPaint(
              size: Size.infinite,
              painter: _StraightSliderPainter(
                value: widget.value,
                max: widget.max,
                colorScheme: cs,
                hPadding: _SliderSettings.hPadding,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StraightSliderPainter extends CustomPainter {
  final double value;
  final double max;
  final ColorScheme colorScheme;
  final double hPadding;

  const _StraightSliderPainter({
    required this.value,
    required this.max,
    required this.colorScheme,
    required this.hPadding,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final safeMax = max > 0 ? max : 1.0;
    final progress = (value / safeMax).clamp(0.0, 1.0);

    final cy = size.height / 2;
    final trackLeft = hPadding;
    final trackRight = size.width - hPadding;
    final trackWidth = (trackRight - trackLeft).clamp(0.0, double.infinity);
    final thumbX = trackLeft + trackWidth * progress;

    final cs = colorScheme;

    if (trackWidth <= 0) return;

    // 1. inactive track background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          trackLeft,
          cy - _SliderSettings.trackHeight / 2,
          trackWidth,
          _SliderSettings.trackHeight,
        ),
        const Radius.circular(_SliderSettings.trackHeight / 2),
      ),
      Paint()..color = cs.surfaceContainerHighest,
    );

    // 2. active progress fill
    if (progress > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            trackLeft,
            cy - _SliderSettings.trackHeight / 2,
            (thumbX - trackLeft).clamp(0.0, trackWidth),
            _SliderSettings.trackHeight,
          ),
          const Radius.circular(_SliderSettings.trackHeight / 2),
        ),
        Paint()..color = cs.primary,
      );
    }

    // 3. unified capsule thumb
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          thumbX - _SliderSettings.thumbWidth / 2,
          cy - _SliderSettings.thumbHeight / 2,
          _SliderSettings.thumbWidth,
          _SliderSettings.thumbHeight,
        ),
        const Radius.circular(_SliderSettings.thumbRadius),
      ),
      Paint()..color = cs.primary,
    );
  }

  @override
  bool shouldRepaint(_StraightSliderPainter old) =>
      old.value != value || old.max != max || old.colorScheme != colorScheme;
}
