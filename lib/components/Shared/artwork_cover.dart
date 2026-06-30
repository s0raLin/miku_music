import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/app_radius.dart';

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
    this.iconSize = 48,
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
      // === 无封面样式 ===
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
