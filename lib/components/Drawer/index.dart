import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:provider/provider.dart';

// ── 菜单项数据模型 ──────────────────────────────────────────────────────────

sealed class DrawerItem {
  final String group;
  final String label;
  final IconData icon;

  const DrawerItem({
    required this.group,
    required this.label,
    required this.icon,
  });
}

/// 普通导航跳转项
class NavItem extends DrawerItem {
  final String path;
  final IconData selectedIcon;
  final bool isDestructive;

  const NavItem({
    required super.group,
    required super.label,
    required super.icon,
    required this.path,
    required this.selectedIcon,
    this.isDestructive = false,
  });
}

/// 开关类型的设置项
class SwitchItem extends DrawerItem {
  const SwitchItem({
    required super.group,
    required super.label,
    required super.icon,
  });
}

// ── MainDrawer ──────────────────────────────────────────────────────────────

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  /// 根据当前路由路径计算高亮 index（仅对 NavItem 有效）
  static int _resolveSelectedIndex(
    String currentLocation,
    List<NavItem> navItems,
  ) {
    final idx = navItems.indexWhere((e) => e.path == currentLocation);
    return idx < 0 ? 0 : idx;
  }

  /// 构建菜单配置（依赖登录状态）
  List<DrawerItem> _buildMenuConfig(bool isLoggedIn) => [
    // ── 音乐 ──
    const NavItem(
      group: '音乐',
      path: '/user/playlist/favorites',
      label: '我的收藏',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    const NavItem(
      group: '音乐',
      path: '/user/playlist/recent',
      label: '最近播放',
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_rounded,
    ),
    const NavItem(
      group: '音乐',
      path: '/upload',
      label: '上传歌曲',
      icon: Icons.upload_rounded,
      selectedIcon: Icons.upload_rounded,
    ),

    // ── 偏好 ──
    const SwitchItem(
      group: '偏好',
      label: '夜间模式',
      icon: Icons.dark_mode_outlined,
    ),

    // ── 其他 ──
    const NavItem(
      group: '其他',
      path: '/settings',
      label: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
    const NavItem(
      group: '其他',
      path: '/about',
      label: '关于',
      icon: Icons.info_outline_rounded,
      selectedIcon: Icons.info_rounded,
    ),
    if (isLoggedIn)
      const NavItem(
        group: '其他',
        path: 'logout',
        label: '退出登录',
        icon: Icons.logout_rounded,
        selectedIcon: Icons.logout_rounded,
        isDestructive: true,
      ),
  ];

  void _handleNavItem(BuildContext context, NavItem item) {
    Navigator.of(context).pop(); // 关闭抽屉
    if (item.path == 'logout') {
      _confirmLogout(context);
    } else {
      context.push(item.path);
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<UserProvider>().logout();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isLoggedIn = user != null;

    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    final menuConfig = _buildMenuConfig(isLoggedIn);

    // 只有 NavItem 才注册为 NavigationDrawerDestination，用于 selectedIndex 计算
    final navItems = menuConfig.whereType<NavItem>().toList();
    final currentLocation = GoRouterState.of(context).uri.path;
    final selectedIndex = _resolveSelectedIndex(currentLocation, navItems);

    // 按 group 分组，保持插入顺序
    final Map<String, List<DrawerItem>> groupedMenus = {};
    for (final item in menuConfig) {
      groupedMenus.putIfAbsent(item.group, () => []).add(item);
    }

    // NavigationDrawer 要求 children 中的 NavigationDrawerDestination
    // 必须连续排列才能正确映射 selectedIndex；
    // 将所有 NavItem 平铺到 destinations，非 NavItem 用自定义 widget 替代。
    // 因此这里放弃使用 NavigationDrawer 的内置 selectedIndex，
    // 改为手动给每个 NavigationDrawerDestination 包一层带点击的 InkWell。
    return Drawer(
      child: Column(
        children: [
          // ── Header ──
          _DrawerHeader(
            isLoggedIn: isLoggedIn,
            username: user?.username,
            email: user?.email,
          ),

          // ── 菜单列表 ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                ...groupedMenus.entries.expand((entry) {
                  final groupName = entry.key;
                  final items = entry.value;
                  final isLastGroup = groupName == groupedMenus.keys.last;

                  return [
                    _SectionLabel(groupName),
                    ...items.map((item) {
                      if (item is SwitchItem) {
                        return _SwitchTile(
                          item: item,
                          value: isDark,
                          onChanged: (_) => themeProvider.setThemeMode(
                            isDark ? ThemeMode.light : ThemeMode.dark,
                          ),
                        );
                      }

                      // NavItem
                      final nav = item as NavItem;
                      final isSelected = navItems.indexOf(nav) == selectedIndex;
                      return _NavTile(
                        item: nav,
                        isSelected: isSelected,
                        onTap: () => _handleNavItem(context, nav),
                      );
                    }),
                    if (!isLastGroup) const Divider(indent: 28, endIndent: 28),
                  ];
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 子组件 ──────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.isLoggedIn, this.username, this.email});

  final bool isLoggedIn;
  final String? username;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.primaryContainer,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20, // 安全区适配
        20,
        20,
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(
                  Icons.person_rounded,
                  size: 30,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoggedIn ? username! : '游客',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    isLoggedIn ? email! : '还未登录',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (!isLoggedIn) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login, size: 16),
              label: const Text('登录 / 注册'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 普通导航条目（自绘高亮，避免 NavigationDrawer selectedIndex 混乱）
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = item.isDestructive ? colorScheme.error : null;
    final selectedColor = item.isDestructive
        ? colorScheme.error
        : colorScheme.onSecondaryContainer;
    final bgColor = isSelected && !item.isDestructive
        ? colorScheme.secondaryContainer
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                color: isSelected ? selectedColor : color,
                size: 22,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? selectedColor : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 开关条目
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.item,
    required this.value,
    required this.onChanged,
  });

  final SwitchItem item;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(item.icon, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(item.label, style: const TextStyle(fontSize: 14)),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

/// 分类标题
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
