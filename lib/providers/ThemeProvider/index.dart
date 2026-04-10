import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  Color _seedColor = Colors.deepPurple;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleThemeMode() {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
  }

  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: _themeMode == ThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
    ),
  );
}
