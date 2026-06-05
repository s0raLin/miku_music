import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:provider/provider.dart';

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

class SwitchItem extends DrawerItem {
  const SwitchItem({
    required super.group,
    required super.label,
    required super.icon,
  });
}

// ==================== MainDrawer ====================

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  List<DrawerItem> _buildMenuConfig(bool isLoggedIn) => [
    // 音乐
    NavItem(
      group: '音乐',
      path: '/user/playlist/favorites',
      label: '我的收藏',
      icon: Icons.favorite_border_rounded,
      selectedIcon: Icons.favorite_rounded,
    ),
    NavItem(
      group: '音乐',
      path: '/user/recent',
      label: '最近播放',
      icon: Icons.history_rounded,
      selectedIcon: Icons.history_rounded,
    ),
    NavItem(
      group: '音乐',
      path: '/search',
      label: '查找歌曲',
      icon: Icons.search_rounded,
      selectedIcon: Icons.search_rounded,
    ),

    // 偏好
    SwitchItem(group: '偏好', label: '夜间模式', icon: Icons.dark_mode_outlined),

    // 其他
    NavItem(
      group: '其他',
      path: '/settings',
      label: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
    ),
    NavItem(
      group: '其他',
      path: '/about',
      label: '关于',
      icon: Icons.info_outline_rounded,
      selectedIcon: Icons.info_rounded,
    ),
    if (isLoggedIn)
      NavItem(
        group: '其他',
        path: 'logout',
        label: '退出登录',
        icon: Icons.logout_rounded,
        selectedIcon: Icons.logout_rounded,
        isDestructive: true,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isLoggedIn = userProvider.user != null;

    final menuConfig = _buildMenuConfig(isLoggedIn);
    final navItems = menuConfig.whereType<NavItem>().toList();

    final currentLocation = GoRouterState.of(context).uri.path;
    final selectedIndex = navItems.indexWhere((e) => e.path == currentLocation);

    return NavigationDrawer(
      selectedIndex: selectedIndex >= 0 ? selectedIndex : 0,
      onDestinationSelected: (index) {
        final item = navItems[index];
        Navigator.of(context).pop();
        if (item.path == 'logout') {
          _confirmLogout(context);
        } else {
          context.push(item.path);
        }
      },
      children: [
        // Header
        _DrawerHeader(
          isLoggedIn: isLoggedIn,
          username: userProvider.user?.username,
          email: userProvider.user?.email,
          avatarURL: userProvider.user?.avatarURL,
        ),

        // 分组菜单
        ..._buildGroupedDestinations(
          context,
          menuConfig,
          navItems,
          themeProvider,
        ),
      ],
    );
  }

  List<Widget> _buildGroupedDestinations(
    BuildContext context,
    List<DrawerItem> items,
    List<NavItem> navItems,
    ThemeProvider themeProvider,
  ) {
    final grouped = <String, List<DrawerItem>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.group, () => []).add(item);
    }

    return grouped.entries.expand((entry) {
      final isLastGroup = entry.key == grouped.keys.last;

      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
          child: Text(
            entry.key,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ...entry.value.map((item) {
          if (item is SwitchItem) {
            return _SwitchTile(
              item: item,
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (_) => themeProvider.setThemeMode(
                themeProvider.themeMode == ThemeMode.dark
                    ? ThemeMode.light
                    : ThemeMode.dark,
              ),
            );
          }

          final nav = item as NavItem;
          return NavigationDrawerDestination(
            icon: Icon(nav.icon),
            selectedIcon: Icon(nav.selectedIcon),
            label: Text(nav.label),
          );
        }),
        if (!isLastGroup) const Divider(indent: 28, endIndent: 28),
      ];
    }).toList();
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
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
              ctx.read<UserProvider>().logout();
              Navigator.of(ctx).pop();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

// ====================== Header ======================

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.isLoggedIn,
    this.username,
    this.email,
    this.avatarURL,
  });

  final bool isLoggedIn;
  final String? username;
  final String? email;
  final String? avatarURL;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: !isLoggedIn ? () => context.push('/login') : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
        child: Row(
          children: [
            // 左侧头像
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                backgroundImage: (avatarURL != null && avatarURL!.isNotEmpty)
                    ? NetworkImage(avatarURL!)
                    : null,
                child: (avatarURL == null || avatarURL!.isEmpty)
                    ? Icon(Icons.person_rounded, size: 32)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            // 右侧文字信息（竖直居中，左对齐）
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLoggedIn ? (username ?? '用户') : '游客',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoggedIn ? (email ?? '未设置邮箱') : '还未登录',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================== Switch Tile ======================

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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(item.icon, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
