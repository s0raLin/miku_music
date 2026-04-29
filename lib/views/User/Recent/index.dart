import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                },
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: "清空历史",
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            sliver: history.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 80,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "还没有播放记录",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "去音乐库听听歌曲吧",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                ),
                          ),
                        ],
                      ),
                    ),
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

  void _showContextMenu(BuildContext context, MusicInfo music, MusicProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_circle_outline_rounded),
              title: const Text("播放"),
              onTap: () {
                Navigator.pop(context);
                provider.playFromLibrary(music);
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play_rounded),
              title: const Text("下一首播放"),
              onTap: () {
                Navigator.pop(context);
                provider.addToQueue(music);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("已添加到下一首")),
                );
              },
            ),
            ListTile(
              leading: Icon(
                provider.favList.any((m) => m.id == music.id)
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
              ),
              title: Text(
                provider.favList.any((m) => m.id == music.id)
                    ? "取消收藏"
                    : "收藏",
              ),
              onTap: () {
                Navigator.pop(context);
                provider.toggleFav(music);
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
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          color: colorScheme.surfaceContainerHighest,
          child: coverBytes != null && coverBytes!.isNotEmpty
              ? Image.memory(coverBytes!, fit: BoxFit.cover)
              : Icon(
                  Icons.music_note_rounded,
                  color: colorScheme.primary,
                ),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: onMoreTap != null
          ? IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: onMoreTap,
            )
          : null,
    );
  }
}
