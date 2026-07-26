import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';

class PlaylistListCard extends StatelessWidget {
  final String playlistName;
  final int songCount;
  final Uint8List? coverBytes;
  final String? coverPath;
  final List<Music> recentSongs;
  final bool showSongList;
  final VoidCallback onTap;

  const PlaylistListCard({
    super.key,
    required this.playlistName,
    required this.songCount,
    this.coverBytes,
    this.coverPath,
    this.recentSongs = const [],
    this.showSongList = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 155,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaOverlayCard(
              title: playlistName,
              subtitle: '$songCount 首',
              coverBytes: coverBytes,
              coverPath: coverPath,
              coverUrl: null,
              coverHeaders: null,
              fallbackIcon: Icons.playlist_play_rounded,
              onTap: null,
              isLoading: false,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            const SizedBox(height: 6),
            if (showSongList && recentSongs.isNotEmpty)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: recentSongs.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 8,
                    endIndent: 8,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                  itemBuilder: (context, index) {
                    final song = recentSongs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              )
            else if (showSongList)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  '暂无歌曲',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}