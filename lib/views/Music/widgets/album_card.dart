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
    return MediaGridCard(
      title: albumName,
      subtitle: "$songCount 首",
      coverBytes: coverBytes,
      fallbackIcon: Icon(Icons.album_rounded, size: 32),
      onTap: onTap,
      coverAspectRatio: 1.22,
      titleLines: 1,
      contentSpacing: 4,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
    );
  }
}
