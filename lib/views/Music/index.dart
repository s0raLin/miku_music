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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("音乐库"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "单曲"),
              Tab(text: "专辑"),
              Tab(text: "歌单"),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildLeft(), _buildCenter(), _buildRight()],
        ),
      ),
    );
  }

  Widget _buildLeft() {
    return RefreshIndicator(
      onRefresh: () async {},
      child: const Center(child: Text("单曲列表")),
    );
  }

  Widget _buildCenter() {
    return RefreshIndicator(
      onRefresh: () async {},
      child: const Center(child: Text("专辑列表")),
    );
  }

  Widget _buildRight() {
    final musicProvider = context.watch<MusicProvider>();
    final queue = musicProvider.queue;
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListTileTheme(
        data: ListTileThemeData(
          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: queue.length,
          separatorBuilder: (context, index) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final music = queue[index];
            return Card(
              child: ListTile(
                selected: music.id == musicProvider.currentMusic?.id,
                onTap: () {
                  final musicProvider = context.read<MusicProvider>();
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
                  child: music.coverBytes != null
                      ? Image.memory(music.coverBytes!, fit: BoxFit.cover)
                      : const Icon(Icons.music_note),
                ),
                title: Text(music.title),
                subtitle: Text(music.artist),
                trailing: IconButton(
                  onPressed: () {
                    context.read<MusicProvider>().removeFromQueue(index);
                  },
                  icon: const Icon(Icons.close),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
