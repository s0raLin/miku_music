import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/app_radius.dart';
import 'package:myapp/components/Shared/artwork_cover.dart';

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
