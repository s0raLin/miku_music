import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:myapp/providers/MusicProvider/index.dart';

// ============================================================================
// M3 歌曲列表容器 — 包裹在圆角 Card.filled 内，用 Divider 分隔，紧凑间距
// ============================================================================

/// 单个歌曲条目数据
class M3SongEntry {
  final String id;
  final String title;
  final String subtitle;
  final Uint8List? coverBytes;
  final IconData fallbackIcon;
  final bool isHighlighted;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const M3SongEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    this.coverBytes,
    this.fallbackIcon = Icons.music_note_rounded,
    this.isHighlighted = false,
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

  const M3SongList({
    super.key,
    required this.songs,
    this.padding = const EdgeInsets.all(12),
    this.emptyTitle,
    this.emptySubtitle,
    this.coverLoader,
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
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: songs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
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

    return SliverToBoxAdapter(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: songs.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
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

  static const double _cornerRadius = 16; // 与 AppRadius.card 保持一致

  BorderRadius _clipRadius() {
    if (isFirst && isLast) return BorderRadius.circular(_cornerRadius);
    if (isFirst) return const BorderRadius.vertical(top: Radius.circular(_cornerRadius));
    if (isLast) return const BorderRadius.vertical(bottom: Radius.circular(_cornerRadius));
    return BorderRadius.zero;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final clipRadius = _clipRadius();

    // 封面懒加载：当 coverBytes 为空且提供了 coverLoader 时，触发异步加载
    if ((entry.coverBytes == null || entry.coverBytes!.isEmpty) &&
        coverLoader != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!coverLoader!.isCoverLoading(entry.id) &&
            !coverLoader!.hasNoCover(entry.id)) {
          coverLoader!.loadCoverLazy(entry.id);
        }
      });
    }

    // 选中行使用 secondaryContainer 背景
    final rowColor =
        entry.isHighlighted ? colorScheme.secondaryContainer : Colors.transparent;

    return Material(
      color: rowColor,
      borderRadius: clipRadius,
      child: InkWell(
        borderRadius: clipRadius,
        splashColor: colorScheme.primary.withValues(alpha: 0.12),
        highlightColor: colorScheme.primary.withValues(alpha: 0.08),
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
        onTap: entry.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // ---- 封面 / 图标 ----
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: entry.coverBytes != null && entry.coverBytes!.isNotEmpty
                      ? Image.memory(entry.coverBytes!, fit: BoxFit.cover)
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            entry.fallbackIcon,
                            size: 24,
                            color: entry.isHighlighted
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
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
                        fontWeight:
                            entry.isHighlighted ? FontWeight.w600 : FontWeight.normal,
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
                const SizedBox(width: 8),
                entry.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
