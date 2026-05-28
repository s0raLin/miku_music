import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/NeteaseCloudMusic/index.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/config/globals.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart'; // 👈 引入新的 Provider
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
          Header(
            pinned: true,
            leading: IconButton(
              onPressed: () {
                rootScaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(Icons.menu),
            ),
            title: const Text("个人主页"),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
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
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) =>
                          quickCards[index],
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 10.0),
                      itemCount: quickCards.length,
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

                  // 👈 将绑定的 Provider 切换至 PlaylistProvider
                  Consumer<PlaylistProvider>(
                    builder: (context, playlistProvider, _) {
                      final userPlaylists = playlistProvider.userPlaylists;
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
                              maxCrossAxisExtent: 220,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(username),
              const SizedBox(height: 4),
              Text(
                decoration,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text("- 关注 | - 粉丝"),
            ],
          ),
        ),
        IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _UserPlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final int songCount;
  final VoidCallback onTap;

  const _UserPlaylistCard({
    required this.playlist,
    required this.songCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MediaGridCard(
      title: playlist.name,
      subtitle: "$songCount 首",
      coverBytes: playlist.coverBytes,
      fallbackIcon: const Icon(Icons.playlist_play_rounded, size: 32),
      onTap: onTap,
      coverAspectRatio: 1.22,
      titleLines: 1,
      contentSpacing: 4,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
    );
  }
}

// ─────────────────────────────────────────────
// 对话框及逻辑重构
// ─────────────────────────────────────────────
Future<void> _showCreatePlaylistDialog(BuildContext context) async {
  final nameController = TextEditingController();
  final uidController = TextEditingController();

  // 1. 弹出 Tab 型对话框
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => DefaultTabController(
      length: 2,
      child: Builder(
        builder: (tabContext) {
          return AlertDialog(
            title: const TabBar(
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
  );

  // 2. 异步安全守卫
  if (result == null || !context.mounted) return;

  final playlistProvider = context.read<PlaylistProvider>();

  if (result['index'] == 0) {
    // 创建自建歌单
    final name = nameController.text.trim();
    if (name.isNotEmpty) {
      await playlistProvider.createPlaylist(name);
      if (context.mounted) {
        AppToast.success(context, message: '歌单「$name」已创建', title: '创建成功');
      }
    }
  } else {
    // 网易云歌单导入
    final uid = uidController.text.trim();
    if (uid.isNotEmpty) {
      try {
        // final playlists = await NeteaseCloudMusicApi.getPlaylist(uid);
        // ⚠️ 请确保您在 PlaylistProvider 中实现了 addNetworkPlaylists 方法，
        // 如果目前暂未迁移，可以先在这个方法内通过 playlistUpdates 广播通知或调用批量插入接口。
        // playlistProvider.addNetworkPlaylists(playlists);
      } catch (e) {
        if (context.mounted) {
          AppToast.error(context, message: '导入失败: $e', title: '错误');
        }
      }
    }
  }
}

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 92,
      height: 92,
      child: Card.filled(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12), // ↓ 从 14 收紧到 12，减少白边
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 图标容器：放大到 56×56，图标 28px，视觉存在感更强
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: AppRadius.innerBR,
                  ),
                  child: SizedBox(
                    width: 46, // ↑ 从 48 → 56
                    height: 46, // ↑ 从 48 → 56
                    child: Icon(
                      icon,
                      color: colorScheme.onSecondaryContainer,
                      size: 24, // ↑ 从 24 → 28，图标更突出
                    ),
                  ),
                ),
                const SizedBox(height: 6), // 固定间距替代 Spacer，避免图标贴顶/文字贴底
                Text(
                  title,
                  textAlign: TextAlign.center, //居中
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700, // 加重到 w700，与 icon 对比更明确
                    fontSize: 12,
                    letterSpacing: -0.1, // 微收字间距，标题更紧实
                    color: colorScheme.onSurface, // 明确用 onSurface，避免跟随默认灰
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
