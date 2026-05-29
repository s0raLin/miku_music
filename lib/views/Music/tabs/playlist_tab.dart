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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final playlistProvider = context.watch<PlaylistProvider>();
    final userPlaylists = playlistProvider.userPlaylists;

    // 获取“喜欢”系统歌单
    final favorites = playlistProvider.getPlaylistById(
      PlaylistProvider.favoritesPlaylistId,
    );

    // 抽离统一的网格代理配置，确保上下卡片的自适应尺寸和 1:1 比例绝对像素级一致
    const gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 140, // 统一限定卡片最大宽度
      mainAxisSpacing: 12, // 行间距
      crossAxisSpacing: 12, // 列间距
      childAspectRatio: 1.0, // 🔒 强制 1:1 正方形比例
    );

    return RefreshIndicator(
      onRefresh: () async {
        await playlistProvider.refreshFromDb();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ================= 1. 系统歌单标题 =================
          if (favorites != null)
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(
                  "系统歌单",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // ================= 2. 系统歌单网格 =================
          // 用只包含 1 个元素的 SliverGrid 承载，使其完美继承网格的尺寸计算公式
          if (favorites != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverGrid(
                gridDelegate: gridDelegate,
                delegate: SliverChildBuilderDelegate((context, index) {
                  return PlaylistCard(
                    playlist: favorites,
                    songCount: favorites.songIds.length,
                    onTap: () => context.push("/user/playlist/favorites"),
                  );
                }, childCount: 1),
              ),
            ),

          // ================= 3. 我的歌单标题与新建按钮 =================
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Row(
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
            ),
          ),

          // ================= 4. 我的歌单列表网格 =================
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            sliver: userPlaylists.isEmpty
                ? SliverToBoxAdapter(
                    child: AppPanel(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: colorScheme.secondaryContainer,
                            foregroundColor: colorScheme.onSecondaryContainer,
                            child: const Icon(Icons.history_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "还没有创建歌单\n点击上方「新建歌单」按钮创建",
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverGrid.builder(
                    gridDelegate: gridDelegate,
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

          // 底部留白，防止滚动被底部导航栏或播放条遮挡
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  /// 弹出创建新歌单的对话框
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

    // 🔒 异步安全守卫：确保 context 在弹窗关闭后依然挂载有效
    if (!context.mounted) return;

    if (name != null && name.isNotEmpty) {
      // 调用歌单状态管理器创建新歌单
      await context.read<PlaylistProvider>().createPlaylist(name);

      // 再次确认挂载状态，安全弹出 Toast 提示
      if (context.mounted) {
        AppToast.success(context, message: '歌单「$name」已创建', title: '创建成功');
      }
    }
  }
}
