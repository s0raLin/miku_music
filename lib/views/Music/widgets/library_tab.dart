import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
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
    return RefreshIndicator(
      onRefresh: () async {},
      child: library.isEmpty
          ? EmptyState(
              icon: Icons.music_note_rounded,
              title: "还没有歌曲",
              subtitle: "点击下方按钮上传歌曲开始使用",
              action: FilledButton.icon(
                onPressed: () => MusicApi.pickAndUploadMusic(),
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
                    context.push("/music-detail", extra: music);
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

  const SongTile({
    super.key,
    required this.music,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: isCurrent ? colorScheme.secondaryContainer : null,
      child: ListTile(
        selected: isCurrent,
        onTap: onTap,
        leading: Container(
          width: 50,
          height: 50,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: music.coverBytes != null && music.coverBytes!.isNotEmpty
              ? Image.memory(music.coverBytes!, fit: BoxFit.cover)
              : Icon(Icons.music_note_rounded, color: colorScheme.primary),
        ),
        title: Text(
          music.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          music.artist,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
