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

    final isRoot = _isRootBranch;

    // 计算底部栏完整的设计高度
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomBarHeight =
        kBottomNavigationBarHeight + bottomPadding;

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

      // ── 2. 完美的底部导航栏裁剪收缩动画 ──
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        // 核心：如果是根路由则为全高，非根路由则必须为 0
        height: isRoot ? totalBottomBarHeight : 0.0,
        child: ClipRect(
          // ClipRect 会把超出当前 Container 高度范围的所有子内容无情裁剪掉
          child: OverflowBox(
            // OverflowBox 允许子组件打破父级的 0 高度限制，强行按照设定的最大高度去渲染
            // 这样 BottomBar 内部就不会因为空间变小而崩溃或者撑开父容器
            alignment: Alignment.topCenter,
            minHeight: totalBottomBarHeight,
            maxHeight: totalBottomBarHeight,
            child: BottomBar(currentIndex: currentIndex, onTap: onTabChanged),
          ),
        ),
      ),
    );
  }
}
