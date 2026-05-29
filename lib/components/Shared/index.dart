// import 'dart:io';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

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
    required this.fallbackIcon,
    this.onTap,
    this.badge,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0, // 强制限制为完美的圆角正方形，不随外部拉伸变形
        child: Container(
          clipBehavior: Clip.antiAlias, // 完美裁剪内部层级
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24), // 统一的现代大圆角
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCoverImage(cs),

              // 2. 半透明黑色安全渐变层（防止复杂/亮色封面导致白色文字隐形）
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.6, 0.8, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. 底部文字信息层
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
                      style: const TextStyle(
                        color: Colors.white,
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
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // 4. 右上角可选的 Badge 挂件
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

    // 其次：判断是否存在路径
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

/// M3 蛇形进度条
/// 已播放区域：正弦波曲线；未播放区域：水平直线；thumb：固定在中轴线的圆点。
// ─── 智能动画蛇形进度条组件 (原M3波浪动效) ─────────────────────────────────────────
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
  State<WavySlider> createState() => _M3WavySliderState();
}

class _M3WavySliderState extends State<WavySlider>
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

class ObservableGridCard extends StatefulWidget {
  final int index;
  final Music music;
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
        context.read<MusicProvider>().updateCoverBytes(
          widget.music.id,
          updatedMusic.coverBytes,
        );
        setState(() {
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

    // 角标背景颜色适配
    final badgeBackground = colorScheme.surfaceContainerHigh.withValues(
      alpha: colorScheme.brightness == Brightness.dark ? 0.88 : 0.82,
    );

    return MediaOverlayCard(
      title: widget.music.title,
      subtitle: widget.music.artist,
      coverBytes: widget.music.coverBytes,
      fallbackIcon: Icons.music_note_rounded,
      onTap: widget.onTap,
      isLoading: _isLoading, // 将加载状态传给公共组件，使其自动在没图时渲染菊花图
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBackground,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          borderRadius: BorderRadius.circular(999), // 椭圆胶囊
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

class SongTile extends StatelessWidget {
  final Music music;
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
  final Music music;

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
