import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/providers/NavProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';

import 'package:myapp/views/Search/index.dart';
import 'package:myapp/views/SetupWizard/index.dart';
import 'package:myapp/views/User/EditProfile/index.dart';
import 'package:myapp/views/User/Files/index.dart';
import 'package:myapp/views/Home/index.dart';
import 'package:myapp/views/Login/index.dart';
import 'package:myapp/views/User/Files/AlumDetail/index.dart';
import 'package:myapp/views/Music/index.dart';
import 'package:myapp/views/MusicDetail/index.dart';
import 'package:myapp/views/User/Network/index.dart';
import 'package:myapp/views/NotFound/index.dart';
import 'package:myapp/views/Settings/index.dart';
import 'package:myapp/views/Splash/index.dart';
import 'package:myapp/views/EditPlaylist/index.dart';
import 'package:myapp/views/User/PlaylistDetail/Favorites/index.dart';
import 'package:myapp/views/User/PlaylistDetail/index.dart';
import 'package:myapp/views/User/RecentlyPlayed/index.dart';
import 'package:myapp/views/User/index.dart';
import 'package:myapp/views/index.dart';
import 'package:myapp/views/About/index.dart';
import 'package:provider/provider.dart';

class AppNavItem {
  final String name;
  final String path;

  final Widget page;
  final IconData icon;
  final ImageIcon? i;
  final String label;
  final List<RouteBase> routes;

  AppNavItem({
    required this.name,
    required this.path,
    required this.page,
    this.i,
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
    i: ImageIcon(AssetImage(MyAssets.home)),
    icon: Icons.home,
    label: "首页",
  ),
  AppNavItem(
    name: "music",
    path: "/music",
    page: MusicPage(),
    i: ImageIcon(AssetImage(MyAssets.music)),
    icon: Icons.music_note,
    label: "音乐",
  ),
  AppNavItem(
    name: "user",
    path: "/user",
    page: UserProfilePage(),
    i: ImageIcon(AssetImage(MyAssets.user)),
    icon: Icons.person,
    label: "我的",
    routes: [
      GoRoute(
        name: "files",
        path: "/files",
        builder: (context, state) {
          return const FilesPage();
        },
        routes: [
          GoRoute(
            path: "/album-detail",
            builder: (context, state) {
              final data = state.extra as Map<String, dynamic>;
              final String albumName = data['albumName'] as String;

              return AlbumDetailPage(albumName: albumName);
            },
          ),
        ],
      ),
      GoRoute(
        name: "network",
        path: "/network",
        builder: (context, state) => NetWorkPage(),
      ),
      GoRoute(
        name: "recent",
        path: "/recent",
        builder: (context, state) => RecentlyPlayedPage(),
      ),
      GoRoute(
        name: "playlist",
        path: "/playlist",
        routes: [
          GoRoute(
            name: "favorites",
            path: "/favorites",
            builder: (context, state) => const FavoritesPage(),
          ),
          GoRoute(
            path: "/:id",
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return PlaylistDetailPage(playlistId: id);
            },
          ),
        ],
        builder: (context, state) => const MusicPage(),
      ),
      GoRoute(
        name: "edit-profile",
        path: "/edit-profile",
        builder: (context, state) => const EditProfilePage(),
      ),
    ],
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
  GoRoute(path: "/splash", builder: (context, state) => const SplashPage()),
  GoRoute(
    path: "/setup",
    builder: (context, state) => const SetupWizardScreen(),
  ),
  GoRoute(path: "/login", builder: (context, state) => const LoginPage()),
  GoRoute(
    name: "about",
    path: "/about",
    builder: (context, state) => const AboutPage(),
  ),
  GoRoute(path: "/search", builder: (context, state) => const SearchPage()),
  GoRoute(
    path: "/playlist-edit/:id",
    builder: (context, state) {
      final id = state.pathParameters['id'] ?? '';
      return PlaylistEditPage(playlistId: id);
    },
  ),
  GoRoute(
    path: "/music-detail",
    pageBuilder: (context, state) {
      return CustomTransitionPage(
        child: MusicDetailPage(),
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
    builder: (context, state) => SettingsPage(),
  ),
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) {
      // [关键点] 使用 context.read 获取 Provider 并更新 shell
      // 使用 addPostFrameCallback 确保在构建完成后更新状态，避免构建冲突
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<NavProvider>().updateShell(navigationShell);
      });
      return MainPage(navigationShell: navigationShell);
    },
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
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: _router,
        );
      },
    );
  }
}
