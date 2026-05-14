import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final history = musicProvider.history;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text("最近播放"),
            actions: [
               IconButton(
                 onPressed: () {
                   musicProvider.clearHistory();
                   AppToast.neutral(
                     context,
                     message: '播放历史已清空',
                   );
                 },
                 icon: const Icon(Icons.delete_sweep_outlined),
                 tooltip: "清空历史",
               ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            sliver: history.isEmpty
                ? const AppEmptySliver(
                    icon: Icons.history_rounded,
                    title: "还没有播放记录",
                    subtitle: "去音乐库听听歌曲吧",
                  )
                : SliverList.builder(
                    itemCount: history.length,
                    itemBuilder: (BuildContext context, int index) {
                      final music = history[index];
                      return _MusicListTile(
                        title: music.title,
                        subtitle: "${music.artist} - ${music.album}",
                        coverBytes: music.coverBytes,
                        onTap: () {
                          musicProvider.playFromLibrary(music);
                          context.push("/music-detail", extra: music);
                        },
                        onMoreTap: () {
                          _showContextMenu(context, music, musicProvider);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(
    BuildContext context,
    MusicInfo music,
    MusicProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
               ListTile(
                 leading: Icon(
                   provider.favList.any((m) => m.id == music.id)
                       ? Icons.favorite_rounded
                       : Icons.favorite_border_rounded,
                 ),
                 title: Text(
                   provider.favList.any((m) => m.id == music.id) ? "取消收藏" : "收藏",
                 ),
                 onTap: () {
                   Navigator.pop(context);
                   provider.toggleFav(music);
                   final isFav = provider.favList.any((m) => m.id == music.id);
                   AppToast.neutral(
                     context,
                     message: isFav ? '已添加到喜欢' : '已取消收藏',
                   );
                 },
               ),
            ListTile(
              leading: const Icon(Icons.playlist_play_rounded),
              title: const Text("下一首播放"),
              onTap: () {
                Navigator.pop(context);
                provider.addToQueue(music);
                AppToast.success(context, title: "已加入队列", message: "已添加到下一首");
              },
            ),
               ListTile(
                 leading: Icon(
                   provider.favList.any((m) => m.id == music.id)
                       ? Icons.favorite_rounded
                       : Icons.favorite_border_rounded,
                 ),
                 title: Text(
                   provider.favList.any((m) => m.id == music.id) ? "取消收藏" : "收藏",
                 ),
                 onTap: () {
                   Navigator.pop(context);
                   provider.toggleFav(music);
                   final isFav = provider.favList.any((m) => m.id == music.id);
                   AppToast.neutral(
                     context,
                     message: isFav ? '已添加到喜欢' : '已取消收藏',
                   );
                 },
               ),
          ],
        ),
      ),
    );
  }
}

class _MusicListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Uint8List? coverBytes;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const _MusicListTile({
    required this.title,
    required this.subtitle,
    this.coverBytes,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return SongListCardTile(
      title: title,
      subtitle: subtitle,
      coverBytes: coverBytes,
      fallbackIcon: Icons.music_note_rounded,
      onTap: onTap,
      trailing: onMoreTap != null
          ? IconButton(
              icon: const Icon(Icons.more_horiz_rounded),
              onPressed: onMoreTap,
            )
          : null,
    );
  }
}
