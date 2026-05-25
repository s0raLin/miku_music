import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class AlbumDetailPage extends StatelessWidget {
  final String albumName;
  // final List<MusicInfo> songs;
  const AlbumDetailPage({
    super.key,
    required this.albumName,
    // required this.songs,
  });

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final songs = mp.library.where((song) {
      final currentAlbum = (song.album ?? '未知专辑').trim();
      final currentArtist = song.artist.trim();
      final folderPath = p.dirname(song.id); // 对应歌曲所在的文件夹路径

      return currentAlbum == albumName.trim() ||
          currentArtist == albumName.trim() ||
          folderPath == albumName.trim();
    }).toList();
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
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final music = songs[index];
            return ObservableMusicListItem(music: music);
          },
        ),
      ),
    );
  }
}
