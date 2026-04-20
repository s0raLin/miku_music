import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/service/Settings/index.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  Color _seedColor;

  // 构造函数初始值
  ThemeProvider({
    ThemeMode initialMode = ThemeMode.light,
    Color initialColor = Colors.deepPurple,
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

  // 使用 FlexColorScheme 生成主题
  ThemeData get lightTheme => FlexThemeData.light(
    keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
    // 如果想用预设的主题颜色，可以使用 scheme: FlexScheme.materialBaseline
    // 这里使用你的自定义 seedColor
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 7,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      useTextTheme: true,
      // 1. 禁用滚动时的海拔（阴影）
      appBarScrolledUnderElevation: 0,

      useM2StyleDividerInM3: true,
      adaptiveRemoveElevationTint: FlexAdaptive.all(),
      adaptiveElevationShadowsBack: FlexAdaptive.all(),
      adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
      adaptiveRadius: FlexAdaptive.all(),
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
      navigationBarSelectedIconSchemeColor: SchemeColor.primary,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    fontFamily: GoogleFonts.notoSansSc().fontFamily,
  );

  ThemeData get darkTheme => FlexThemeData.dark(
    keyColors: const FlexKeyColors(useSecondary: true, useTertiary: true),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 13,
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      useTextTheme: true,
      // 1. 禁用滚动时的海拔（阴影）
      appBarScrolledUnderElevation: 0,

      useM2StyleDividerInM3: true,
      adaptiveRemoveElevationTint: FlexAdaptive.all(),
      adaptiveElevationShadowsBack: FlexAdaptive.all(),
      adaptiveAppBarScrollUnderOff: FlexAdaptive.all(),
      adaptiveRadius: FlexAdaptive.all(),
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      alignedDropdown: true,
      navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
      navigationBarSelectedIconSchemeColor: SchemeColor.primary,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    fontFamily: GoogleFonts.notoSansSc().fontFamily,
  );

  ThemeData get themeData {
    final baseTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: _themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light,
      ),
    );
    return baseTheme.copyWith(
      textTheme: GoogleFonts.notoSansScTextTheme(baseTheme.textTheme),
    );
  }
}
