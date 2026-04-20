import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class AlbumDetailPage extends StatelessWidget {
  final String albumName;
  final List<MusicInfo> songs;
  const AlbumDetailPage({
    super.key,
    required this.albumName,
    required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(albumName)),
      body: ListTileTheme(
        data: ListTileThemeData(
          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final music = songs[index];
            return Card(
              child: ListTile(
                selected: music.id == musicProvider.currentMusic?.id,
                leading: Icon(Icons.music_note),
                title: Text(music.title),
                subtitle: Text(music.artist),
                onTap: () {
                  if (musicProvider.currentMusic?.id != music.id) {
                    musicProvider.replaceQueue(songs, startIndex: index);
                  }
                  context.push("/music-detail", extra: music);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
