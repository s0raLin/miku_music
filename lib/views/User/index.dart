import 'package:flutter/material.dart';

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

          // 2. 用户信息卡片区域
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: const M3UserCard(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  TabBar.secondary(
                    controller: _tabController,
                    isScrollable: true, //允许自适应宽度
                    tabs: const [
                      Tab(text: "自建歌单"),
                      Tab(text: "收藏歌单"),
                    ],
                  ),
                  SizedBox(
                    height: 140,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        Card(
                          margin: const EdgeInsets.all(16.0),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal, //设置为横向滚动
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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
                        ),
                        Card(
                          margin: const EdgeInsets.all(16.0),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal, //设置为横向滚动
                            itemCount: 10,
                            itemBuilder: (context, index) {
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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

class M3UserCard extends StatelessWidget {
  const M3UserCard({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取 M3 颜色方案
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      // M3 风格：使用 filled 类型
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      color: colorScheme.surfaceContainerHighest, // M3 标准容器颜色
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                // 头像带圆角外框
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(
                      'https://placeholder.com/150',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 用户基本信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "用户名称",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "这里是一段个性签名或简介...",
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // 右侧操作按钮
                FilledButton.tonal(onPressed: () {}, child: const Text("编辑")),
              ],
            ),
            const Divider(height: 32),
            // 底部统计数据
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
          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
