import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/views/Music/widgets/playlist_card.dart';
import 'package:provider/provider.dart';

class PlaylistTab extends StatelessWidget {
  const PlaylistTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. 修正命名：明确这是 PlaylistProvider
    final playlistProvider = context.watch<PlaylistProvider>();
    final userPlaylists = playlistProvider.userPlaylists;

    // 2. 从提供者中通过常量 ID 动态获取“我喜欢”系统歌单
    final favorites = playlistProvider.getPlaylistById(
      PlaylistProvider.favoritesPlaylistId,
    );

    return RefreshIndicator(
      // 3. 补全下拉刷新，联动底层的 Rust 数据库拉取
      onRefresh: () async {
        await playlistProvider.refreshFromDb();
      },
      child: SingleChildScrollView(
        // 让内容不满一屏时也能触发下拉刷新
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favorites != null)
              PlaylistCard(
                playlist: favorites,
                // 歌单自己的 songIds 已经包含了准确的数量，不再和 MusicProvider 耦合
                songCount: favorites.songIds.length,
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
                ? const AppEmptyState(
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

    // 弹出创建对话框
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

    // 4. 严格的异步安全守卫：await 之后必须先检查 context 还在不在
    if (!context.mounted) return;

    if (name != null && name.isNotEmpty) {
      // 5. 正确调用 PlaylistProvider 而不是原来的 MusicProvider
      await context.read<PlaylistProvider>().createPlaylist(name);

      // 再次确认挂载状态后弹出提示
      if (context.mounted) {
        AppToast.success(context, message: '歌单「$name」已创建', title: '创建成功');
      }
    }
  }
}
