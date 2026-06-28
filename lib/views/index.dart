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

  // 拦截关闭事件
  @override
  void onWindowClose() async {
    await windowManager.hide(); // 隐藏到托盘
  }

  @override
  void dispose() {
    windowManager.removeListener(this); // 清理
    super.dispose();
  }

  // 修复点：移除了多余的 setState(() {});
  // StatefulNavigationShell 的 goBranch 会自行处理分支切换引起的局部或整体通知刷新。
  void onTabChanged(int idx) {
    widget.navigationShell.goBranch(idx);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showNavigationDrawer = MediaQuery.of(context).size.width >= 450;
  }

  bool get _isRootBranch {
    // 当前激活分支的导航器，栈深度为 1 说明在根路由
    return widget.navigationShell.shellRouteContext.navigatorKey.currentState
            ?.canPop() ==
        false;
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
    final hasMusic = mp.currentMusic != null;

    return Scaffold(
      key: rootScaffoldKey,
      drawer: const MainDrawer(),
      body: Row(
        children: [
          SideBar(currentIndex: currentIndex, onTap: onTabChanged),
          const VerticalDivider(thickness: 1, width: 1),

          // 主内容区 — 胶囊悬浮在内容之上
          Expanded(
            child: Stack(
              children: [
                // 内容页，底部留出胶囊高度避免被遮挡
                Positioned.fill(
                  bottom: (!isMiniMode && hasMusic) ? 80 : 0,
                  child: widget.navigationShell,
                ),
                // 悬浮胶囊
                if (!isMiniMode)
                  const Positioned(
                    left: 0, right: 0, bottom: 0,
                    child: NowPlayingBar(),
                  ),
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
    final hasMusic = mp.currentMusic != null;

    final isRoot = _isRootBranch;

    // 计算底部栏完整的设计高度
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomBarHeight =
        kBottomNavigationBarHeight + bottomPadding + 8;

    // 胶囊高度 = 64(胶囊体) + 8(上边距) + 8(下边距) = 80
    const double capsuleHeight = 80.0;

    return Scaffold(
      key: rootScaffoldKey,
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          // 内容页，底部留出胶囊 + 导航栏的空间
          Positioned.fill(
            bottom: (!isMiniMode && hasMusic)
                ? (isRoot
                    ? capsuleHeight + totalBottomBarHeight - bottomPadding
                    : capsuleHeight)
                : 0,
            child: widget.navigationShell,
          ),
          // 悬浮胶囊，紧贴导航栏顶部
          if (!isMiniMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: isRoot ? totalBottomBarHeight - bottomPadding : 0,
              child: const NowPlayingBar(),
            ),
        ],
      ),
      floatingActionButton: isMiniMode ? NowPlayingMiniFab() : null,
      // ── 底部导航栏裁剪收缩动画 ──
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        height: isRoot ? totalBottomBarHeight : 0.0,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.bottomCenter,
            minHeight: totalBottomBarHeight,
            maxHeight: totalBottomBarHeight,
            child: BottomBar(currentIndex: currentIndex, onTap: onTabChanged),
          ),
        ),
      ),
    );
  }
}
