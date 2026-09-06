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

    return Scaffold(
      key: rootScaffoldKey,
      drawer: const MainDrawer(),
      body: Row(
        children: [
          SideBar(currentIndex: currentIndex, onTap: onTabChanged),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Column(
              children: [
                Expanded(child: widget.navigationShell),
                if (!isMiniMode && mp.currentMusic != null)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
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

    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomBarHeight =
        kBottomNavigationBarHeight + bottomPadding + 8;

    return Scaffold(
      key: rootScaffoldKey,
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Expanded(child: widget.navigationShell),
          if (!isMiniMode && mp.currentMusic != null) ...[
            const NowPlayingBar(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              height: isRoot ? 0.0 : bottomPadding,
            ),
          ],
        ],
      ),
      floatingActionButton: isMiniMode ? const NowPlayingMiniFab() : null,

      // 使用 SingleChildScrollView 防裁剪 + 固化子项 RenderBox 高度，防止高度变动时触发子组件抖动重绘
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
