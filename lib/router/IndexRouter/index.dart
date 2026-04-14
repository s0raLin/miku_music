import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/views/Files/index.dart';
import 'package:myapp/views/Home/index.dart';
import 'package:myapp/views/Login/index.dart';
import 'package:myapp/views/Login/register.dart';
import 'package:myapp/views/Music/album_detail.dart';
import 'package:myapp/views/Music/index.dart';
import 'package:myapp/views/Music/music_detail.dart';
import 'package:myapp/views/NotFound/index.dart';
import 'package:myapp/views/Settings/index.dart';
import 'package:myapp/views/Splash/index.dart';
import 'package:myapp/views/index.dart';
import 'package:provider/provider.dart';

class AppNavItem {
  final String name;
  final String path;

  final Widget page;
  final IconData icon;
  final String label;
  final List<RouteBase> routes;

  AppNavItem({
    required this.name,
    required this.path,
    required this.page,
    required this.icon,
    required this.label,
    this.routes = const [],
  });
}

final List<AppNavItem> navItems = [
  AppNavItem(
    name: "home",
    path: "/home",
    page: HomePage(),
    icon: Icons.home,
    label: "首页",
  ),
  AppNavItem(
    name: "music",
    path: "/music",
    page: MusicPage(),
    icon: Icons.music_note,
    label: "音乐",
  ),
  AppNavItem(
    name: "files",
    path: "/files",
    page: FilesPage(),
    icon: Icons.folder,
    label: "文件",
  ),
];

final _shellBranches = navItems.map((item) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        name: item.name,
        path: item.path,
        builder: (context, state) => item.page,
        routes: item.routes,
      ),
    ],
  );
}).toList();

final _routes = [
  GoRoute(path: "/splash", builder: (context, state) => SplashPage()),
  GoRoute(path: "/login", builder: (context, state) => LoginPage()),
  GoRoute(path: "/register", builder: (context, state) => RegisterPage()),
  GoRoute(
    path: "/album-detail",
    builder: (context, state) {
      final data = state.extra as Map<String, dynamic>;
      final String albumName = data['albumName'] as String;
      final List<MusicInfo> songs = data['songs'] as List<MusicInfo>;
      return AlbumDetailPage(albumName: albumName, songs: songs);
    },
  ),
  GoRoute(
    path: "/music-detail",
    pageBuilder: (context, state) {
      final music = state.extra as MusicInfo?;

      return CustomTransitionPage(
        child: MusicDetailPage(music: music),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  // Offset(1, 0) 表示屏幕右侧边缘外
                  // Offset(0, 0) 表示屏幕中心位置
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
                ),
            child: child,
          );
        },
      );
    },
  ),
  GoRoute(
    name: "settings",
    path: "/settings",
    pageBuilder: (context, state) {
      return CustomTransitionPage(
        child: const SettingsPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  // Offset(1, 0) 表示屏幕右侧边缘外
                  // Offset(0, 0) 表示屏幕中心位置
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOutExpo),
                ),
            child: child,
          );
        },
      );
    },
  ),
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        MainPage(navigationShell: navigationShell),
    branches: _shellBranches,
  ),
];

final _router = GoRouter(
  initialLocation: "/splash",
  routes: _routes,
  errorBuilder: (context, state) => const NotFoundPage(),
);

class IndexRouter extends StatelessWidget {
  const IndexRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          theme: themeProvider.themeData,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
