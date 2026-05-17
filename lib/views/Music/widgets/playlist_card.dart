// Playlist card (existing)
import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
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
    return MediaGridCard(
      width: 160,
      title: playlist.name,
      subtitle: "$songCount 首",
      coverBytes: playlist.coverBytes,
      fallbackIcon: Icon(Icons.playlist_play_rounded, size: 32),
      onTap: onTap,
      coverAspectRatio: 1.22,
      titleLines: 1,
      contentSpacing: 4,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
    );
  }
}
