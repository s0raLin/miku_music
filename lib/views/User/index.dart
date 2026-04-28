import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. 沉浸式顶部栏
          SliverAppBar(
            title: const Text("个人主页"),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 2. 用户信息卡片区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const M3UserCard(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 12.0,
                runSpacing: 12.0,
                children: [
                  _PlaylistQuickCard(
                    onTap: () {},
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
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  TabBar(
                    tabAlignment: TabAlignment.start,
                    controller: _tabController,
                    isScrollable: true, //允许自适应宽度
                    tabs: const [
                      Tab(text: "自建歌单"),
                      Tab(text: "收藏歌单"),
                    ],
                  ),
                  SizedBox(
                    height: 100,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ListView.builder(
                          scrollDirection: Axis.horizontal, //设置为横向滚动
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(child: Text("111")),
                            );
                          },
                        ),
                        ListView.builder(
                          scrollDirection: Axis.horizontal, //设置为横向滚动
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(child: Text("222")),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 底部留白
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// --- 优化后的用户信息卡片 ---
class M3UserCard extends StatelessWidget {
  const M3UserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      // 使用 secondaryContainer 让背景色更出挑，或者使用 surfaceContainerHighest 保持稳重
      color: colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // 增加圆角更具 M3 感
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                // 头像
                CircleAvatar(
                  radius: 36,
                  backgroundColor: colorScheme.primary,
                  child: const CircleAvatar(
                    radius: 34,
                    backgroundImage: NetworkImage(
                      'https://placeholder.com/150',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "苍璃 s0raLin",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Coding with Music & Arch Linux",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: const Text("编辑"),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: colorScheme.outlineVariant),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem("动态", "128", colorScheme),
                _buildStatItem("关注", "1.2k", colorScheme),
                _buildStatItem("粉丝", "8.5k", colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSecondaryContainer.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

// --- 优化后的快捷入口卡片 ---
class _PlaylistQuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Uint8List? coverBytes;
  final VoidCallback? onTap;
  // 增加一个枚举或索引来决定使用哪种主题色，或者统一使用 primary

  const _PlaylistQuickCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    this.coverBytes,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 统一使用主题色：如果没有传 customColor，则默认使用 primary
    // 也可以这里固定使用 colorScheme.primary
    final activeColor = colorScheme.secondaryContainer;

    return SizedBox(
      width: 105,
      child: Card.filled(
        // 背景使用极其清淡的主题色，保持 M3 的通透感
        color: activeColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                  child: coverBytes != null && coverBytes!.isNotEmpty
                      ? Image.memory(coverBytes!)
                      : Icon(icon),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface, // 使用通用的文字颜色
                    fontSize: 13,
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
