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

  // _stableIsRoot 延迟一帧更新，防止 tab 切换时短暂闪变导致 BottomBar 抖动
  bool _stableIsRoot = true;

  bool get _isRootBranch {
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

          // 主内容区
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

    // 如果实际值与稳定值不同，延迟一帧后再更新，避免 tab 切换时的瞬时抖动
    final actualIsRoot = _isRootBranch;
    if (actualIsRoot != _stableIsRoot) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _stableIsRoot = actualIsRoot);
      });
    }
    final isRoot = _stableIsRoot;

    // 计算底部栏完整的设计高度
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double totalBottomBarHeight =
        kBottomNavigationBarHeight + bottomPadding + 8;

    return Scaffold(
      key: rootScaffoldKey,
      drawer: const MainDrawer(),
      body: Column(
        children: [
          Expanded(child: widget.navigationShell),
          if (!isMiniMode) ...[
            NowPlayingBar(),
            // 当导航栏隐藏时，填入底部安全区高度，将胶囊栏托举在安全区上方
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              height: isRoot ? 0.0 : bottomPadding,
            ),
          ],
        ],
      ),
      floatingActionButton: isMiniMode ? NowPlayingMiniFab() : null,
      // ── 底部导航栏高度动画（不使用 AnimatedSlide，因为后者不释放布局空间） ──
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        height: isRoot ? totalBottomBarHeight : 0.0,
        child: BottomBar(currentIndex: currentIndex, onTap: onTabChanged),
      ),
    );
  }
}
