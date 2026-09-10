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

  /// NowPlayingBar 总高度 = 上下 Padding(6*2) + Capsule(64)
  static const double _nowPlayingBarHeight = 76.0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void onTabChanged(int idx) {
    widget.navigationShell.goBranch(
      idx,
      initialLocation: idx == widget.navigationShell.currentIndex,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showNavigationDrawer = MediaQuery.of(context).size.width >= 450;
  }

  /// 稳定准确的 Root 路径判断，不再触发帧时序导致的错判抖动
  bool get _isRootBranch {
    final navKey = widget.navigationShell.shellRouteContext.navigatorKey;
    final state = navKey.currentState;
    // 如果 state 还未初始化，默认必然是 Root
    if (state == null) return true;
    return !state.canPop();
  }

  @override
  Widget build(BuildContext context) {
    return showNavigationDrawer
        ? _buildDrawerScaffold(context)
        : _buildBottomBarScaffold(context);
  }

  Widget _buildDrawerScaffold(BuildContext context) {
    final nav = context.watch<NavProvider>();
    final currentIndex =
        nav.shell?.currentIndex ?? widget.navigationShell.currentIndex;
    final mp = context.watch<MusicProvider>();
    final isMiniMode = mp.isMiniMode;
    final bool showBar = !isMiniMode && mp.currentMusic != null;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    // 只加 Bar 自身高度，安全区已在 MediaQuery.padding.bottom 中
    final double contentBottomInset = showBar ? _nowPlayingBarHeight : 0.0;

    return Scaffold(
      key: rootScaffoldKey,
      drawer: const MainDrawer(),
      body: Row(
        children: [
          SideBar(currentIndex: currentIndex, onTap: onTabChanged),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Stack(
              children: [
                MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    padding: MediaQuery.of(context).padding.copyWith(
                      bottom:
                          MediaQuery.of(context).padding.bottom +
                          contentBottomInset,
                    ),
                  ),
                  child: widget.navigationShell,
                ),
                if (showBar)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: bottomPadding,
                    child: const NowPlayingBar(),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: isMiniMode ? const NowPlayingMiniFab() : null,
    );
  }

  Widget _buildBottomBarScaffold(BuildContext context) {
    final mp = context.watch<MusicProvider>();
    final nav = context.watch<NavProvider>();
    final currentIndex =
        nav.shell?.currentIndex ?? widget.navigationShell.currentIndex;
    final isMiniMode = mp.isMiniMode;
    final isRoot = _isRootBranch;
    final bool showBar = !isMiniMode && mp.currentMusic != null;

    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomBarHeight =
        kBottomNavigationBarHeight + bottomPadding + 8;
    // 只加 Bar 自身高度，避免与安全区叠加
    final double contentBottomInset = showBar ? _nowPlayingBarHeight : 0.0;

    return Scaffold(
      key: rootScaffoldKey,
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(
                bottom:
                    MediaQuery.of(context).padding.bottom + contentBottomInset,
              ),
            ),
            child: widget.navigationShell,
          ),
          if (showBar)
            Positioned(
              left: 0,
              right: 0,
              // root：贴 body 底；非 root：抬到安全区上方
              bottom: isRoot ? 0.0 : bottomPadding,
              child: const NowPlayingBar(),
            ),
        ],
      ),
      floatingActionButton: isMiniMode ? const NowPlayingMiniFab() : null,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: isRoot ? totalBottomBarHeight : 0.0,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            height: totalBottomBarHeight,
            child: BottomBar(currentIndex: currentIndex, onTap: onTabChanged),
          ),
        ),
      ),
    );
  }
}
