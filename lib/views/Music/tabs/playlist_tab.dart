import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/Music/widgets/playlist_card.dart';
import 'package:provider/provider.dart';

class PlaylistTab extends StatelessWidget {
  const PlaylistTab({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final userPlaylists = musicProvider.userPlaylists;
    final favorites = musicProvider.favoritesPlaylist;

    return RefreshIndicator(
      onRefresh: () async {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favorites != null)
              PlaylistCard(
                playlist: favorites,
                songCount: musicProvider.favList.length,
                onTap: () => context.push("/user/playlist/favorites"),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "我的歌单",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                TextButton.icon(
                  onPressed: () => _showCreatePlaylistDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text("新建"),
                ),
              ],
            ),
            const SizedBox(height: 8),
            userPlaylists.isEmpty
                ? AppEmptyState(
                    icon: Icons.playlist_play_rounded,
                    title: "还没有歌单",
                    subtitle: "创建自己的歌单来整理喜欢的歌曲",
                  )
                : Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: userPlaylists
                        .map(
                          (playlist) => PlaylistCard(
                            playlist: playlist,
                            songCount: playlist.songIds.length,
                            onTap: () =>
                                context.push("/user/playlist/${playlist.id}"),
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("新建歌单"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "歌单名称"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("创建"),
          ),
        ],
      ),
    );

     if (name != null && name.isNotEmpty) {
       if (!context.mounted) return;
       context.read<MusicProvider>().createPlaylist(name);
       if (context.mounted) {
         AppToast.success(
           context,
           message: '歌单「$name」已创建',
           title: '创建成功',
         );
       }
     }
  }
}
