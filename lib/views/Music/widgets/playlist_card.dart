// Playlist card (existing)
import 'package:flutter/material.dart';
import 'package:myapp/model/Playlist/index.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final int songCount;
  final VoidCallback onTap;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.songCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 140,
                width: double.infinity,
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                  child:
                      playlist.coverBytes != null &&
                          playlist.coverBytes!.isNotEmpty
                      ? Image.memory(playlist.coverBytes!, fit: BoxFit.cover)
                      : Icon(
                          Icons.playlist_play_rounded,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
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
      ),
    );
  }
}
