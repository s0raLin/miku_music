import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:material_color_utilities/blend/blend.dart';
import 'package:myapp/service/Settings/index.dart';

// ============================================================================
// 1. 桌面端无动画 PageTransition
// ============================================================================
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

enum SliderStyle { straight, wave }

// ============================================================================
// 2. 颜色微调参数配置 (可根据明暗模式自动匹配/覆盖)
// ============================================================================
@immutable
class ColorAdjustments {
  final double primaryDesat;
  final double containerDesat;
  final double neutralStrength;
  final Color desatTargetLight;
  final Color desatTargetDark;
  final Color neutralBaseLight;
  final Color neutralBaseDark;

  const ColorAdjustments({
    this.primaryDesat = 0.15,
    this.containerDesat = 0.30,
    this.neutralStrength = 0.15,
    this.desatTargetLight = const Color(0xFFF0EAE4),
    this.desatTargetDark = const Color(0xFF282423),
    this.neutralBaseLight = const Color(0xFF4A4341),
    this.neutralBaseDark = const Color(0xFFE5DDD9),
  });

  /// 快速获取当前亮暗对应的目标颜色 Record
  ({Color desatTarget, Color neutralBase}) targetsFor(Brightness brightness) {
    return brightness == Brightness.light
        ? (desatTarget: desatTargetLight, neutralBase: neutralBaseLight)
        : (desatTarget: desatTargetDark, neutralBase: neutralBaseDark);
  }
}

// ============================================================================
// 3. 颜色柔化与 Surface 生成引擎
// ============================================================================
abstract class SoftThemeEngine {
  static Color lerp(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  /// 生成柔化后的 ColorScheme
  static ColorScheme buildSoftColorScheme(
    ColorScheme raw,
    Brightness brightness,
    ColorAdjustments adj,
  ) {
    final (:desatTarget, :neutralBase) = adj.targetsFor(brightness);

    return raw.copyWith(
      primary: lerp(raw.primary, desatTarget, adj.primaryDesat),
      primaryContainer: lerp(
        raw.primaryContainer,
        desatTarget,
        adj.containerDesat,
      ),
      onPrimaryContainer: lerp(raw.onPrimaryContainer, neutralBase, 0.10),
      secondary: lerp(raw.secondary, desatTarget, 0.18),
      secondaryContainer: lerp(raw.secondaryContainer, desatTarget, 0.35),
      tertiary: lerp(raw.tertiary, desatTarget, 0.20),
      tertiaryContainer: lerp(raw.tertiaryContainer, desatTarget, 0.35),
    );
  }

  /// 计算容器阶梯色
  static ({Color lowest, Color low, Color medium, Color high, Color highest})
  buildSurfaceContainers(Color baseSurface, Color desatTarget) {
    return (
      lowest: lerp(baseSurface, desatTarget, 0.20),
      low: lerp(baseSurface, desatTarget, 0.30),
      medium: lerp(baseSurface, desatTarget, 0.45),
      high: lerp(baseSurface, desatTarget, 0.60),
      highest: lerp(baseSurface, desatTarget, 0.75),
    );
  }
}

// ============================================================================
// 4. ThemeProvider 主控制器
// ============================================================================
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = const Color(0xFFC49B8A);
  SliderStyle _sliderStyle = SliderStyle.wave;
  String _listDensity = 'normal';

  final ColorAdjustments adjustments;

  ThemeProvider({this.adjustments = const ColorAdjustments()});

  // ---------------- Getters ----------------
  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  SliderStyle get sliderStyle => _sliderStyle;
  String get listDensity => _listDensity;

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  // ---------------- Setters & Handlers ----------------
  void updateFromMap(Map<String, dynamic> data) {
    _seedColor = data['seedColor'] ?? _seedColor;
    _themeMode = data['themeMode'] ?? _themeMode;
    final s = data['sliderStyle'];
    _sliderStyle = s == 'wave' ? SliderStyle.wave : SliderStyle.straight;
    _listDensity = data['listDensity'] ?? _listDensity;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    SettingService.setThemeMode(mode);
  }

  void setSeedColor(Color color) {
    if (_seedColor == color) return;
    _seedColor = color;
    notifyListeners();
    SettingService.setColor(color);
  }

  void setSliderStyle(SliderStyle style) {
    if (_sliderStyle == style) return;
    _sliderStyle = style;
    notifyListeners();
    SettingService.setSliderStyle(style.name);
  }

  void setListDensity(String density) {
    if (_listDensity == density) return;
    _listDensity = density;
    notifyListeners();
    SettingService.setListDensity(density);
  }

  /// 颜色调和 (Harmonization)
  Color blend(Color color) {
    return Color(Blend.harmonize(color.toARGB32(), _seedColor.toARGB32()));
  }

  // ---------------- 核心主题构建方法 ----------------
  ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final (:desatTarget, :neutralBase) = adjustments.targetsFor(brightness);

    // 1. 生成 M3 种子 Scheme
    final rawScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );

    // 2. 二次莫兰迪/柔化处理
    final softScheme = SoftThemeEngine.buildSoftColorScheme(
      rawScheme,
      brightness,
      adjustments,
    );

    // 3. 背景色与文本色精细微调
    final finalSurface = isLight
        ? const Color(0xFFFDFDFB)
        : const Color(0xFF141211);
    final surfaceContainers = SoftThemeEngine.buildSurfaceContainers(
      softScheme.surface,
      desatTarget,
    );

    final softOnSurface = SoftThemeEngine.lerp(
      softScheme.onSurface,
      neutralBase,
      0.15,
    );
    final softOnSurfaceVariant = SoftThemeEngine.lerp(
      softScheme.onSurfaceVariant,
      neutralBase,
      0.35,
    );
    final softOutline = SoftThemeEngine.lerp(
      softScheme.outline,
      desatTarget,
      0.25,
    );

    final finalColorScheme = softScheme.copyWith(
      surface: finalSurface,
      onSurface: softOnSurface,
      onSurfaceVariant: softOnSurfaceVariant,
      outline: softOutline,
      surfaceContainerLowest: surfaceContainers.lowest,
      surfaceContainerLow: surfaceContainers.low,
      surfaceContainer: surfaceContainers.medium,
      surfaceContainerHigh: surfaceContainers.high,
      surfaceContainerHighest: surfaceContainers.highest,
    );

    // 4. 通用 Shape 定义
    final pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );

    // 5. 基础 Theme 构建
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: finalColorScheme,
      scaffoldBackgroundColor: finalSurface,
    );

    return baseTheme.copyWith(
      // 路由切换动画配置
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
        },
      ),

      // Text Theme
      textTheme: baseTheme.textTheme.copyWith(
        headlineLarge: TextStyle(
          letterSpacing: -0.8,
          fontWeight: FontWeight.w600,
          color: softOnSurface,
        ),
        headlineMedium: TextStyle(
          letterSpacing: -0.5,
          fontWeight: FontWeight.w600,
          color: softOnSurface,
        ),
        titleLarge: TextStyle(
          letterSpacing: -0.3,
          fontWeight: FontWeight.w600,
          color: softOnSurface,
        ),
        titleMedium: TextStyle(
          letterSpacing: -0.2,
          fontWeight: FontWeight.w500,
          color: softOnSurface,
        ),
        bodyLarge: TextStyle(letterSpacing: 0.1, color: softOnSurface),
        bodyMedium: TextStyle(letterSpacing: 0.1, color: softOnSurface),
        bodySmall: TextStyle(color: softOnSurfaceVariant),
        labelLarge: TextStyle(
          letterSpacing: 0.6,
          fontWeight: FontWeight.w600,
          color: softOnSurface,
        ),
        labelMedium: TextStyle(letterSpacing: 0.4, color: softOnSurface),
        labelSmall: TextStyle(letterSpacing: 0.3, color: softOnSurfaceVariant),
      ),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        toolbarHeight: 48,
        backgroundColor: finalSurface,
        foregroundColor: softOnSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: softOnSurface,
        ),
      ),

      // TabBar Theme
      tabBarTheme: TabBarThemeData(
        labelColor: finalColorScheme.primary,
        unselectedLabelColor: softOnSurfaceVariant,
        indicatorColor: finalColorScheme.primary,
        overlayColor: WidgetStateProperty.all(
          finalColorScheme.primary.withValues(alpha: 0.08),
        ),
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: finalColorScheme.primary,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: softOnSurfaceVariant,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceContainers.low,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      // NavigationBar Theme
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: finalSurface,
        indicatorColor: finalColorScheme.secondaryContainer,
        indicatorShape: pillShape,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? finalColorScheme.onSecondaryContainer
                : softOnSurfaceVariant,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? softOnSurface : softOnSurfaceVariant,
          );
        }),
      ),

      // Button Themes
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: finalColorScheme.onPrimary,
          backgroundColor: finalColorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: pillShape,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: softOnSurface,
          backgroundColor: surfaceContainers.low,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: pillShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: finalColorScheme.primary,
          side: BorderSide(color: softOutline, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: pillShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: finalColorScheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: pillShape,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: finalColorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: finalColorScheme.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: softOnSurfaceVariant),
        hintStyle: TextStyle(
          color: softOnSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: finalColorScheme.primary,
        inactiveTrackColor: finalColorScheme.surfaceContainerHighest,
        thumbColor: finalColorScheme.primary,
        overlayColor: finalColorScheme.primary.withValues(alpha: 0.1),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? finalColorScheme.primary
              : softOutline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? finalColorScheme.primary.withValues(alpha: 0.25)
              : finalColorScheme.surfaceContainerHighest,
        ),
      ),

      // ListTile Theme
      listTileTheme: ListTileThemeData(
        dense: _listDensity == 'compact',
        contentPadding: _listDensity == 'compact'
            ? const EdgeInsets.symmetric(horizontal: 12)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        visualDensity: _listDensity == 'compact'
            ? const VisualDensity(horizontal: -2, vertical: -2)
            : VisualDensity.standard,
        titleTextStyle: TextStyle(color: softOnSurface),
        subtitleTextStyle: TextStyle(color: softOnSurfaceVariant),
        iconColor: softOnSurfaceVariant,
      ),

      // Dialog & BottomSheet
      dialogTheme: DialogThemeData(
        backgroundColor: finalColorScheme.surfaceContainerHigh,
        shape: cardShape,
        elevation: isLight ? 4 : 0,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: finalColorScheme.surfaceContainerHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
