import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:myapp/providers/MusicProvider/index.dart';

// ============================================================================
// M3 歌曲列表容器 — 包裹在圆角 Card.filled 内，用 Divider 分隔
// ============================================================================

/// 单个歌曲条目数据
class M3SongEntry {
  final String id;
  final String title;
  final String subtitle;
  final Uint8List? coverBytes;
  final String? coverPath;
  final String? coverUrl;
  final Map<String, String>? coverHeaders;
  final IconData fallbackIcon;
  final bool isHighlighted;
  final bool isNetworkSource;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const M3SongEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    this.coverBytes,
    this.coverPath,
    this.coverUrl,
    this.coverHeaders,
    this.fallbackIcon = Icons.music_note_rounded,
    this.isHighlighted = false,
    this.isNetworkSource = false,
    this.trailing,
    this.onTap,
    this.onDoubleTap,
  });
}

// ============================================================================
// 固定列表版本 (用于普通 Column / Expanded 中)
// ============================================================================

class M3SongList extends StatelessWidget {
  final List<M3SongEntry> songs;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry itemPadding;
  final String? emptyTitle;
  final String? emptySubtitle;
  final MusicProvider? coverLoader;
  final bool isScrollable;

  const M3SongList({
    super.key,
    required this.songs,
    this.padding = const EdgeInsets.all(12),
    this.itemPadding = const EdgeInsets.fromLTRB(10, 5, 4, 5),
    this.emptyTitle,
    this.emptySubtitle,
    this.coverLoader,
    this.isScrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (songs.isEmpty) {
      return Card.filled(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.library_music_outlined,
                  size: 40,
                  color: colorScheme.onSurfaceVariant,
                ),
                if (emptyTitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    emptyTitle!,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
                if (emptySubtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    emptySubtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: !isScrollable,
      physics: isScrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      // 新 API：使用 scrollCacheExtent 替代已弃用的 cacheExtent
      scrollCacheExtent: isScrollable
          ? const ScrollCacheExtent.pixels(800)
          : const ScrollCacheExtent.pixels(250),
      padding: padding,
      itemCount: songs.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 74.0,
        endIndent: itemPadding.resolve(TextDirection.ltr).right + 2,
      ),
      itemBuilder: (context, index) {
        final isFirst = index == 0;
        final isLast = index == songs.length - 1;
        return _M3SongRow(
          entry: songs[index],
          isFirst: isFirst,
          isLast: isLast,
          coverLoader: coverLoader,
          itemPadding: itemPadding,
        );
      },
    );
  }
}

// ============================================================================
// Sliver 列表版本 (用于 CustomScrollView 中)
// ============================================================================

class SliverM3SongList extends StatelessWidget {
  final List<M3SongEntry> songs;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry itemPadding;
  final Widget? emptyWidget;
  final MusicProvider? coverLoader;

  const SliverM3SongList({
    super.key,
    required this.songs,
    this.padding = const EdgeInsets.all(12),
    this.itemPadding = const EdgeInsets.fromLTRB(10, 5, 4, 5),
    this.emptyWidget,
    this.coverLoader,
  });

  @override
  Widget build(BuildContext context) {
    if (songs.isEmpty) {
      if (emptyWidget != null) {
        return SliverToBoxAdapter(child: emptyWidget);
      }
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        // Sliver 的预加载由外层 CustomScrollView 的 scrollCacheExtent 控制
        // 建议在使用处设置：
        // CustomScrollView(scrollCacheExtent: 800, ...)
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return Divider(
              height: 1,
              thickness: 0.5,
              indent: 74.0,
              endIndent: itemPadding.resolve(TextDirection.ltr).right + 2,
            );
          }
          final songIndex = index ~/ 2;
          final isFirst = songIndex == 0;
          final isLast = songIndex == songs.length - 1;
          return _M3SongRow(
            entry: songs[songIndex],
            isFirst: isFirst,
            isLast: isLast,
            coverLoader: coverLoader,
            itemPadding: itemPadding,
          );
        }, childCount: songs.length * 2 - 1),
      ),
    );
  }
}

// ============================================================================
// 单行条目
// ============================================================================

class _M3SongRow extends StatelessWidget {
  final M3SongEntry entry;
  final bool isFirst;
  final bool isLast;
  final MusicProvider? coverLoader;
  final EdgeInsetsGeometry itemPadding;

  const _M3SongRow({
    required this.entry,
    this.isFirst = false,
    this.isLast = false,
    this.coverLoader,
    this.itemPadding = const EdgeInsets.fromLTRB(10, 5, 4, 5),
  });

  static const double _cornerRadius = 16;
  static const double _coverSize = 48;

  BorderRadius _clipRadius() {
    if (isFirst && isLast) return BorderRadius.circular(_cornerRadius);
    if (isFirst) {
      return const BorderRadius.vertical(top: Radius.circular(_cornerRadius));
    }
    if (isLast) {
      return const BorderRadius.vertical(
        bottom: Radius.circular(_cornerRadius),
      );
    }
    return BorderRadius.zero;
  }

  Widget _buildCoverImage(BuildContext context, ColorScheme colorScheme) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (_coverSize * dpr).round().clamp(48, 144);

    // ---------- 本地字节 ----------
    if (entry.coverBytes != null && entry.coverBytes!.isNotEmpty) {
      return Image.memory(
        entry.coverBytes!,
        key: ValueKey('bytes_${entry.id}'),
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true, // 关键：切换时不闪
      );
    }

    // ---------- 本地文件 ----------
    if (entry.coverPath != null && entry.coverPath!.isNotEmpty) {
      final file = File(entry.coverPath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          key: ValueKey('file_${entry.coverPath}'),
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          cacheHeight: cacheSize,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true, // 关键
        );
      }
    }

    // ---------- 网络封面 ----------
    if (entry.coverUrl != null && entry.coverUrl!.isNotEmpty) {
      final Map<String, String> finalHeaders = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        ...?entry.coverHeaders,
      };

      return CachedNetworkImage(
        // 稳定 Key，切换 Tab 时尽量复用 Element
        key: ValueKey(entry.coverUrl),
        imageUrl: entry.coverUrl!,
        cacheKey: entry.coverUrl,
        fit: BoxFit.cover,
        httpHeaders: finalHeaders,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
        // 关键：关掉所有淡入淡出
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholderFadeInDuration: Duration.zero,
        // 关键：url 不变时继续显示旧图，不闪 placeholder
        useOldImageOnUrlChange: true,
        filterQuality: FilterQuality.low,
        placeholder: (context, url) => ColoredBox(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: const SizedBox.expand(),
        ),
        errorWidget: (_, _, _) => _buildFallbackIcon(colorScheme),
      );
    }

    return _buildFallbackIcon(colorScheme);
  }

  Widget _buildFallbackIcon(ColorScheme colorScheme) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        entry.fallbackIcon,
        size: 24,
        color: entry.isHighlighted
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final clipRadius = _clipRadius();

    // 懒加载封面（仅本地音乐需要）
    if ((entry.coverBytes == null || entry.coverBytes!.isEmpty) &&
        entry.coverUrl == null &&
        coverLoader != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!coverLoader!.isCoverLoading(entry.id) &&
            !coverLoader!.hasNoCover(entry.id)) {
          coverLoader!.loadCoverLazy(entry.id);
        }
      });
    }

    const hPadding = 10.0;
    const vPadding = 5.0;
    const rightPadding = 4.0;
    const highlightRadius = BorderRadius.all(Radius.circular(12));

    final effectiveRadius = entry.isHighlighted ? highlightRadius : clipRadius;
    final rowColor = entry.isHighlighted
        ? colorScheme.secondaryContainer
        : Colors.transparent;

    final rowContent = Padding(
      padding: const EdgeInsets.fromLTRB(
        hPadding,
        vPadding,
        rightPadding,
        vPadding,
      ),
      child: Row(
        children: [
          // ---- 封面 / 图标 ----
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: _coverSize,
              height: _coverSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverImage(context, colorScheme),
                  if (entry.isNetworkSource)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.9),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(5),
                          ),
                        ),
                        child: Icon(
                          Icons.cloud_rounded,
                          size: 11,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ---- 标题 + 副标题 ----
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: entry.isHighlighted
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: entry.isHighlighted
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: entry.isHighlighted
                        ? colorScheme.primary.withValues(alpha: 0.7)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // ---- trailing ----
          if (entry.trailing != null) ...[
            const SizedBox(width: 4),
            entry.trailing!,
          ],
        ],
      ),
    );

    return Padding(
      padding: entry.isHighlighted
          ? const EdgeInsets.symmetric(vertical: 2)
          : EdgeInsets.zero,
      child: Material(
        color: rowColor,
        shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: effectiveRadius,
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
          onTap: entry.onTap,
          child: rowContent,
        ),
      ),
    );
  }
}
