import 'dart:typed_data';

import 'package:flutter/material.dart';

class AlbumCard extends StatelessWidget {
  final String albumName;
  final int songCount;
  final Uint8List? coverBytes;
  final VoidCallback onTap;

  const AlbumCard({
    super.key,
    required this.albumName,
    required this.songCount,
    this.coverBytes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child: coverBytes != null && coverBytes!.isNotEmpty
                      ? Image.memory(coverBytes!, fit: BoxFit.cover)
                      : Icon(
                          Icons.album_rounded,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    albumName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$songCount 首",
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
