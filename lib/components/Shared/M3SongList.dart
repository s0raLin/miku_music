import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
  final String? emptyTitle;
  final String? emptySubtitle;
  final MusicProvider? coverLoader;
  final bool isScrollable;

  const M3SongList({
    super.key,
    required this.songs,
    this.padding = const EdgeInsets.all(12),
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
      shrinkWrap: isScrollable ? false : true,
      physics: isScrollable
          ? const AlwaysScrollableScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: songs.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1, // 精致紧凑的极细分割线
        thickness: 0.5,
        indent: 74.0, // 对齐：10px padding + 48px 封面 + 16px 间距
        endIndent: 12.0,
      ),
      itemBuilder: (context, index) {
        final isFirst = index == 0;
        final isLast = index == songs.length - 1;
        return _M3SongRow(
          entry: songs[index],
          isFirst: isFirst,
          isLast: isLast,
          coverLoader: coverLoader,
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
  final Widget? emptyWidget;
  final MusicProvider? coverLoader;

  const SliverM3SongList({
    super.key,
    required this.songs,
    this.padding = const EdgeInsets.all(12),
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
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return const Divider(
              height: 1,
              thickness: 0.5,
              indent: 74.0,
              endIndent: 12.0,
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

  const _M3SongRow({
    required this.entry,
    this.isFirst = false,
    this.isLast = false,
    this.coverLoader,
  });

  static const double _cornerRadius = 16;

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

  Widget _buildCoverImage(ColorScheme colorScheme) {
    if (entry.coverBytes != null && entry.coverBytes!.isNotEmpty) {
      return Image.memory(entry.coverBytes!, fit: BoxFit.cover);
    }

    if (entry.coverPath != null && entry.coverPath!.isNotEmpty) {
      final file = File(entry.coverPath!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }

    if (entry.coverUrl != null && entry.coverUrl!.isNotEmpty) {
      final Map<String, String> finalHeaders = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        ...?entry.coverHeaders,
      };

      return CachedNetworkImage(
        imageUrl: entry.coverUrl!,
        fit: BoxFit.cover,
        httpHeaders: finalHeaders,
        placeholder: (context, url) => ColoredBox(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          child: const SizedBox.expand(),
        ),
        errorWidget: (_, __, ___) => _buildFallbackIcon(colorScheme),
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

    // 适配精致比例的尺寸与内边距配置
    const hPadding = 10.0;
    const vPadding = 5.0; // 黄金比例内边距：既不挤压文字，也不拉得太宽
    const highlightRadius = BorderRadius.all(Radius.circular(12));

    final effectiveRadius = entry.isHighlighted ? highlightRadius : clipRadius;
    final rowColor = entry.isHighlighted
        ? colorScheme.secondaryContainer
        : Colors.transparent;

    final rowContent = Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      child: Row(
        children: [
          // ---- 封面 / 图标 ----
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48, // 标准 M3 歌曲封面比例
              height: 48,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverImage(colorScheme),
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
                const SizedBox(height: 2), // 微调间距
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
            const SizedBox(width: 8),
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
