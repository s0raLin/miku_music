import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/contants/Assets/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatefulWidget {
  const MainDrawer({super.key});

  @override
  State<MainDrawer> createState() => _MainDrawerState();
}

class Destination {
  final String path;
  final String label;
  final Widget icon;
  final Widget selectedIcon;

  Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}

class _MainDrawerState extends State<MainDrawer> {
  int _screenIndex = 0;
  final _destinations = <Destination>[
    Destination(
      path: "/files",
      label: "选择目录",
      icon: const Icon(Icons.folder),
      selectedIcon: const Icon(Icons.folder),
    ),
    Destination(
      path: "/login",
      label: "登录/注册",
      icon: const Icon(Icons.login),
      selectedIcon: const Icon(Icons.login),
    ),
    Destination(
      path: "/settings",
      label: "设置",
      icon: const Icon(Icons.settings),
      selectedIcon: const Icon(Icons.settings),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final username = userProvider.user?.username ?? "游客";

    final avatarUrl = userProvider.user?.avatarURL;
    final email = userProvider.user?.email ?? "请登录账号";

    return NavigationDrawer(
      selectedIndex: _screenIndex,
      onDestinationSelected: (int idx) {
        _screenIndex = idx;
        context.push(_destinations[idx].path);
        setState(() {});
      },
      children: [
        UserAccountsDrawerHeader(
          accountName: Text(username),
          accountEmail: Text(email),
          currentAccountPicture: CircleAvatar(
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl)
                : AssetImage(MyAssets.avatar),
          ),
        ),
        ..._destinations.map((Destination destination) {
          return NavigationDrawerDestination(
            icon: destination.icon,
            label: Text(destination.label),
            selectedIcon: destination.selectedIcon,
          );
        }),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
      ],
    );
  }
}
