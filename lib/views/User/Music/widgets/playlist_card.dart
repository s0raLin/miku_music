import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/model/Playlist/index.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final int songCount;
  final VoidCallback onTap;
  final MusicSource source; // 2. 新增 source 字段

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.songCount,
    required this.onTap,
    this.source = MusicSource.local, // 3. 默认设为 local 保证向下兼容
  });

  @override
  Widget build(BuildContext context) {
    return MediaOverlayCard(
      title: playlist.name,
      subtitle: "$songCount 首",
      coverPath: playlist.coverPath,
      fallbackIcon: Icons.playlist_play_rounded,
      onTap: onTap,
      source: source,
    );
  }
}
