import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/song_list_card_tile.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class ObservableMusicListItem extends StatelessWidget {
  final Music music;

  const ObservableMusicListItem({super.key, required this.music});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();

    final isCurrent = context.select<MusicProvider, bool>(
      (p) => p.currentMusic?.id == music.id,
    );

    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );

    // Reactive lazy cover loading
    if (music.coverBytes == null || music.coverBytes!.isEmpty) {
      musicProvider.loadCoverLazy(music.id);
    }

    return SongListCardTile(
      title: music.title,
      subtitle: music.artist,
      coverBytes: music.coverBytes,
      fallbackIcon: Icons.music_note_rounded,
      highlighted: isCurrent,
      onTap: () {
        musicProvider.playFromLibrary(music);
        context.push("/music-detail");
      },
      trailing: FilledButton.tonal(
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () {
          if (!isCurrent) {
            musicProvider.playFromLibrary(music);
          } else {
            musicProvider.togglePlay();
          }
        },
        child: Icon(
          isCurrent && isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
          size: 20,
        ),
      ),
    );
  }
}
