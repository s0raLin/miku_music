import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/contants/Assets/index.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: Container(
        color: colorScheme.surface,
        width: 280,
        child: ListTileTheme(
          data: ListTileThemeData(
            selectedTileColor: colorScheme.primaryContainer,
            selectedColor: colorScheme.onPrimaryContainer,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ), // 胶囊形状
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: colorScheme.primaryContainer),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.asset(
                              MyAssets.avatar,
                              width: 60,
                              height: 60,
                            ),
                          ),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "data",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "example@qq.com",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  // context.toSettings();
                  context.push("/settings");
                },
                leading: const Icon(Icons.settings),
                title: const Text("设置"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
