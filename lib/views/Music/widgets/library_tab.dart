import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/Music/widgets/empty_state.dart';
import 'package:provider/provider.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final library = musicProvider.library;

    final currentMusic = context.select<MusicProvider, MusicInfo?>(
      (p) => p.currentMusic,
    );

    return RefreshIndicator(
      onRefresh: () async {},
      child: library.isEmpty
          ? EmptyState(
              icon: Icons.music_note_rounded,
              title: "还没有歌曲",
              subtitle: "点击下方按钮上传歌曲开始使用",
              action: FilledButton.icon(
                onPressed: () async {
                  try {
                    await MusicApi.pickAndUploadMusic();
                    if (context.mounted) {
                      AppToast.success(
                        context,
                        message: '歌曲上传成功',
                        title: '上传完成',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppToast.error(
                        context,
                        message: e.toString().replaceAll('Exception: ', ''),
                        title: '上传失败',
                      );
                    }
                  }
                },
                icon: const Icon(Icons.upload_rounded),
                label: const Text("上传歌曲"),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: library.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final music = library[index];
                return SongTile(
                  music: music,
                  isCurrent: music.id == musicProvider.currentMusic?.id,
                  onTap: () {
                    musicProvider.playFromLibrary(music);
                    context.push("/music-detail");
                  },
                  onPressed: () {

                    if (currentMusic == null || currentMusic.id != music.id) {
                      musicProvider.playFromLibrary(music);

                    } else {
                      musicProvider.togglePlay();
                    }
                  },
                );
              },
            ),
    );
  }
}

// Song list tile
class SongTile extends StatelessWidget {
  final MusicInfo music;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onPressed;

  const SongTile({
    super.key,
    required this.music,
    required this.isCurrent,
    required this.onTap,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );
    return SongListCardTile(
      title: music.title,
      subtitle: music.artist,
      coverBytes: music.coverBytes,
      fallbackIcon: Icons.music_note_rounded,
      onTap: onTap,
      highlighted: isCurrent,
      trailing: FilledButton(
        onPressed: onPressed,
        child: Icon(
          isCurrent & isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
        ),
      ),
    );
  }
}
