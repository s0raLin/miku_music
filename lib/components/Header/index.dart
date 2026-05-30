import 'dart:io';

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

  @override
  Widget build(BuildContext context) {
    // 判断是否在桌面端，只有桌面端才开启拖拽与双击手势
    final isDesktop =
        Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    return SliverAppBar(
      title: title,
      leading: leading,
      pinned: pinned,
      floating: floating,
      snap: snap,
      expandedHeight: expandedHeight,
      flexibleSpace: Stack(
        children: [
          ?flexibleSpace,

          if (isDesktop)
            Positioned.fill(
              child: GestureDetector(
                onDoubleTap: () async {
                  bool isMaximized = await windowManager.isMaximized();
                  if (isMaximized) {
                    windowManager.unmaximize();
                  } else {
                    windowManager.maximize();
                  }
                },
                child: const DragToMoveArea(child: SizedBox.expand()),
              ),
            ),
        ],
      ),
      bottom: bottom,
      actions: [...?actions, if (isDesktop) const _WindowControls()],
    );
  }
}

// 窗口控制按钮，内部自己处理逻辑
class _WindowControls extends StatelessWidget {
  const _WindowControls();

  @override
  Widget build(BuildContext context) {
    const double iconVisualSize = 20;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: ImageIcon(AssetImage(MyAssets.minimize), size: iconVisualSize),
          onPressed: () => windowManager.minimize(),
        ),
        _WindowButton(
          icon: ImageIcon(AssetImage(MyAssets.maximize), size: iconVisualSize),
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
        ),
        _WindowButton(
          icon: ImageIcon(AssetImage(MyAssets.close), size: iconVisualSize),
          isCloseBtn: true,
          onPressed: () => windowManager.hide(),
        ),
      ],
    );
  }
}

class _WindowButton extends StatelessWidget {
  final ImageIcon icon;
  final VoidCallback onPressed;
  final bool isCloseBtn;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.isCloseBtn = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      // M3 语义色：
      //   关闭按钮 → error 容器色（红色系，随主题变化）
      //   其他按钮 → onSurface 的低透明叠加（M3 state layer 规范）
      hoverColor: isCloseBtn
          ? colorScheme.errorContainer
          : colorScheme.onSurface.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(width: 46, height: 40, child: Center(child: icon)),
    );
  }
}
