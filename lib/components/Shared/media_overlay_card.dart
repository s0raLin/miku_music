import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/app_radius.dart';

class MediaOverlayCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Uint8List? coverBytes;
  final String? coverPath;
  final String? coverUrl;
  final Map<String, String>? coverHeaders;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final Widget? badge;
  final bool isLoading;

  const MediaOverlayCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.coverBytes,
    this.coverPath,
    this.coverUrl,
    this.coverHeaders,
    required this.fallbackIcon,
    this.onTap,
    this.badge,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bool hasCover =
        (coverBytes != null && coverBytes!.isNotEmpty) ||
        (coverPath != null && coverPath!.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildCoverImage(cs),

              // only show gradient overlay when there is a real cover
              if (hasCover)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),

              // Text layer
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
                      style: TextStyle(
                        color: hasCover ? Colors.white : cs.onSurface,
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
                        color: hasCover
                            ? Colors.white.withValues(alpha: 0.85)
                            : cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              if (badge != null) Positioned(top: 10, right: 10, child: badge!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverImage(ColorScheme cs) {
    // Priority 1: memory bytes
    if (coverBytes != null && coverBytes!.isNotEmpty) {
      return Image.memory(coverBytes!, fit: BoxFit.cover);
    }

    // Priority 2: network URL with CachedNetworkImage
    if (coverUrl != null && coverUrl!.isNotEmpty) {
      final Map<String, String> headers = {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        ...?coverHeaders,
      };
      return CachedNetworkImage(
        imageUrl: coverUrl!,
        fit: BoxFit.cover,
        httpHeaders: headers,
        placeholder: (_, _) => _buildFallback(cs),
        errorWidget: (_, _, _) => _buildFallback(cs),
      );
    }

    // Priority 3: local path
    if (coverPath != null && coverPath!.isNotEmpty) {
      if (coverPath!.startsWith('http://') ||
          coverPath!.startsWith('https://')) {
        return Image.network(
          coverPath!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(cs),
        );
      }
      return Image.file(
        File(coverPath!),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallback(cs),
      );
    }

    // Fallback
    return _buildFallback(cs);
  }

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
