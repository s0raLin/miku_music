import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/NeteaseCloudMusic/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/contants/Assets/index.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/NavProvider/index.dart';
import 'package:provider/provider.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final nav = context.read<NavProvider>();

    final quickCards = [
      _PlaylistQuickCard(
        onTap: () => context.push("/user/playlist/favorites"),
        title: "喜欢",
        icon: Icons.favorite_rounded,
      ),
      _PlaylistQuickCard(
        onTap: () => context.push("/user/recent"),
        title: "最近",
        icon: Icons.history_rounded,
      ),
      _PlaylistQuickCard(
        onTap: () => context.push("/user/files"),
        title: "本地",
        icon: Icons.folder_special_rounded,
      ),
      _PlaylistQuickCard(
        onTap: () => context.push("/user/network"),
        title: "网络",
        icon: Icons.cloud_queue,
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. 沉浸式顶部栏
          SliverAppBar(
            pinned: true,
            title: const Text("个人主页"),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert), // 纵向三个点
                onSelected: (value) {
                  if (value == "edit") {
                    context.push("/user/edit-profile");
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: "share",
                    child: ListTile(
                      leading: Icon(Icons.share_outlined),
                      title: Text('分享'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('编辑'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 2. 用户信息卡片区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _UserCard(
                username: "匿名",
                decoration: "暂无描述",
                onTap: () {
                  context.push("/user/edit-profile");
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 3. 快捷入口
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(title: "我的音乐"),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal, // 设置为横向滚动
                      itemBuilder: (BuildContext context, int index) =>
                          quickCards[index],
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 12.0),
                      itemCount: quickCards.length,

                      // spacing: 12.0,
                      // runSpacing: 12.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // 4. 歌单管理区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionHeader(title: "我的歌单"),
                  const SizedBox(height: 12),
                  // 新建歌单按钮 + 进入音乐库链接
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          await _showCreatePlaylistDialog(context);
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text("新建歌单"),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => nav.jumpByPath("/music"),
                        icon: const Icon(Icons.library_music_rounded, size: 18),
                        label: const Text("音乐库"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 歌单列表
                  Consumer<MusicProvider>(
                    builder: (context, musicProvider, _) {
                      final userPlaylists = musicProvider.userPlaylists;
                      if (userPlaylists.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: AppPanel(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      colorScheme.secondaryContainer,
                                  foregroundColor:
                                      colorScheme.onSecondaryContainer,
                                  child: const Icon(Icons.queue_music_rounded),
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
                        );
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 220, // ← 关键：限制每个卡片最大宽度为 220
                              childAspectRatio: 0.9,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: userPlaylists.length,
                        itemBuilder: (context, index) {
                          final playlist = userPlaylists[index];
                          return _UserPlaylistCard(
                            playlist: playlist,
                            songCount: playlist.songIds.length,
                            onTap: () {
                              context.push("/user/playlist/${playlist.id}");
                            },
                            onMoreTap: () {
                              _showPlaylistOptions(
                                context,
                                playlist,
                                musicProvider,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String username;
  final String decoration;
  final VoidCallback? onTap;
  const _UserCard({
    required this.username,
    required this.decoration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundImage: AssetImage(MyAssets.mikulogo),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            // 让子组件在水平方向上靠起始位置（左侧）对齐
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username),
              const SizedBox(height: 4),
              Text(
                decoration,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis, // 防止描述过长导致换行
              ),
              const SizedBox(height: 4),
              Text("- 关注 | - 粉丝"),
            ],
          ),
        ),
        IconButton(onPressed: onTap, icon: Icon(Icons.chevron_right_rounded)),
      ],
    );
  }
}

// --- 用户播放列表卡（用于网格） ---
class _UserPlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final int songCount;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

  const _UserPlaylistCard({
    required this.playlist,
    required this.songCount,
    required this.onTap,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actionBackground = colorScheme.surfaceContainerHigh.withValues(
      alpha: colorScheme.brightness == Brightness.dark ? 0.9 : 0.82,
    );
    return MediaGridCard(
      title: playlist.name,
      subtitle: "$songCount 首",
      coverBytes: playlist.coverBytes,
      fallbackIcon: Icons.playlist_play_rounded,
      onTap: onTap,
      coverAspectRatio: 1.22,
      titleLines: 1,
      contentSpacing: 4,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      trailing: Material(
        color: actionBackground,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onMoreTap,
          icon: Icon(Icons.more_horiz_rounded, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}

// --- 播放列表管理 ---
Future<void> _showPlaylistOptions(
  BuildContext context,
  Playlist playlist,
  MusicProvider provider,
) async {
  await showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!playlist.isSystem) ...[
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text("重命名"),
              onTap: () {
                Navigator.pop(context);
                _showRenameDialog(context, playlist, provider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outlined),
              title: const Text("删除"),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmDialog(context, playlist, provider);
              },
            ),
          ] else
            ListTile(
              leading: const Icon(Icons.info_outlined),
              title: const Text("系统歌单"),
              onTap: () => Navigator.pop(context),
            ),
        ],
      ),
    ),
  );
}

Future<void> _showRenameDialog(
  BuildContext context,
  Playlist playlist,
  MusicProvider provider,
) async {
  final controller = TextEditingController(text: playlist.name);
  final newName = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("重命名歌单"),
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
          child: const Text("确定"),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (newName != null && newName.isNotEmpty) {
    provider.renamePlaylist(playlist.id, newName);
  }
}

Future<void> _showDeleteConfirmDialog(
  BuildContext context,
  Playlist playlist,
  MusicProvider provider,
) async {
  final mp = context.read<MusicProvider>();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("删除歌单"),
      content: Text("确定要删除「${playlist.name}」吗？"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("取消"),
        ),
        FilledButton(
          onPressed: () {
            mp.deletePlaylist(playlist.id);
            Navigator.pop(context, true);
          },
          child: const Text("删除"),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (confirmed == true) {
    provider.deletePlaylist(playlist.id);
  }
}

Future<void> _showCreatePlaylistDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final uidController = TextEditingController();
  final mp = context.read<MusicProvider>();

  await showDialog(
    context: context,
    builder: (context) => DefaultTabController(
      length: 2,
      child: Builder(
        builder: (tabContext) {
          return AlertDialog(
            title: TabBar(
              tabs: [
                Tab(text: "新建歌单"),
                Tab(text: "网易云导入"),
              ],
            ),
            content: SizedBox(
              width: 120,
              height: 96,
              child: TabBarView(
                children: [
                  Center(
                    child: TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: "歌单名称"),
                    ),
                  ),
                  Center(
                    child: TextField(
                      controller: uidController,
                      decoration: const InputDecoration(
                        hintText: "输入网易云用户id",
                        helperText: "将自动获取该用户公开的歌单",
                        prefixIcon: Icon(Icons.cloud_download),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("取消"),
              ),
              FilledButton(
                onPressed: () {
                  // 根据当前选中的索引判断执行哪种逻辑
                  final tabIndex = DefaultTabController.of(tabContext).index;
                  Navigator.pop(context, {'index': tabIndex});
                },
                child: const Text("确定"),
              ),
            ],
          );
        },
      ),
    ),
  ).then((result) async {
    if (result == null || !context.mounted) return [];

    final provider = context.read<MusicProvider>();
    if (result['index'] == 0) {
      final name = nameController.text.trim();
      if (name.isNotEmpty) provider.createPlaylist(name);
    } else {
      final uid = uidController.text.trim();
      if (uid.isNotEmpty) {
        final playlists = await NeteaseCloudMusicApi.getPlaylist(uid);
        mp.addNetworkPlaylists(playlists);
      }
    }
  });
}

// --- 优化后的快捷入口卡片 ---
class _PlaylistQuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _PlaylistQuickCard({
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      height: 116,
      child: QuickActionCard(title: title, icon: icon, onTap: onTap),
    );
  }
}
