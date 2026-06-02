import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';

class AlbumCard extends StatelessWidget {
  final String albumName;
  final int songCount;
  final Uint8List? coverBytes;
  final VoidCallback onTap;
  final bool isLoading; // 1. 新增：加载状态属性

  const AlbumCard({
    super.key,
    required this.albumName,
    required this.songCount,
    this.coverBytes,
    required this.onTap,
    this.isLoading = false, // 2. 默认为 false，保证向下兼容，不影响其他旧代码
  });

  @override
  Widget build(BuildContext context) {
    return MediaOverlayCard(
      title: albumName,
      subtitle: '$songCount 首歌曲',
      coverBytes: coverBytes,
      fallbackIcon: Icons.album_rounded,
      onTap: onTap,
      isLoading: isLoading, // 3. 完美透传给底层的公共卡片组件
    );
  }
}
