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
    final playlistProvider = context.watch<PlaylistProvider>();
    final userPlaylists = playlistProvider.userPlaylists;

    final favorites = playlistProvider.getPlaylistById(
      PlaylistProvider.favoritesPlaylistId,
    );

    return RefreshIndicator(
      onRefresh: () async {
        await playlistProvider.refreshFromDb();
      },
      child: CustomScrollView(
        // 👈 改为 CustomScrollView，能完美处理网格流与滚动
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 限制“喜欢”系统歌单的尺寸，不再让它无限撑满全宽
                  if (favorites != null) ...[
                    const Text(
                      "系统歌单",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 150, // 🔒 严格限制宽度，“喜欢”卡片会自动变成 150x150
                      child: PlaylistCard(
                        playlist: favorites,
                        songCount: favorites.songIds.length,
                        onTap: () => context.push("/user/playlist/favorites"),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 2. 标题与新建按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "我的歌单",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showCreatePlaylistDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("新建"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. 将原本的 Wrap 替换为响应式的原生 GridView 布局
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: userPlaylists.isEmpty
                ? const SliverToBoxAdapter(
                    child: AppEmptyState(
                      icon: Icons.playlist_play_rounded,
                      title: "还没有歌单",
                      subtitle: "创建自己的歌单来整理喜欢的歌曲",
                    ),
                  )
                : SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180, // 🔒 控制单张卡片的最大宽度，会自动响应式分列
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio:
                              1.0, // 🔒 强制网格分配 1:1 正方形空间，终结无限大和长方形
                        ),
                    itemCount: userPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = userPlaylists[index];
                      return PlaylistCard(
                        playlist: playlist,
                        songCount: playlist.songIds.length,
                        onTap: () =>
                            context.push("/user/playlist/${playlist.id}"),
                      );
                    },
                  ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
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
