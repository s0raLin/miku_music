import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart' as ft;

enum MediaGridCardTextLayout { below, overlay }

enum AppToastTone { neutral, success, warning, error }

// ---------------------------------------------------------------------------
// 统一圆角常量 (严格符合 Material 3 的 Token 体系)
// ---------------------------------------------------------------------------
abstract final class AppRadius {
  static const double card = 16; // M3 Medium Card 默认圆角 Token
  static const double inner = 16; // M3 Small Shape Token (内部图像/容器)
  static const double tile = 16; // M3 Large Shape Token (列表项外廓)

  static BorderRadius get cardBR => BorderRadius.circular(card);
  static BorderRadius get innerBR => BorderRadius.circular(inner);
  static BorderRadius get tileBR => BorderRadius.circular(tile);
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
    if (Platform.isAndroid) {
      final text = title != null ? '$title: $message' : message;
      ft.Fluttertoast.showToast(
        msg: text,
        toastLength: ft.Toast.LENGTH_SHORT,
        gravity: ft.ToastGravity.BOTTOM,
        fontSize: 14.0,
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final colorScheme = Theme.of(context).colorScheme;
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
// AppPanel (已移除 Border 属性)
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
    final colorScheme = Theme.of(context).colorScheme;
    final br = borderRadius ?? AppRadius.cardBR;

    return Container(
      decoration: BoxDecoration(
        color: color ?? colorScheme.surfaceContainerLow,
        borderRadius: br,
        // 【已修改】移除了 Border.all 以去除边框线
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            Padding(padding: padding ?? const EdgeInsets.all(12), child: child),
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ArtworkCover
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
// MediaGridCard (已移除 Container 中的 Border 属性，并修正了 Overlay 模式下的文本颜色)
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
  final EdgeInsetsGeometry padding;
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
    this.padding = const EdgeInsets.all(10),
    this.textLayout = MediaGridCardTextLayout.below,
    this.subtitleLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bool useOverlay = textLayout == MediaGridCardTextLayout.overlay;

    // 【修正说明】原 scrim 底色上使用 scrim 颜色文字会导致看不见，这里将其纠正为在阴影遮罩上使用高亮白色/浅色
    TextStyle titleStyle = (theme.textTheme.titleSmall ?? const TextStyle())
        .copyWith(
          fontWeight: FontWeight.w600,
          color: useOverlay ? Colors.white : colorScheme.onSurface,
        );

    TextStyle subtitleStyle = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(
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

    Widget buildArtwork({required bool fillHeight}) {
      return ArtworkCover(
        bytes: coverBytes,
        fallbackIcon: fallbackIcon.icon!,
        iconSize: fallbackIcon.size!,
        aspectRatio: (fillHeight || expandArtwork) ? null : coverAspectRatio,
        overlay: useOverlay
            ? _GradientOverlay(
                titleWidget: titleWidget,
                subtitleWidget: subtitleWidget,
              )
            : null,
      );
    }

    final br = AppRadius.cardBR;
    final cardContent = Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: br,
        // 【已修改】移除了 Border.all 移除边框线
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            Padding(
              padding: padding,
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
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap),
                ),
              ),
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
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black54, // 【已修改】使用黑半透明遮罩以确保图片上的文本可读性
          ],
          stops: [0.4, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // 组件上移，不在这里重复声明
          ],
        ),
      ),
    );
  }

  Widget buildWithChildren(BuildContext context, List<Widget> children) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black54],
          stops: [0.4, 1.0],
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
// SongListCardTile (已移除 Container 中的 Border 属性)
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

    final tileColor = highlighted
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerLowest;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: AppRadius.tileBR,
        // 【已修改】移除了 Border.all 属性以隐藏默认以及高亮状态下的物理边框
      ),
      child: ClipRRect(
        borderRadius: AppRadius.tileBR,
        child: Stack(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
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
            if (onTap != null)
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: onTap),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// QuickActionCard
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

    return AppPanel(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: AppRadius.innerBR,
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
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
