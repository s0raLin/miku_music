import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:window_manager/window_manager.dart';

class Header extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? title;
  final bool centerTitle;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final List<Widget>? actions;
  final bool pinned;
  final bool floating;
  final bool snap;
  final double? expandedHeight;
  final Widget? flexibleSpace;

  const Header({
    super.key,
    this.scaffoldKey,
    this.title,
    this.centerTitle = true,
    this.leading,
    this.actions,
    this.bottom,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
    this.expandedHeight,
    this.flexibleSpace,
  });

  /// 安全判断是否为桌面端（兼容 Web）
  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  @override
  Widget build(BuildContext context) {
    final titleWidget = title;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;

    return SliverAppBar(
      title: titleWidget == null
          ? null
          : _isDesktop
          ? DragToMoveArea(child: titleWidget)
          : titleWidget,
      centerTitle: centerTitle,
      leading: leading,
      pinned: pinned,
      floating: floating,
      snap: snap,
      toolbarHeight: kToolbarHeight,
      collapsedHeight: expandedHeight == null
          ? kToolbarHeight + bottomHeight
          : null,
      expandedHeight: expandedHeight,
      backgroundColor: colorScheme.surfaceContainerLow,
      foregroundColor: colorScheme.onSurface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      actions: [...?actions, if (_isDesktop) const _WindowControls()],
    );
  }
}

/// 窗口控制按钮组
class _WindowControls extends StatelessWidget {
  const _WindowControls();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          iconPath: MyAssets.minimize,
          action: _WindowAction.minimize,
        ),
        _WindowButton(
          iconPath: MyAssets.maximize,
          action: _WindowAction.maximize,
        ),
        _WindowButton(iconPath: MyAssets.close, action: _WindowAction.close),
      ],
    );
  }
}

enum _WindowAction { minimize, maximize, close }

/// 单个窗口控制按钮（性能优化版）
class _WindowButton extends StatelessWidget {
  final String iconPath;
  final _WindowAction action;

  const _WindowButton({required this.iconPath, required this.action});

  Future<void> _handlePressed() async {
    switch (action) {
      case _WindowAction.minimize:
        await windowManager.minimize();
      case _WindowAction.maximize:
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      case _WindowAction.close:
        await windowManager.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCloseBtn = action == _WindowAction.close;

    return InkWell(
      onTap: _handlePressed,
      hoverColor: isCloseBtn
          ? colorScheme.errorContainer
          : colorScheme.onSurface.withValues(alpha: 0.08),
      // 桌面端规范：关闭按钮悬浮时，图标通常变为白色/错误色前景
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 46,
        height: 40,
        child: Center(child: ImageIcon(AssetImage(iconPath), size: 20)),
      ),
    );
  }
}
