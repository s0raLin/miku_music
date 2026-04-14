import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final queue = musicProvider.queue;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListTileTheme(
        data: ListTileThemeData(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          iconColor: colorScheme.primary,
          textColor: colorScheme.onSurface,

          tileColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), //外轮廓
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(12), // 列表整体内边距
          itemCount: queue.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final music = queue[index];
            return ListTile(
              // 这里的 ListTile 会自动继承上方 ListTileTheme 的样式
              onTap: () {
                final musicProvider = context.read<MusicProvider>();
                musicProvider.playFromLibrary(music);
                context.push("/music-detail", extra: music);
              },
              leading: Container(
                width: 50,
                height: 50,
                clipBehavior: Clip.antiAlias, //抗锯齿
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: music.coverBytes != null
                    ? Image.memory(music.coverBytes!, fit: BoxFit.cover)
                    : const Icon(Icons.music_note),
              ),
              title: Text(music.title),
              subtitle: Text(music.artist),
              trailing: IconButton(
                onPressed: () {
                  context.read<MusicProvider>().remoteFromQueue(index);
                },
                icon: Icon(Icons.close),
              ),
            );
          },
        ),
      ),
    );
  }
}
