import 'package:flutter/material.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart'; 
import 'package:myapp/views/User/PlaylistDetail/index.dart';

class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 PlaylistProvider 的系统常数 ID
    const playlistId = PlaylistProvider.recentPlaylistId;
    return const PlaylistDetailPage(playlistId: playlistId);
  }
}
