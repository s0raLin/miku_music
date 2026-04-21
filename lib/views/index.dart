import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/BottomBar/index.dart';
import 'package:myapp/components/Drawer/index.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/NowPlayingBar/index.dart';
import 'package:myapp/components/SideBar/index.dart';

class MainPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({super.key, required this.navigationShell});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void onTabChanged(int idx) {
    widget.navigationShell.goBranch(idx);
  }

  @override
  Widget build(BuildContext context) {
    const maxWidth = 800;
    final colorScheme = Theme.of(context).colorScheme;
    final currentIndex = widget.navigationShell.currentIndex;
    final backgroundColor = colorScheme.surfaceContainerLow;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: const MainDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLargeScreen = constraints.maxWidth >= maxWidth;

          return Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (isLargeScreen) ...[
                      SideBar(currentIndex: currentIndex, onTap: onTabChanged),
                      const VerticalDivider(thickness: 1, width: 1),
                    ],
                    //主内容区
                    Expanded(
                      child: widget.navigationShell,
                      // child: Column(
                      //   children: [
                      //     Header(scaffoldKey: _scaffoldKey),
                      //     Expanded(child: widget.navigationShell),
                      //   ],
                      // ),
                    ),
                  ],
                ),
              ),
              NowPlayingBar(),
            ],
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= maxWidth) {
            return const SizedBox.shrink();
          }
          return BottomBar(currentIndex: currentIndex, onTap: onTabChanged);
        },
      ),
    );
  }
}
