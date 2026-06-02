import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class AlbumDetailPage extends StatelessWidget {
  final String albumName;
  const AlbumDetailPage({
    super.key,
    required this.albumName,
  });

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final songs = mp.library.where((song) {
      final currentAlbum = (song.album ?? '未知专辑').trim();
      final currentArtist = song.artist.trim();
      final folderPath = p.dirname(song.id);

      return currentAlbum == albumName.trim() ||
          currentArtist == albumName.trim() ||
          folderPath == albumName.trim();
    }).toList();

    final colorScheme = Theme.of(context).colorScheme;

    final entries = songs.map((music) {
      final isCurrent = mp.currentMusic?.id == music.id;
      final isPlaying = isCurrent && mp.player.playing;
      return M3SongEntry(
        id: music.id,
        title: music.title,
        subtitle: music.artist,
        coverBytes: music.coverBytes,
        isHighlighted: isCurrent,
        trailing: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(40, 36),
          ),
          onPressed: () {
            if (!isCurrent) {
              mp.playFromLibrary(music);
            } else {
              mp.togglePlay();
            }
          },
          child: Icon(
            isCurrent && isPlaying
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            size: 18,
          ),
        ),
        onTap: () {
          mp.playFromLibrary(music);
          context.push("/music-detail");
        },
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(albumName)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: M3SongList(
          songs: entries,
          emptyTitle: '专辑内无歌曲',
        ),
      ),
    );
  }
}
