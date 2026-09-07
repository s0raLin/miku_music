import 'dart:math' as math;

import 'package:flutter/material.dart';

// ============================================================================
// OrganicSplash - 最终稳定版（解决永久残留）
// ============================================================================

class OrganicSplash extends InteractiveInkFeature {
  OrganicSplash({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required TextDirection textDirection,
    required Offset position,
    required Color color,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  })  : _position = position,
        _borderRadius = borderRadius ?? BorderRadius.zero,
        _textDirection = textDirection,
        _targetRadius = radius ??
            _getTargetRadius(referenceBox, containedInkWell, rectCallback, position),
        _clipCallback = _getClipCallback(referenceBox, containedInkWell, rectCallback),
        super(
          controller: controller,
          referenceBox: referenceBox,
          color: _makeVivid(color),
          customBorder: customBorder,
          onRemoved: onRemoved,
        ) {
    // 半径动画
    _radiusController = AnimationController(
      duration: const Duration(milliseconds: 420),
      vsync: controller.vsync,
    )..addListener(controller.markNeedsPaint);

    _radius = Tween<double>(
      begin: 0.0,
      end: _targetRadius,
    ).animate(CurvedAnimation(
      parent: _radiusController,
      curve: Curves.easeOutCubic,
    ));

    // 透明度动画 + 关键：完成后主动 dispose
    _alphaController = AnimationController(
      duration: const Duration(milliseconds: 480),
      vsync: controller.vsync,
    )
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_handleAlphaStatusChanged);

    _alpha = Tween<double>(
      begin: 0.32,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _alphaController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    ));

    // 立即开始
    _radiusController.forward();
    _alphaController.forward();

    controller.addInkFeature(this);
  }

  final Offset _position;
  final BorderRadius _borderRadius;
  final TextDirection _textDirection;
  final double _targetRadius;
  final RectCallback? _clipCallback;

  late final AnimationController _radiusController;
  late final Animation<double> _radius;
  late final AnimationController _alphaController;
  late final Animation<double> _alpha;

  static const double _ellipseRatio = 1.05;

  static Color _makeVivid(Color c) {
    final HSLColor hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation * 1.28).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * 0.90).clamp(0.0, 1.0))
        .toColor();
  }

  // ★★★ 核心：透明度动画结束后主动销毁自己（官方标准做法）
  void _handleAlphaStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      dispose();
    }
  }

  @override
  void confirm() {
    final int duration = (_targetRadius / 1.3).round().clamp(180, 380);
    _radiusController
      ..duration = Duration(milliseconds: duration)
      ..forward();
    _alphaController.forward();
  }

  @override
  void cancel() {
    _alphaController.forward(); // 直接淡出
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _alphaController.dispose();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final double currentRadius = _radius.value;
    if (currentRadius < 1.0) return;

    final double opacity = _alpha.value.clamp(0.0, 1.0);
    if (opacity < 0.01) return;

    final Paint paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final double rx = currentRadius * _ellipseRatio;
    final double ry = currentRadius / _ellipseRatio;

    // 用半径进度模拟轻微波动（不再需要额外的无限循环 Controller）
    final double phase = _radiusController.value * math.pi * 4;
    final Path path = Path();

    const int segments = 48;
    for (int i = 0; i <= segments; i++) {
      final double angle = (i / segments) * math.pi * 2;

      final double wave = 1.0 +
          0.022 * math.sin(angle * 3.0 + phase) +
          0.011 * math.sin(angle * 5.0 - phase * 1.3);

      final double x = _position.dx + rx * wave * math.cos(angle);
      final double y = _position.dy + ry * wave * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.save();
    canvas.transform(transform.storage);

    if (_clipCallback != null) {
      final Rect rect = _clipCallback();
      if (customBorder != null) {
        canvas.clipPath(
          customBorder!.getOuterPath(rect, textDirection: _textDirection),
        );
      } else {
        canvas.clipRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: _borderRadius.topLeft,
            topRight: _borderRadius.topRight,
            bottomLeft: _borderRadius.bottomLeft,
            bottomRight: _borderRadius.bottomRight,
          ),
        );
      }
    }

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  // -------------------- 工具方法 --------------------

  static double _getTargetRadius(
    RenderBox referenceBox,
    bool containedInkWell,
    RectCallback? rectCallback,
    Offset position,
  ) {
    final Size size =
        rectCallback != null ? rectCallback().size : referenceBox.size;

    final double d1 = (Offset.zero - position).distance;
    final double d2 = (Offset(size.width, 0) - position).distance;
    final double d3 = (Offset(0, size.height) - position).distance;
    final double d4 = (Offset(size.width, size.height) - position).distance;

    final double maxDistance = math.max(math.max(d1, d2), math.max(d3, d4));

    // 限制扩散范围，避免变成矩形
    return maxDistance * 0.58;
  }

  static RectCallback? _getClipCallback(
    RenderBox referenceBox,
    bool containedInkWell,
    RectCallback? rectCallback,
  ) {
    if (rectCallback != null) {
      assert(containedInkWell);
      return rectCallback;
    }
    if (containedInkWell) {
      return () => Offset.zero & referenceBox.size;
    }
    return null;
  }
}

// ============================================================================
// Factory
// ============================================================================

class _OrganicSplashFactory extends InteractiveInkFeatureFactory {
  const _OrganicSplashFactory();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    return OrganicSplash(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}

class OrganicSplashFactory {
  static const InteractiveInkFeatureFactory splashFactory =
      _OrganicSplashFactory();
}
