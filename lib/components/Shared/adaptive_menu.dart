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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
                    Navigator.pop(context);
                    item.onTap();
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
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
    final position = details.globalPosition;

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
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTapDown: (details) {
          show(context, items: items, details: details, title: title);
        },
        onTap: () {},
        customBorder: const CircleBorder(),
        splashColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
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
