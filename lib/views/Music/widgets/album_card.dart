import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';

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
    return MediaOverlayCard(
      title: albumName,
      subtitle: '$songCount 首歌曲',
      coverBytes: coverBytes,
      fallbackIcon: Icons.album_rounded,
      onTap: onTap,
    );
  }
}
