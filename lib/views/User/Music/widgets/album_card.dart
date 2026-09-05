import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart'; // 1. 引入 MusicSource

class AlbumCard extends StatelessWidget {
  final String albumName;
  final int songCount;
  final Uint8List? coverBytes;
  final VoidCallback onTap;
  final bool isLoading;
  final MusicSource source; // 2. 新增 source 字段

  const AlbumCard({
    super.key,
    required this.albumName,
    required this.songCount,
    this.coverBytes,
    required this.onTap,
    this.isLoading = false,
    this.source = MusicSource.local, // 3. 默认设为 local 保证向下兼容
  });

  @override
  Widget build(BuildContext context) {
    return MediaOverlayCard(
      title: albumName,
      subtitle: '$songCount 首歌曲',
      source: source, // 4. 透传给 MediaOverlayCard
      coverBytes: coverBytes,
      fallbackIcon: Icons.album_rounded,
      onTap: onTap,
      isLoading: isLoading,
    );
  }
}
