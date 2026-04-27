import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/contants/Assets/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:provider/provider.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.read<UserProvider>();
    final avatarUrl = userProvider.avatar;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("data"),
            accountEmail: const Text("example@qq.com"),
            currentAccountPicture: CircleAvatar(
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : AssetImage(MyAssets.avatar),
            ),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context);
              context.push("/user");
            },
            leading: const Icon(Icons.person),
            title: const Text("用户信息"),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context);
              context.push("/login");
            },
            leading: const Icon(Icons.login),
            title: const Text("登录/注册"),
          ),
          ListTile(
            onTap: () {},
            leading: const Icon(Icons.image_outlined),
            title: const Text("更换背景"),
          ),
          ListTile(
            onTap: () {
              Navigator.pop(context);
              context.push("/settings");
            },
            leading: const Icon(Icons.settings),
            title: const Text("设置"),
          ),
        ],
      ),
    );
  }
}
