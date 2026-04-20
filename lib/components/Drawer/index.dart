import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/contants/Assets/index.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("data"),
            accountEmail: const Text("example@qq.com"),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage(MyAssets.avatar),
            ),
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
