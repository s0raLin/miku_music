import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/views/Home/index.dart';
import 'package:myapp/views/Music/index.dart';
import 'package:myapp/views/Settings/index.dart';
import 'package:myapp/views/Splash/index.dart';
import 'package:myapp/views/index.dart';
import 'package:provider/provider.dart';

extension RouterCtx on BuildContext {
  void toSettings() => this.go('/settings');
  void toHome() => this.go('/home');
  void toMusic() => this.go('/music');
}

class IndexRouter extends StatefulWidget {
  const IndexRouter({super.key});

  @override
  State<IndexRouter> createState() => _IndexRouterState();
}

class _IndexRouterState extends State<IndexRouter> {
  final router = GoRouter(
    initialLocation: "/splash",
    routes: [
      GoRoute(path: "/splash", builder: (context, state) => SplashPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Provider.value(
            value: navigationShell,
            child: MainPage(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: "home",
                path: "/home",
                builder: (context, state) => HomePage(),
              ),
              GoRoute(
                name: "settings",
                path: "/settings",
                builder: (context, state) => SettingsPage(),
              ),
              GoRoute(
                name: "music",
                path: "/music",
                builder: (context, state) => MusicPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            theme: themeProvider.themeData,
            themeMode: themeProvider.themeMode,
            routerConfig: router,
            builder: (context, child) {
              return Provider.value(value: router, child: child!);
            },
          );
        },
      ),
    );
  }
}
