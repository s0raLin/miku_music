// import 'dart:io';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

export 'EmailVerificationModal.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

enum MediaGridCardTextLayout { below, overlay }

enum AppToastTone { neutral, success, warning, error }

// ---------------------------------------------------------------------------
// 统一圆角常量 — M3 Shape Scale (重设计版: 更柔和、更大的圆角)
// ---------------------------------------------------------------------------
abstract final class AppRadius {
  /// M3 Large (Card 默认): 24dp — 柔和大圆角
  static const double card = 24;

  /// M3 Medium (内嵌图像/头像/panel): 16dp
  static const double inner = 16;

  /// M3 Small (label/chip): 8dp
  static const double sm = 8;

  /// Pill/Stadium: 全圆角
  static const double full = 999;

  static BorderRadius get cardBR => BorderRadius.circular(card);
  static BorderRadius get innerBR => BorderRadius.circular(inner);
  static BorderRadius get pillBR => BorderRadius.circular(full);
}

// ---------------------------------------------------------------------------
// AppToast
// ---------------------------------------------------------------------------
class AppToast {
  AppToast._();

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppToastTone tone = AppToastTone.neutral,
    Duration duration = const Duration(seconds: 2),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();

    final colorScheme = Theme.of(context).colorScheme;

    // M3 Snackbar 语义色映射
    final (bg, fg, icon) = switch (tone) {
      AppToastTone.success => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
        Icons.check_circle_rounded,
      ),
      AppToastTone.warning => (
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
        Icons.warning_rounded,
      ),
      AppToastTone.error => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        Icons.error_rounded,
      ),
      AppToastTone.neutral => (
        colorScheme.inverseSurface,
        colorScheme.onInverseSurface,
        Icons.info_rounded,
      ),
    };

    messenger?.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  Text(
                    message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: fg, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(milliseconds: 1500),
  }) => show(
    context,
    message: message,
    title: title,
    tone: AppToastTone.success,
    duration: duration,
  );

  static void neutral(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(milliseconds: 1500),
  }) => show(
    context,
    message: message,
    title: title,
    tone: AppToastTone.neutral,
    duration: duration,
  );

  static void warning(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(milliseconds: 2000),
  }) => show(
    context,
    message: message,
    title: title,
    tone: AppToastTone.warning,
    duration: duration,
  );

  static void error(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(milliseconds: 2500),
  }) => show(
    context,
    message: message,
    title: title,
    tone: AppToastTone.error,
    duration: duration,
  );
}

// ---------------------------------------------------------------------------
// AppSectionHeader
// ---------------------------------------------------------------------------
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 12), action!],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppPanel
// 用途：通用内容容器，默认走 M3 filled card（surfaceContainerHigh）。
// 若需要更低层次感（如嵌套在已有 Card 内），传入 color: colorScheme.surface。
// ---------------------------------------------------------------------------
class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;

  const AppPanel({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      margin: EdgeInsets.zero,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppRadius.cardBR,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ArtworkCover
// 背景填充色使用 M3 surfaceContainerHighest — 与 Card 背景形成层次对比。
// ---------------------------------------------------------------------------
class ArtworkCover extends StatelessWidget {
  final Uint8List? bytes;
  final IconData fallbackIcon;
  final double borderRadius;
  final double? size;
  final double? aspectRatio;
  final double iconSize;
  final Widget? overlay;

  const ArtworkCover({
    super.key,
    this.bytes,
    required this.fallbackIcon,
    this.borderRadius = AppRadius.inner,
    this.size,
    this.aspectRatio = 1,
    this.iconSize = 48, // 稍微调大一点
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget content;

    if (bytes != null && bytes!.isNotEmpty) {
      content = Image.memory(
        bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // === 重构后的无封面样式 ===
      content = Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerHighest,
              colorScheme.surfaceContainerHigh,
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              fallbackIcon,
              size: iconSize,
              color: colorScheme.primary,
            ),
          ),
        ),
      );
    }

    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [content, if (overlay != null) overlay!],
      ),
    );

    Widget cover = aspectRatio == null
        ? clipped
        : AspectRatio(aspectRatio: aspectRatio!, child: clipped);

    if (size != null) {
      cover = SizedBox(width: size, height: size, child: cover);
    }

    return cover;
  }
}

// ---------------------------------------------------------------------------
// SongListCardTile
//
// 选中态统一使用 M3 secondaryContainer / onSecondaryContainer。
// 未选中态不再手动指定颜色，走 Card.filled 默认（surfaceContainerHigh），
// 与 MediaGridCard below 模式保持一致的视觉层次。
// ---------------------------------------------------------------------------
class SongListCardTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Uint8List? coverBytes;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool highlighted;

  const SongListCardTile({
    super.key,
    required this.title,
    required this.subtitle,
    this.coverBytes,
    required this.fallbackIcon,
    this.onTap,
    this.trailing,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 未选中：Card.filled 默认色（null 即可，无需 surfaceContainerLowest）
    // 选中：M3 secondaryContainer，语义清晰
    final tileColor = highlighted ? colorScheme.secondaryContainer : null;

    return Card.filled(
      color: tileColor,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: ArtworkCover(
          bytes: coverBytes,
          fallbackIcon: fallbackIcon,
          size: 40,
          borderRadius: AppRadius.inner,
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
            color: highlighted
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: highlighted
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}

class MediaOverlayCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Uint8List? coverBytes;
  final String? coverPath;
  final String? coverUrl;
  final Map<String, String>? coverHeaders;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final Widget? badge; // 预留右上角组件（比如序号、状态标签等）
  final bool isLoading; // 预留封面懒加载状态

  const MediaOverlayCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.coverBytes,
    this.coverPath,
    this.coverUrl,
    this.coverHeaders,
    required this.fallbackIcon,
    this.onTap,
    this.badge,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bool hasCover =
        (coverBytes != null && coverBytes!.isNotEmpty) ||
        (coverPath != null && coverPath!.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCoverImage(cs),

              // === 只在有真实封面时才显示强渐变 ===
              if (hasCover)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),

              // 文字层
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasCover ? Colors.white : cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasCover
                            ? Colors.white.withValues(alpha: 0.85)
                            : cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              if (badge != null) Positioned(top: 10, right: 10, child: badge!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(ColorScheme cs) {
    // 优先：判断是否存在内存字节数组
    if (coverBytes != null && coverBytes!.isNotEmpty) {
      return Image.memory(coverBytes!, fit: BoxFit.cover);
    }

    // 其次：网络URL 封面 — 使用 CachedNetworkImage 解决 163 CDN 防盗链
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      final Map<String, String> headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        ...?coverHeaders,
      };
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        httpHeaders: headers,
        placeholder: (_, _) => _buildFallback(cs),
        errorWidget: (_, _, _) => _buildFallback(cs),
      );
    }

    // 再次：判断是否存在路径
    if (coverPath != null && coverPath!.isNotEmpty) {
      // 如果是网络图片 URL
      if (coverPath!.startsWith('http://') ||
          coverPath!.startsWith('https://')) {
        return Image.network(
          coverPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(cs),
        );
      }
      // 如果是本地绝对路径 (比如 /storage/emulated/0/... 或 /Users/...)
      return Image.file(
        File(coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallback(cs),
      );
    }

    // 最后：兜底状态
    return _buildFallback(cs);
  }

  // 加载中状态
  Widget _buildFallback(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
            )
          : Icon(fallbackIcon, size: 44, color: cs.primary),
    );
  }
}

// ---------------------------------------------------------------------------
// AppEmptyState
// ---------------------------------------------------------------------------
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final EdgeInsetsGeometry padding;
  final bool compact;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: compact ? 36 : 48, color: colorScheme.outline),
              SizedBox(height: compact ? 10 : 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (action != null) ...[const SizedBox(height: 14), action!],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppEmptySliver
// ---------------------------------------------------------------------------
class AppEmptySliver extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final bool hasScrollBody;
  final EdgeInsetsGeometry padding;
  final bool compact;

  const AppEmptySliver({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.hasScrollBody = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: hasScrollBody,
      child: AppEmptyState(
        icon: icon,
        title: title,
        subtitle: subtitle,
        action: action,
        padding: padding,
        compact: compact,
      ),
    );
  }
}

// ─── 统一的级联尺寸与设计规范 ──────────────────────────────────────────────────
class _SliderSettings {
  static const double hPadding = 16.0; // 统一两端留白，防止滑块溢出边界
  static const double componentHeight = 44.0; // 统一点击热区高度
  static const double trackHeight = 6.0; // 统一轨道物理粗细

  // 胶囊主滑块参数
  static const double thumbWidth = 4.0;
  static const double thumbHeight = 20.0; // 20dp 的高度更协调，既保留了刻度感又不会过于突兀
  static const double thumbRadius = 2.0; // 微小的圆角，保持硬朗的胶囊质感
}

// ─── 1. 胶囊竖线版 M3 蛇形进度条 (WavySlider) ──────────────────────────────────
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

    // 1. 未播放区域：从滑块右边缘开始绘制水平直线
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

    // 2. 已播放区域：波浪正弦曲线（终点完美对接滑块左边缘）
    // 🔥 核心优化：波浪终点向左回缩半个滑块宽度，防止浪头刺穿指示器
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
        // 淡出因子改用物理边缘 waveMaxX 计算，确保在撞击滑块前完美收尾
        final double distanceFromThumb = waveMaxX - x;
        final double fadeOutFactor = (distanceFromThumb / 32.0).clamp(0.0, 1.0);
        final double currentAmplitude =
            maxAmplitude * fadeInFactor * fadeOutFactor;

        final double y =
            midY + math.sin(relativeX * 2 * math.pi - phase) * currentAmplitude;
        path.lineTo(x, y);
      }
      // 严丝合缝地连回滑块左边缘的中轴线
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

    // 3. 统一的胶囊竖线滑块
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

// ─── 2. 胶囊竖线版 M3 直线进度条 (StraightSlider) ────────────────────────────────
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

    // 1. 轨道底色 (未播放部分)
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

    // 2. 已播放进度填充
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

    // 3. 统一的胶囊竖线滑块 (完全去除了原点和护翼，保持与 Wavy 一致)
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

class ObservableMusicGridCard extends StatefulWidget {
  final int index;
  final Music music;
  final VoidCallback? onTap;

  const ObservableMusicGridCard({
    super.key,
    required this.music,
    required this.index,
    this.onTap,
  });

  @override
  State<ObservableMusicGridCard> createState() =>
      _ObservableMusicGridCardState();
}

class _ObservableMusicGridCardState extends State<ObservableMusicGridCard> {
  void _triggerLazyCover() {
    final hasNoCover =
        widget.music.coverBytes == null || widget.music.coverBytes!.isEmpty;
    if (hasNoCover) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<MusicProvider>().loadCoverLazy(widget.music.id);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _triggerLazyCover();
  }

  @override
  void didUpdateWidget(ObservableMusicGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.music.id != widget.music.id) {
      _triggerLazyCover();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final musicProvider = context.watch<MusicProvider>();

    final music = musicProvider.library.firstWhere(
      (m) => m.id == widget.music.id,
      orElse: () => widget.music,
    );

    final bool hasNoCover =
        music.coverBytes == null || music.coverBytes!.isEmpty;

    final badgeBackground = colorScheme.surfaceContainerHigh.withValues(
      alpha: colorScheme.brightness == Brightness.dark ? 0.88 : 0.82,
    );

    final isNetwork = music.source == MusicSource.network;
    final coverUrl = isNetwork ? musicProvider.getCoverUrl(music.id) : null;

    return MediaOverlayCard(
      title: music.title,
      subtitle: music.artist,
      coverBytes: music.coverBytes,
      coverUrl: coverUrl,
      coverHeaders: isNetwork && coverUrl != null && coverUrl.contains('music.126.net')
          ? {'Referer': 'https://music.163.com/'}
          : null,
      fallbackIcon: Icons.music_note_rounded,
      onTap: widget.onTap,
      isLoading: hasNoCover && musicProvider.isCoverLoading(music.id),
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBackground,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '#${widget.index + 1}',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ObservableMusicListItem
// ---------------------------------------------------------------------------
class ObservableMusicListItem extends StatelessWidget {
  final Music music;

  const ObservableMusicListItem({super.key, required this.music});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();

    // 1. 粒度化追踪：当前歌曲是否正在被选中（高亮）
    final isCurrent = context.select<MusicProvider, bool>(
      (p) => p.currentMusic?.id == music.id,
    );

    // 2. 粒度化追踪：全局播放状态
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );

    // 3. 纯响应式的延迟加载封面触发
    if (music.coverBytes == null || music.coverBytes!.isEmpty) {
      musicProvider.loadCoverLazy(music.id);
    }

    return SongListCardTile(
      title: music.title,
      subtitle: music.artist,
      coverBytes: music.coverBytes,
      fallbackIcon: Icons.music_note_rounded,
      highlighted: isCurrent,
      onTap: () {
        musicProvider.playFromLibrary(music);
        context.push("/music-detail");
      },
      // 4. 彻底干掉 SongTile 后的多按钮组排放
      trailing: FilledButton.tonal(
        style: FilledButton.styleFrom(
          // 如果想进一步微调颜色，可以取消注释下面两行：
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12), // 让胶囊更紧凑
        ),
        onPressed: () {
          if (!isCurrent) {
            musicProvider.playFromLibrary(music);
          } else {
            musicProvider.togglePlay();
          }
        },
        child: Icon(
          isCurrent && isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          size: 20, // 减小尺寸让胶囊包得更紧凑
        ),
      ),
    );
  }
}

class AdaptiveMenuItem {
  final IconData? icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive; // 是否为危险操作（如删除，M3风格下通常会变红）

  const AdaptiveMenuItem({
    required this.title,
    required this.onTap,
    this.icon,
    this.isDestructive = false,
  });
}

class AdaptiveMenu {
  /// 弹出自适应菜单
  static void show(
    BuildContext context, {
    required List<AdaptiveMenuItem> items,
    required TapDownDetails details, // 用于精确定位桌面端的弹出位置
    String? title, // 底部菜单可以带一个标题
  }) {
    // 阈值设为 600dp（Material 3 标准的大屏分界线）
    final isCompact = MediaQuery.of(context).size.width < 600;

    if (isCompact) {
      _showBottomSheet(context, items, title);
    } else {
      _showPopupMenu(context, items, details);
    }
  }

  /// 1. 移动端：Material 3 底部弹出菜单
  static void _showBottomSheet(
    BuildContext context,
    List<AdaptiveMenuItem> items,
    String? title,
  ) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      // M3 默认支持圆角和拖拽条
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
              ...items.map(
                (item) => ListTile(
                  leading: item.icon != null ? Icon(item.icon) : null,
                  title: Text(item.title),
                  textColor: item.isDestructive
                      ? theme.colorScheme.error
                      : null,
                  iconColor: item.isDestructive
                      ? theme.colorScheme.error
                      : null,
                  onTap: () {
                    Navigator.pop(context); // 先关闭菜单
                    item.onTap(); // 再执行事件
                  },
                ),
              ),
              const SizedBox(height: 16), // 底部留白
            ],
          ),
        );
      },
    );
  }

  /// 2. 桌面端：Material 3 下拉菜单
  static void _showPopupMenu(
    BuildContext context,
    List<AdaptiveMenuItem> items,
    TapDownDetails details,
  ) {
    final theme = Theme.of(context);
    final position = details.globalPosition;

    // 使用 showMenu 原生组件，它会自动应用 M3 的 Menu 样式（如阴影和高亮）
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items.map((item) {
        return PopupMenuItem<VoidCallback>(
          value: item.onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(
                  item.icon,
                  color: item.isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 12),
              ],
              Text(
                item.title,
                style: TextStyle(
                  color: item.isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((action) {
      // 点击菜单项后执行对应回调
      if (action != null) action();
    });
  }

  static Widget buildAnchor(
    BuildContext context, {
    required List<AdaptiveMenuItem> items,
    String? title,
    IconData icon = Icons.more_vert_rounded,
    double iconSize = 20,
  }) {
    // 使用 Material + InkWell 强制裁剪出标准的 M3 圆形图标触控反馈
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTapDown: (details) {
          show(context, items: items, details: details, title: title);
        },
        onTap: () {}, // 激活水波纹
        customBorder: const CircleBorder(), // 强制水波纹为正圆形
        splashColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(
            10.0,
          ), // 恰到好处的热区：20(Icon) + 10*2 = 40dp 完美的点击块
          child: Icon(
            icon,
            size: iconSize,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
