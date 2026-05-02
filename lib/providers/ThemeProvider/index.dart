// 桌面端无动画切换逻辑
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_color_utilities/blend/blend.dart';
import 'package:myapp/service/Settings/index.dart';

class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode;
  Color _seedColor;

  ThemeProvider({
    ThemeMode initialMode = ThemeMode.system,
    Color initialColor = const Color(0xFF6750A4),
  }) : _themeMode = initialMode,
       _seedColor = initialColor;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  // --- 逻辑方法 ---

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    SettingService.setThemeMode(mode);
  }

  void setSeedColor(Color color) {
    _seedColor = color;
    notifyListeners();
    SettingService.setColor(color);
  }

  // M3 颜色谐波化算法：让自定义颜色（如链接色）适配主题种子色
  Color blend(Color targetColor) {
    return Color(Blend.harmonize(targetColor.value, _seedColor.value));
  }

  // --- 主题构建 ---

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      ),
    );

    final scheme = baseTheme.colorScheme;

    return baseTheme.copyWith(
      // 整合：桌面端优化动画
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
        },
      ),

      // 整合：你的 GoogleFonts
      textTheme: GoogleFonts.notoSansScTextTheme(baseTheme.textTheme),

      // 整合：新代码中更精细的组件样式
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),

      drawerTheme: DrawerThemeData(backgroundColor: scheme.surface),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selectedColor: scheme.secondary,
      ),

      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
      ),

      // 菜单样式
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);
}
