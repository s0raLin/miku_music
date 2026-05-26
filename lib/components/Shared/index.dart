// import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:provider/provider.dart';
// import 'package:fluttertoast/fluttertoast.dart' as ft;

enum MediaGridCardTextLayout { below, overlay }

enum AppToastTone { neutral, success, warning, error }

// ---------------------------------------------------------------------------
// 统一圆角常量 — M3 Shape Scale
// ---------------------------------------------------------------------------
abstract final class AppRadius {
  /// M3 Medium (Card 默认): 默认12 dp
  static const double card = 16;

  /// M3 Small (内嵌图像/头像容器): 默认8 dp
  static const double inner = 16;

  static BorderRadius get cardBR => BorderRadius.circular(card);
  static BorderRadius get innerBR => BorderRadius.circular(inner);
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
    // if (Platform.isAndroid) {
    //   final text = title != null ? '$title: $message' : message;
    //   ft.Fluttertoast.showToast(
    //     msg: text,
    //     toastLength: ft.Toast.LENGTH_SHORT,
    //     gravity: ft.ToastGravity.BOTTOM,
    //     fontSize: 14.0,
    //   );
    //   return;
    // }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

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

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
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
    this.iconSize = 24,
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
      // surfaceContainerHighest 在浅色/深色主题下均提供足够对比
      content = ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            fallbackIcon,
            size: iconSize,
            color: colorScheme.onSurfaceVariant,
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
// MediaGridCard
//
// 背景色统一策略：
//   • below 模式 → Card.filled 默认色（surfaceContainerHigh），无需手动指定。
//   • overlay 模式 → color: Colors.transparent，视觉层次由图片+渐变承担。
//
// 与 SongListCardTile 保持一致：都走 Card.filled 默认色，不再使用
// surfaceContainerLowest（该 Token 在 M3 中为最低层级，用于 Page 背景）。
// ---------------------------------------------------------------------------
class MediaGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Uint8List? coverBytes;
  final Icon fallbackIcon;
  final VoidCallback? onTap;
  final Widget? badge;
  final Widget? trailing;
  final double? width;
  final int titleLines;
  final bool expandArtwork;
  final double? coverAspectRatio;
  final double contentSpacing;
  final EdgeInsetsGeometry? padding;
  final MediaGridCardTextLayout textLayout;
  final int subtitleLines;

  const MediaGridCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.coverBytes,
    required this.fallbackIcon,
    this.onTap,
    this.badge,
    this.trailing,
    this.width,
    this.titleLines = 1,
    this.expandArtwork = false,
    this.coverAspectRatio = 1,
    this.contentSpacing = 8,
    this.padding,
    this.textLayout = MediaGridCardTextLayout.below,
    this.subtitleLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool useOverlay = textLayout == MediaGridCardTextLayout.overlay;

    // overlay 模式：Card 透明，视觉由图片决定；below 模式：走 Card.filled 默认色
    final cardColor = useOverlay ? Colors.transparent : null;

    final titleStyle = theme.textTheme.titleSmall!.copyWith(
      fontWeight: FontWeight.w600,
      color: useOverlay ? Colors.white : colorScheme.onSurface,
    );
    final subtitleStyle = theme.textTheme.bodySmall!.copyWith(
      color: useOverlay ? Colors.white70 : colorScheme.onSurfaceVariant,
    );

    final titleWidget = Text(
      title,
      maxLines: titleLines,
      overflow: TextOverflow.ellipsis,
      style: titleStyle,
    );
    final subtitleWidget = Text(
      subtitle,
      maxLines: subtitleLines,
      overflow: TextOverflow.ellipsis,
      style: subtitleStyle,
    );

    Widget buildArtwork({required bool fillHeight}) => ArtworkCover(
      bytes: coverBytes,
      fallbackIcon: fallbackIcon.icon!,
      iconSize: fallbackIcon.size ?? 24,
      aspectRatio: (fillHeight || expandArtwork) ? null : coverAspectRatio,
      overlay: useOverlay
          ? _GradientOverlay(
              titleWidget: titleWidget,
              subtitleWidget: subtitleWidget,
            )
          : null,
    );

    final cardContent = Card.filled(
      margin: EdgeInsets.zero,
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding:
                  padding ??
                  (useOverlay ? EdgeInsets.zero : const EdgeInsets.all(10)),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final hasBoundedHeight = constraints.maxHeight.isFinite;
                  final artwork = buildArtwork(fillHeight: hasBoundedHeight);

                  if (useOverlay) return artwork;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      hasBoundedHeight ? Expanded(child: artwork) : artwork,
                      SizedBox(height: contentSpacing),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: titleWidget,
                      ),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: subtitleWidget,
                      ),
                    ],
                  );
                },
              ),
            ),
            if (badge != null) Positioned(left: 12, top: 12, child: badge!),
            if (trailing != null)
              Positioned(right: 10, top: 10, child: trailing!),
          ],
        ),
      ),
    );

    return width == null
        ? cardContent
        : SizedBox(width: width, child: cardContent);
  }
}

class _GradientOverlay extends StatelessWidget {
  final Widget titleWidget;
  final Widget subtitleWidget;

  const _GradientOverlay({
    required this.titleWidget,
    required this.subtitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
          stops: const [0.3, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [titleWidget, const SizedBox(height: 4), subtitleWidget],
        ),
      ),
    );
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

// ---------------------------------------------------------------------------
// QuickActionCard
// 图标容器使用 secondaryContainer，与选中态色系统一（primary 留给主操作按钮）。
// ---------------------------------------------------------------------------
class QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;

  const QuickActionCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card.filled(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12), // ↓ 从 14 收紧到 12，减少白边
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标容器：放大到 56×56，图标 28px，视觉存在感更强
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: AppRadius.innerBR,
                ),
                child: SizedBox(
                  width: 46, // ↑ 从 48 → 56
                  height: 46, // ↑ 从 48 → 56
                  child: Icon(
                    icon,
                    color: colorScheme.onSecondaryContainer,
                    size: 24, // ↑ 从 24 → 28，图标更突出
                  ),
                ),
              ),
              const SizedBox(height: 6), // 固定间距替代 Spacer，避免图标贴顶/文字贴底
              Text(
                title,
                textAlign: TextAlign.center, //居中
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700, // 加重到 w700，与 icon 对比更明确
                  fontSize: 12,
                  letterSpacing: -0.1, // 微收字间距，标题更紧实
                  color: colorScheme.onSurface, // 明确用 onSurface，避免跟随默认灰
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3), // ↑ 从 2 → 3，标题与副标题层次更清晰
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
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

/// M3 蛇形进度条
/// 已播放区域：正弦波曲线；未播放区域：水平直线；thumb：固定在中轴线的圆点。
class WavySlider extends StatefulWidget {
  const WavySlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.amplitude = 2.5,
    this.wavelength = 32.0,
    this.strokeWidth = 3.0,
    this.thumbRadius = 7.0,
    this.height = 44.0,
  });

  final double value; // 0.0 ~ 1.0
  final ValueChanged<double> onChanged;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;
  final double amplitude; // 波峰高度 px
  final double wavelength; // 一个完整波形的宽度 px
  final double strokeWidth;
  final double thumbRadius;
  final double height;

  @override
  State<WavySlider> createState() => _WavySliderState();
}

class _WavySliderState extends State<WavySlider> {
  void _handleDrag(double localX, double totalWidth) {
    final v = (localX / totalWidth).clamp(0.0, 1.0);
    widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = widget.activeColor ?? colorScheme.primary;
    final inactiveColor = widget.inactiveColor ?? colorScheme.outlineVariant;
    final thumbColor = widget.thumbColor ?? colorScheme.primary;

    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (d) =>
                _handleDrag(d.localPosition.dx, totalWidth),
            onHorizontalDragUpdate: (d) =>
                _handleDrag(d.localPosition.dx, totalWidth),
            onTapDown: (d) => _handleDrag(d.localPosition.dx, totalWidth),
            child: CustomPaint(
              size: Size(totalWidth, widget.height),
              painter: _WavyPainter(
                value: widget.value,
                activeColor: activeColor,
                inactiveColor: inactiveColor,
                thumbColor: thumbColor,
                amplitude: widget.amplitude,
                wavelength: widget.wavelength,
                strokeWidth: widget.strokeWidth,
                thumbRadius: widget.thumbRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  _WavyPainter({
    required this.value,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.amplitude,
    required this.wavelength,
    required this.strokeWidth,
    required this.thumbRadius,
  });

  final double value;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final double amplitude;
  final double wavelength;
  final double strokeWidth;
  final double thumbRadius;

  double _waveY(double x, double cy, double phaseOffset) {
    return cy +
        math.sin((x + phaseOffset) / wavelength * math.pi * 2) * amplitude;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final splitX = value * size.width;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    // ── 已播放：正弦波 ──
    if (splitX > 0) {
      final path = Path();
      path.moveTo(0, _waveY(0, cy, splitX));
      // 每 1px 采样一次，曲线足够平滑
      for (double x = 1; x <= splitX; x++) {
        path.lineTo(x, _waveY(x, cy, splitX));
      }
      canvas.drawPath(path, activePaint);
    }

    // ── 未播放：水平直线 ──
    if (splitX < size.width) {
      canvas.drawLine(
        Offset(splitX, cy),
        Offset(size.width, cy),
        inactivePaint,
      );
    }

    // ── Thumb：固定在中轴线，盖住接缝 ──
    canvas.drawCircle(Offset(splitX, cy), thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(_WavyPainter old) =>
      old.value != value ||
      old.activeColor != activeColor ||
      old.inactiveColor != inactiveColor ||
      old.thumbColor != thumbColor ||
      old.amplitude != amplitude ||
      old.wavelength != wavelength;
}

class ObservableGridCard extends StatefulWidget {
  final int index;
  final MusicInfo music;
  final VoidCallback? onTap;

  const ObservableGridCard({
    super.key,
    required this.music,
    this.onTap,
    required this.index,
  });

  @override
  State<ObservableGridCard> createState() => _ObservableGridCardState();
}

class _ObservableGridCardState extends State<ObservableGridCard> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('initState: ${widget.music.title}');
    _loadCover();
  }

  void _loadCover() async {
    if (widget.music.coverBytes != null &&
        widget.music.coverBytes!.isNotEmpty) {
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final updatedMusic = await MusicService.parse(widget.music.id);
      if (mounted) {
        setState(() {
          context.read<MusicProvider>().updateCoverBytes(
            widget.music.id,
            updatedMusic.coverBytes,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final badgeBackground = colorScheme.surfaceContainerHigh.withValues(
      alpha: colorScheme.brightness == Brightness.dark ? 0.88 : 0.82,
    );

    return SizedBox(
      width: 156,
      child: MediaGridCard(
        title: widget.music.title,
        subtitle: widget.music.artist,
        coverBytes: widget.music.coverBytes,
        fallbackIcon: Icon(Icons.music_note_rounded, size: 32),
        coverAspectRatio: 1.28,
        titleLines: 1,
        contentSpacing: 2,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        onTap: widget.onTap,
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
      ),
    );
  }
}

class SongTile extends StatelessWidget {
  final MusicInfo music;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onPressed;

  const SongTile({
    super.key,
    required this.music,
    required this.isCurrent,
    required this.onTap,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );
    return SongListCardTile(
      title: music.title,
      subtitle: music.artist,
      coverBytes: music.coverBytes,
      fallbackIcon: Icons.music_note_rounded,
      onTap: onTap,
      highlighted: isCurrent,
      trailing: FilledButton(
        onPressed: onPressed,
        child: Icon(
          isCurrent && isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
        ),
      ),
    );
  }
}

class ObservableMusicListItem extends StatefulWidget {
  final MusicInfo music;

  const ObservableMusicListItem({super.key, required this.music});

  @override
  State<ObservableMusicListItem> createState() =>
      _ObservableMusicListItemState();
}

class _ObservableMusicListItemState extends State<ObservableMusicListItem> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('initState: ${widget.music.title}');
    _loadCover();
  }

  void _loadCover() async {
    if (widget.music.coverBytes != null &&
        widget.music.coverBytes!.isNotEmpty) {
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final updatedMusic = await MusicService.parse(widget.music.id);
      if (mounted) {
        setState(() {
          context.read<MusicProvider>().updateCoverBytes(
            widget.music.id,
            updatedMusic.coverBytes,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();
    final isCurrent = context.select<MusicProvider, bool>(
      (p) => p.currentMusic?.id == widget.music.id,
    );

    return SongTile(
      music: widget.music,
      onTap: () {
        musicProvider.playFromLibrary(widget.music);
        context.push("/music-detail");
      },
      onPressed: () {
        final currentMusic = musicProvider.currentMusic;
        if (currentMusic == null || currentMusic.id != widget.music.id) {
          musicProvider.playFromLibrary(widget.music);
        } else {
          musicProvider.togglePlay();
        }
      },
      isCurrent: isCurrent,
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
}
