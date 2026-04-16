import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingService {
  static Future setColor(Color color) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setInt("themeColor", color.toARGB32());
  }

  static Future setThemeMode(ThemeMode mode) async {
    final pfs = await SharedPreferences.getInstance();

    await pfs.setInt("modeIndex", mode.index);
  }

  static Future<Color> loadColor() async {
    final pfs = await SharedPreferences.getInstance();
    final colorValue = pfs.getInt("themeColor");

    if (colorValue != null) {
      return Color(colorValue);
    }
    //如果没存过,返回默认颜色
    return Colors.teal;
  }

  static Future<ThemeMode> loadThemeMode() async {
    final pfs = await SharedPreferences.getInstance();
    final modeIndex = pfs.getInt("modeIndex");

    if (modeIndex != null) {
      return ThemeMode.values[modeIndex];
    }
    return ThemeMode.light;
  }

  static Future setIsDark(bool isDark) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setBool("isDark", isDark);
  }

  static Future loadIsDark() async {
    final pfs = await SharedPreferences.getInstance();
    final isDark = pfs.getBool("isDark");
    if (isDark != null) {
      return isDark;
    }
    return false;
  }
}
