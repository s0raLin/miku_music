import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myapp/providers/UserProvider/index.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class _MainDrawerState extends State<MainDrawer> {
  int _screenIndex = 0;

  @override
  Widget build(BuildContext context) {
    // 核心：watch 确保登录成功后 build 重新运行
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isLoggedIn = user != null;

    final colorScheme = Theme.of(context).colorScheme;

    // 动态生成菜单项
    final List<Map<String, dynamic>> destinations = [
      {
        "path": "/files",
        "label": "选择目录",
        "icon": Icons.folder_outlined,
        "selectedIcon": Icons.folder,
      },
      {
        "path": "/settings",
        "label": "设置",
        "icon": Icons.settings_outlined,
        "selectedIcon": Icons.settings,
      },
      {
        "path": "/about",
        "label": "关于",
        "icon": Icons.info_outline,
        "selectedIcon": Icons.info,
      },
      isLoggedIn
          ? {
              "path": "logout", // 特殊处理
              "label": "退出登录",
              "icon": Icons.logout,
              "selectedIcon": Icons.logout,
            }
          : {
              "path": "/login",
              "label": "登录/注册",
              "icon": Icons.login,
              "selectedIcon": Icons.login,
            },
    ];

    return NavigationDrawer(
      selectedIndex: _screenIndex,
      onDestinationSelected: (int idx) {
        setState(() => _screenIndex = idx);

        final path = destinations[idx]['path'];
        if (path == "logout") {
          userProvider.logout(); // 执行退出逻辑
        } else {
          context.push(path);
        }
      },
      children: [
        // --- M3 风格自定义 Header ---
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 头像
              CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.primary,
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  foregroundColor: colorScheme.onSurfaceVariant,
                  child: const Icon(Icons.person_rounded, size: 34),
                ),
              ),
              const SizedBox(width: 16),
              // 用户名：显式设置颜色为 onSurface 确保可见
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isLoggedIn ? user.username : "游客"),
                  const SizedBox(height: 4),
                  // 邮箱/签名
                  Text(isLoggedIn ? user.email : "请登录账号"),
                ],
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Divider(),
        ),
        // 遍历生成选项
        ...destinations.map(
          (d) => NavigationDrawerDestination(
            icon: Icon(d['icon']),
            selectedIcon: Icon(d['selectedIcon']),
            label: Text(d['label']),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 28),
          child: Divider(),
        ),
      ],
    );
  }
}
