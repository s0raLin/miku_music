import 'package:flutter/material.dart';

class AdaptiveMenuItem {
  final IconData? icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const AdaptiveMenuItem({
    required this.title,
    required this.onTap,
    this.icon,
    this.isDestructive = false,
  });
}

class AdaptiveMenu {
  /// Show adaptive menu — bottom sheet on mobile, popup on desktop
  static void show(
    BuildContext context, {
    required List<AdaptiveMenuItem> items,
    required TapDownDetails details,
    String? title,
  }) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    if (isCompact) {
      _showBottomSheet(context, items, title);
    } else {
      _showPopupMenu(context, items, details);
    }
  }

  /// 1. Mobile: Material 3 bottom sheet
  static void _showBottomSheet(
    BuildContext context,
    List<AdaptiveMenuItem> items,
    String? title,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: cs.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                    child: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ...items.map((item) {
                  final color = item.isDestructive ? cs.error : cs.onSurface;
                  final iconColor = item.isDestructive
                      ? cs.error
                      : cs.onSurfaceVariant;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 2,
                    ),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      leading: item.icon != null
                          ? Icon(item.icon, color: iconColor, size: 22)
                          : null,
                      title: Text(
                        item.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        item.onTap();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 2. Desktop: Material 3 popup menu
  static void _showPopupMenu(
    BuildContext context,
    List<AdaptiveMenuItem> items,
    TapDownDetails details,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final position = details.globalPosition;

    showMenu<VoidCallback>(
      context: context,
      elevation: 6,
      shadowColor: cs.shadow.withValues(alpha: 0.2),
      surfaceTintColor: cs.surfaceTint,
      color: cs.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items.map((item) {
        final color = item.isDestructive ? cs.error : cs.onSurface;
        final iconColor = item.isDestructive ? cs.error : cs.onSurfaceVariant;

        return PopupMenuItem<VoidCallback>(
          value: item.onTap,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.icon != null) ...[
                Icon(item.icon, color: iconColor, size: 18),
                const SizedBox(width: 12),
              ],
              Text(
                item.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((action) {
      if (action != null) action();
    });
  }

  /// 3. Anchor widget using Builder & RenderBox to accurately track click position
  static Widget buildAnchor(
    BuildContext context, {
    required List<AdaptiveMenuItem> items,
    String? title,
    IconData icon = Icons.more_vert_rounded,
    double iconSize = 20,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Builder(
      builder: (btnContext) {
        return IconButton(
          icon: Icon(icon, size: iconSize),
          color: cs.onSurfaceVariant,
          tooltip: title ?? "更多选项",
          style: IconButton.styleFrom(
            hoverColor: cs.onSurfaceVariant.withValues(alpha: 0.08),
            highlightColor: cs.onSurfaceVariant.withValues(alpha: 0.12),
          ),
          onPressed: () {
            final renderBox = btnContext.findRenderObject() as RenderBox?;
            final offset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
            final size = renderBox?.size ?? Size.zero;

            show(
              btnContext,
              items: items,
              details: TapDownDetails(
                globalPosition: Offset(
                  offset.dx + size.width / 2,
                  offset.dy + size.height / 2,
                ),
              ),
              title: title,
            );
          },
        );
      },
    );
  }
}
