import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/views/Files/index.dart';
import 'package:myapp/views/Home/index.dart';
import 'package:myapp/views/Music/index.dart';
import 'package:myapp/views/Settings/index.dart';
import 'package:myapp/views/Splash/index.dart';
import 'package:myapp/views/index.dart';
import 'package:provider/provider.dart';

final _shellBranches = [
  StatefulShellBranch(
    routes: [
      GoRoute(
        name: "home",
        path: "/home",
        builder: (context, state) => HomePage(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        name: "music",
        path: "/music",
        builder: (context, state) => MusicPage(),
      ),
    ],
  ),
  StatefulShellBranch(
    routes: [
      GoRoute(
        name: "files",
        path: "/files",
        builder: (context, state) => FilesPage(),
      ),
    ],
  ),
];

final _routes = [
  GoRoute(path: "/splash", builder: (context, state) => SplashPage()),
  ShellRoute(
    builder: (context, state, child) => MainPage(content: child),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => navigationShell,
        branches: _shellBranches,
      ),
      GoRoute(
        name: "settings",
        path: "/settings",
        builder: (context, state) => SettingsPage(),
      ),
    ],
  ),
];

final _router = GoRouter(initialLocation: "/splash", routes: _routes);

class IndexRouter extends StatelessWidget {
  const IndexRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            theme: themeProvider.themeData,
            themeMode: themeProvider.themeMode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
