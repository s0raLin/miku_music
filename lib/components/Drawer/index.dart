import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final userProvider = context.watch<UserProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isLoggedIn = userProvider.isLoggedIn;
    final currentLocation = GoRouterState.of(context).uri.path;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      backgroundColor: cs.surface,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(isLoggedIn: isLoggedIn, userProvider: userProvider),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _Section(
                    title: '音乐',
                    children: [
                      _DrawerTile(
                        path: '/user/playlist/favorites',
                        label: '我的收藏',
                        icon: Icons.favorite_border_rounded,
                        selectedIcon: Icons.favorite_rounded,
                        isSelected: currentLocation == '/user/playlist/favorites',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/user/playlist/favorites');
                        },
                      ),
                      _DrawerTile(
                        path: '/user/recent',
                        label: '最近播放',
                        icon: Icons.history_rounded,
                        selectedIcon: Icons.history_rounded,
                        isSelected: currentLocation == '/user/recent',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/user/recent');
                        },
                      ),
                      _DrawerTile(
                        path: '/search',
                        label: '查找歌曲',
                        icon: Icons.search_rounded,
                        selectedIcon: Icons.search_rounded,
                        isSelected: currentLocation == '/search',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/search');
                        },
                      ),
                    ],
                  ),
                  _Section(
                    title: '偏好',
                    children: [
                      SwitchListTile(
                        title: const Text('夜间模式'),
                        secondary: Icon(Icons.dark_mode_outlined),
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (_) => themeProvider.setThemeMode(
                          themeProvider.themeMode == ThemeMode.dark
                              ? ThemeMode.light
                              : ThemeMode.dark,
                        ),
                      ),
                    ],
                  ),
                  _Section(
                    title: '其他',
                    children: [
                      _DrawerTile(
                        path: '/settings',
                        label: '设置',
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        isSelected: currentLocation == '/settings',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/settings');
                        },
                      ),
                      _DrawerTile(
                        path: '/about',
                        label: '关于',
                        icon: Icons.info_outline_rounded,
                        selectedIcon: Icons.info_rounded,
                        isSelected: currentLocation == '/about',
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/about');
                        },
                      ),
                      if (isLoggedIn)
                        _DrawerTile(
                          path: 'logout',
                          label: '退出登录',
                          icon: Icons.logout_rounded,
                          selectedIcon: Icons.logout_rounded,
                          isSelected: false,
                          isDestructive: true,
                          onTap: () {
                            Navigator.of(context).pop();
                            _confirmLogout(context);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

class _DrawerHeader extends StatelessWidget {
  final bool isLoggedIn;
  final UserProvider userProvider;

  const _DrawerHeader({
    required this.isLoggedIn,
    required this.userProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: !isLoggedIn ? () => context.push('/login') : null,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                backgroundImage: isLoggedIn &&
                        userProvider.user?.avatarURL != null &&
                        userProvider.user!.avatarURL!.isNotEmpty
                    ? NetworkImage(userProvider.user!.avatarURL!)
                    : null,
                child: (!isLoggedIn ||
                        userProvider.user?.avatarURL == null ||
                        userProvider.user!.avatarURL!.isEmpty)
                    ? Icon(Icons.person_rounded, size: 28)
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLoggedIn ? (userProvider.user?.username ?? '用户') : '游客',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isLoggedIn ? (userProvider.user?.email ?? '未设置邮箱') : '还未登录',
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

class _DrawerTile extends StatelessWidget {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final bool isDestructive;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveIcon = isSelected ? selectedIcon : icon;
    final iconColor = isDestructive
        ? cs.error
        : isSelected
            ? cs.primary
            : cs.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: isSelected
            ? BoxDecoration(
                color: cs.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(28),
              )
            : null,
        child: ListTile(
          dense: true,
          leading: Icon(effectiveIcon, color: iconColor, size: 24),
          title: Text(
            label,
            style: TextStyle(
              color: isDestructive
                  ? cs.error
                  : isSelected
                      ? cs.onSecondaryContainer
                      : cs.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        ...children,
      ],
    );
  }
}
