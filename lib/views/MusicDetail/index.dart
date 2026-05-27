import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/views/MusicDetail/layout/narrow_layout.dart';
import 'package:myapp/views/MusicDetail/layout/wide_layout.dart';

import 'package:provider/provider.dart';

// ─── 主页面 ───────────────────────────────────────────────────────────────────

class MusicDetailPage extends StatefulWidget {
  const MusicDetailPage({super.key});

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    final music = context.select<MusicProvider, Music?>((p) => p.currentMusic);

    if (music == null) {
      return AppEmptyState(
        icon: Icons.music_note_rounded,
        title: "未选择歌曲",
        subtitle: "请选择歌曲再试",
      );
    }

    final isLiked = playlistProvider
        .getPlaylistSongs(
          PlaylistProvider.favoritesPlaylistId,
          musicProvider.library,
        )
        .any((m) => m.id == music.id);
    final isWide = MediaQuery.sizeOf(context).width > 700;

    return isWide
        ? WideLayout(music: music, isLiked: isLiked)
        : NarrowLayout(music: music, isLiked: isLiked);
  }
}
