import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/Music/widgets/album_card.dart';
import 'package:myapp/views/Music/widgets/empty_state.dart';
import 'package:provider/provider.dart';

class AlbumsTab extends StatelessWidget {
  const AlbumsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final library = musicProvider.library;

    // Group songs by album
    final albumsMap = <String, List<MusicInfo>>{};
    for (final song in library) {
      final albumName = song.album ?? "未知专辑";
      albumsMap.putIfAbsent(albumName, () => []).add(song);
    }

    final albums = albumsMap.entries.toList();
    return RefreshIndicator(
      onRefresh: () async {},
      child: albums.isEmpty
          ? EmptyState(
              icon: Icons.album_rounded,
              title: "还没有专辑",
              subtitle: "上传歌曲后会自动归类到专辑",
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: albums.length,
              itemBuilder: (context, index) {
                final entry = albums[index];
                final albumName = entry.key;
                final songs = entry.value;
                final cover = songs
                    .firstWhere(
                      (s) => s.coverBytes != null && s.coverBytes!.isNotEmpty,
                      orElse: () => songs.first,
                    )
                    .coverBytes;
                return AlbumCard(
                  albumName: albumName,
                  songCount: songs.length,
                  coverBytes: cover,
                  onTap: () {
                    context.push(
                      "/user/files/album-detail",
                      extra: {'albumName': albumName, 'songs': songs},
                    );
                  },
                );
              },
            ),
    );
  }
}
