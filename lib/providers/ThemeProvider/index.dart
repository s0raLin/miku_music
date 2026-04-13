import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/service/Settings/index.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  Color _seedColor;

  // 构造函数初始值
  ThemeProvider({
    ThemeMode initialMode = ThemeMode.light,
    Color initialColor = Colors.teal,
  }) : _themeMode = initialMode,
       _seedColor = initialColor;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
    //状态改变时自动持久化
    SettingService.setThemeMode(themeMode);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    SettingService.setThemeMode(mode);
  }

  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
    //持久化颜色值
    SettingService.setColor(color);
  }

  // ThemeData get themeData => ThemeData(
  //   useMaterial3: true,
  //   fontFamily: "NiShiKiFont",
  //   colorScheme: ColorScheme.fromSeed(
  //     seedColor: _seedColor,
  //     brightness: _themeMode == ThemeMode.dark
  //         ? Brightness.dark
  //         : Brightness.light,
  //   ),
  // );

  ThemeData get themeData {
    final baseTheme = ThemeData(
      useMaterial3: true,
      fontFamily: "NiShiKiFont",
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: _themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light,
      ),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.dotGothic16TextTheme(baseTheme.textTheme),
    );
  }
}
