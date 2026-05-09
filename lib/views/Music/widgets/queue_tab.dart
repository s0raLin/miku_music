import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:myapp/contants/Assets/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/Music/widgets/empty_state.dart';
import 'package:provider/provider.dart';

class QueueTab extends StatelessWidget {
  const QueueTab({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final queue = musicProvider.queue;

    final isPlaying = musicProvider.player.playing;

    return RefreshIndicator(
      onRefresh: () async {},
      child: queue.isEmpty
          ? EmptyState(
              icon: Icons.queue_music_rounded,
              title: "播放队列为空",
              subtitle: "从歌曲库或歌单中添加歌曲到队列",
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: queue.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final music = queue[index];
                final isCurrent = music.id == musicProvider.currentMusic?.id;

                return Card(
                  color: isCurrent
                      ? Theme.of(context).colorScheme.secondaryContainer
                      : null,
                  child: ListTile(
                    selected: isCurrent,
                    onTap: () {
                      musicProvider.playFromLibrary(music);
                      context.push("/music-detail", extra: music);
                    },
                    leading: Container(
                      width: 50,
                      height: 50,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: isCurrent
                          ? Lottie.asset(MyAssets.equalizer, animate: isPlaying)
                          : music.coverBytes != null
                          ? Image.memory(music.coverBytes!, fit: BoxFit.cover)
                          : const Icon(Icons.music_note_rounded),
                    ),
                    title: Text(
                      music.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isCurrent
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      music.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        context.read<MusicProvider>().removeFromQueue(index);
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
