import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class AppTrayManager with TrayListener {
  static final AppTrayManager instance = AppTrayManager._internal();
  factory AppTrayManager() => instance;
  AppTrayManager._internal();

  Future<void> init() async {
    final String iconPath = 'assets/app_icon/app_icon.png';

    await trayManager.setIcon(iconPath);

    if (!Platform.isLinux) {
      await trayManager.setToolTip('M3Music');
    }

    final menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: '显示窗口'),
        MenuItem(key: 'hide_window', label: '隐藏到托盘'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: '退出应用'),
      ],
    );

    await trayManager.setContextMenu(menu);
    trayManager.addListener(this);
  }

  // 窗口控制
  Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> hideWindow() async {
    await windowManager.hide();
  }

  // 托盘事件
  @override
  void onTrayIconMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayIconRightMouseDown() => trayManager.popUpContextMenu();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        showWindow();
        break;
      case 'hide_window':
        hideWindow();
        break;
      case 'exit_app':
        exit(0);
    }
  }

  void dispose() {
    trayManager.removeListener(this);
  }
}
