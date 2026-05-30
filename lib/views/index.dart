import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/BottomBar/index.dart';
import 'package:myapp/components/Drawer/index.dart';
import 'package:myapp/components/NowPlaying/index.dart';
import 'package:myapp/components/SideBar/index.dart';
import 'package:myapp/config/globals.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/NavProvider/index.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

class MainPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({super.key, required this.navigationShell});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WindowListener {
  late bool showNavigationDrawer;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this); // 注册监听
  }

  // 【最关键】拦截关闭事件
  @override
  void onWindowClose() async {
    await windowManager.hide(); // 隐藏到托盘
  }

  @override
  void dispose() {
    windowManager.removeListener(this); // 清理
    super.dispose();
  }

  void onTabChanged(int idx) {
    widget.navigationShell.goBranch(idx);
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showNavigationDrawer = MediaQuery.of(context).size.width >= 450;
  }

  @override
  Widget build(BuildContext context) {
    return showNavigationDrawer
        ? _buildDrawerScaffold(context)
        : _buildBottomBarScaffold(context);
  }

  Widget _buildDrawerScaffold(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final currentIndex = nav.shell?.currentIndex ?? 0;
    final mp = context.watch<MusicProvider>();
    final isMiniMode = mp.isMiniMode;
    return Scaffold(
      key: rootScaffoldKey,
      drawer: const MainDrawer(),

      body: Row(
        children: [
          SideBar(currentIndex: currentIndex, onTap: onTabChanged),
          const VerticalDivider(thickness: 1, width: 1),

          //主内容区
          Expanded(
            child: Column(
              children: [
                Expanded(child: widget.navigationShell),
                if (!isMiniMode) NowPlayingBar(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isMiniMode ? NowPlayingMiniFab() : null,
    );
  }

  Widget _buildBottomBarScaffold(BuildContext context) {
    final mp = context.watch<MusicProvider>();
    final nav = context.watch<NavProvider>();
    final currentIndex = nav.shell?.currentIndex ?? 0;
    final isMiniMode = mp.isMiniMode;
    return Scaffold(
      key: rootScaffoldKey,
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Expanded(child: widget.navigationShell),
          if (!isMiniMode) NowPlayingBar(),
        ],
      ),
      floatingActionButton: isMiniMode ? NowPlayingMiniFab() : null,
      bottomNavigationBar: BottomBar(
        currentIndex: currentIndex,
        onTap: onTabChanged,
      ),
    );
  }
}
