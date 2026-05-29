import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dynamic_icon_plus/flutter_dynamic_icon_plus.dart';

class AppIconService {
  /// 接收类似 "assets/app_icon/app_icon1.png" 或 "assets/app_icon/app_icon.png" 的路径
  static Future<void> switchAppIcon(String iconPath) async {
    if (!Platform.isAndroid) return;

    try {
      // ⚠️ 极其重要：请把这里替换成你真实的 Android 包名 (Application ID)
      // 必须和你的 AndroidManifest.xml 中 package 对应
      const String packageName = "com.app.m3music";

      String targetAlias;

      // 1. 使用正则表达式匹配路径中的数字
      // 如果 iconPath 包含数字（如 app_icon1.png），RegExp 会抓取到 "1"
      final match = RegExp(r'app_icon(\d+)').firstMatch(iconPath);

      if (match != null) {
        // 抓取到了数字，说明是预设图标 1-9
        String indexStr = match.group(1)!;
        targetAlias = "$packageName.MainActivityIcon$indexStr";
      } else {
        // 没有抓取到数字（如 app_icon.png），说明切换回默认图标
        targetAlias = "$packageName.MainActivityDefault";
      }

      // 2. 调用插件执行切换（使用修正后的命名参数）
      await FlutterDynamicIconPlus.setAlternateIconName(iconName: targetAlias);
      debugPrint("【图标服务】成功切换至别名: $targetAlias");
    } catch (e) {
      debugPrint("【图标服务】切换遇到错误: $e");
    }
  }
}
