import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/service/Settings/index.dart';

class AppIconService {
  static const MethodChannel _channel = MethodChannel('com.app.m3music/dynamic_icon');
  static const String manifestNamespace = 'com.app.m3music';

  static const String defaultIconPath = 'assets/app_icon/app_icon1.png';

  /// activity-alias 全类名，例如 com.app.m3music.MainActivityIcon2
  static String aliasForPath(String iconPath) {
    final match = RegExp(r'app_icon(\d+)').firstMatch(iconPath);
    if (match != null) {
      return '$manifestNamespace.MainActivityIcon${match.group(1)}';
    }
    return '$manifestNamespace.MainActivityDefault';
  }

  /// 将 activity-alias 映射为应用内预览资源路径
  static String pathForAlias(String? alias) {
    if (alias == null || alias.endsWith('MainActivityDefault')) {
      return MyAssets.app_icon;
    }
    final match = RegExp(r'MainActivityIcon(\d+)$').firstMatch(alias);
    if (match != null) {
      return 'assets/app_icon/app_icon${match.group(1)}.png';
    }
    return defaultIconPath;
  }

  /// 当前启用的 activity-alias（仅 Android）；失败或非 Android 返回 null
  static Future<String?> getCurrentAlias() async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String?>('getCurrentAlias');
    } on PlatformException catch (e) {
      debugPrint('【图标服务】读取当前别名失败: ${e.code} ${e.message}');
      return null;
    }
  }

  /// 当前应用图标对应的 assets 路径（启动页、设置预览等）
  static Future<String> getCurrentAppIconPath() async {
    if (Platform.isAndroid) {
      final alias = await getCurrentAlias();
      if (alias != null) {
        return pathForAlias(alias);
      }
    }
    return SettingService.loadAppIcon();
  }

  /// 接收类似 "assets/app_icon/app_icon1.png" 或 "assets/app_icon/app_icon.png" 的路径
  static Future<void> switchAppIcon(String iconPath) async {
    if (!Platform.isAndroid) return;

    final targetAlias = aliasForPath(iconPath);

    try {
      final applied = await _channel.invokeMethod<String>('applyAlias', {
        'aliasClass': targetAlias,
      });
      final current = await getCurrentAlias();
      debugPrint('【图标服务】目标别名: $targetAlias');
      debugPrint('【图标服务】当前启用别名: ${current ?? applied ?? "(未知)"}');
      if (current != targetAlias) {
        debugPrint('【图标服务】部分桌面会延迟刷新，可重启桌面或划掉应用后查看');
      }
    } on PlatformException catch (e) {
      debugPrint('【图标服务】切换失败: ${e.code} ${e.message}');
    }
  }
}
