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
    return MediaOverlayCard(
      title: playlist.name,
      subtitle: "$songCount 首",
      coverPath: playlist.coverPath,
      fallbackIcon: Icons.playlist_play_rounded,
      onTap: onTap,
    );
  }
}
