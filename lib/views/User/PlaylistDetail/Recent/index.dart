import 'package:flutter/material.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/User/PlaylistDetail/index.dart';
import 'package:provider/provider.dart';

class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final playlistId = context.read<MusicProvider>().recentPlaylistId;
    return PlaylistDetailPage(playlistId: playlistId);
  }
}
