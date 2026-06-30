// 桌面端无动画切换逻辑
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

enum SliderStyle { straight, wave }

/// 颜色调整配置（便于未来扩展不同风格）
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
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = const Color(0xFFC49B8A);
  SliderStyle _sliderStyle = SliderStyle.wave;
  String _listDensity = "normal";

  final ColorAdjustments _adjustments = const ColorAdjustments();

  ThemeProvider();

  // ==================== Getters ====================
  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  SliderStyle get sliderStyle => _sliderStyle;
  String get listDensity => _listDensity;

  // ==================== 更新方法 ====================
  void updateFromMap(Map<String, dynamic> data) {
    _seedColor = data['seedColor'] ?? _seedColor;
    _themeMode = data['themeMode'] ?? _themeMode;
    final s = data['sliderStyle'];
    _sliderStyle = s == 'wave' ? SliderStyle.wave : SliderStyle.straight;
    _listDensity = data['listDensity'] ?? _listDensity;
    notifyListeners();
  }

  // ==================== Setters ====================
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

  void setSliderStyle(SliderStyle s) {
    _sliderStyle = s;
    notifyListeners();
    SettingService.setSliderStyle(s.name);
  }

  void setListDensity(String v) {
    _listDensity = v;
    notifyListeners();
    SettingService.setListDensity(v);
  }

  Color blend(Color c) =>
      Color(Blend.harmonize(c.toARGB32(), _seedColor.toARGB32()));

  // ==================== 核心主题构建 ====================
  ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
      ),
    );

    final raw = base.colorScheme;
    final adj = _adjustments;

    final desatTarget = isLight ? adj.desatTargetLight : adj.desatTargetDark;
    final neutralBase = isLight ? adj.neutralBaseLight : adj.neutralBaseDark;

    // 柔化颜色
    final soft = _createSoftColorScheme(raw, desatTarget, neutralBase, adj);

    final finalSurface = isLight
        ? const Color(0xFFFDFDFB)
        : const Color(0xFF141211);

    final surfaceColors = _createSurfaceColors(soft.surface, desatTarget);

    final s = soft.copyWith(
      surface: finalSurface,
      surfaceContainerLowest: surfaceColors.lowest,
      surfaceContainerLow: surfaceColors.low,
      surfaceContainer: surfaceColors.medium,
      surfaceContainerHigh: surfaceColors.high,
      surfaceContainerHighest: surfaceColors.highest,
    );

    final softOnSurface = _lerp(s.onSurface, neutralBase, 0.15);
    final softOnSurfaceVariant = _lerp(s.onSurfaceVariant, neutralBase, 0.35);
    final softOutline = _lerp(s.outline, desatTarget, 0.25);

    final pill = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(28),
    );

    return base.copyWith(
      colorScheme: s,
      scaffoldBackgroundColor: finalSurface,

      // Page Transitions
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
        },
      ),

      // Typography
      textTheme: GoogleFonts.notoSansScTextTheme(base.textTheme)
          .copyWith(
            headlineLarge: const TextStyle(
              letterSpacing: -0.8,
              fontWeight: FontWeight.w600,
            ),
            headlineMedium: const TextStyle(
              letterSpacing: -0.5,
              fontWeight: FontWeight.w600,
            ),
            titleLarge: const TextStyle(
              letterSpacing: -0.3,
              fontWeight: FontWeight.w600,
            ),
            titleMedium: const TextStyle(
              letterSpacing: -0.2,
              fontWeight: FontWeight.w500,
            ),
            bodyLarge: const TextStyle(letterSpacing: 0.1),
            bodyMedium: const TextStyle(letterSpacing: 0.1),
            labelLarge: const TextStyle(
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
            labelMedium: const TextStyle(letterSpacing: 0.4),
            labelSmall: const TextStyle(letterSpacing: 0.3),
          )
          .apply(bodyColor: softOnSurface, displayColor: softOnSurface),

      // AppBar (compact)
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        toolbarHeight: 52,
        backgroundColor: finalSurface,
        foregroundColor: softOnSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        titleTextStyle: GoogleFonts.notoSansSc(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: softOnSurface,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColors.low,
        surfaceTintColor: Colors.transparent,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),

      // NavigationBar (compact)
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: finalSurface,
        indicatorColor: s.secondaryContainer,
        indicatorShape: pill,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? IconThemeData(color: s.onSecondaryContainer, size: 22)
              : IconThemeData(color: softOnSurfaceVariant, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)
              : const TextStyle(fontSize: 11);
        }),
      ),

      // Buttons (compact)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          foregroundColor: s.onPrimary,
          backgroundColor: s.primary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: pill,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: softOnSurface,
          backgroundColor: surfaceColors.low,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: pill,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.primary,
          side: BorderSide(color: softOutline, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          shape: pill,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: pill,
        ),
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surfaceContainerHighest,
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
          borderSide: BorderSide(color: s.primary, width: 1.5),
        ),
        labelStyle: TextStyle(color: softOnSurfaceVariant),
        hintStyle: TextStyle(
          color: softOnSurfaceVariant.withValues(alpha: 0.4),
        ),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: s.primary,
        inactiveTrackColor: s.surfaceContainerHighest,
        thumbColor: s.primary,
        overlayColor: s.primary.withValues(alpha: 0.1),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? s.primary : softOutline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.primary.withValues(alpha: 0.25)
              : s.surfaceContainerHighest,
        ),
      ),

      // Other common themes
      listTileTheme: ListTileThemeData(
        dense: _listDensity == "compact",
        contentPadding: _listDensity == "compact"
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 0)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        visualDensity: _listDensity == "compact"
            ? const VisualDensity(horizontal: -2, vertical: -2)
            : VisualDensity.standard,
        titleTextStyle: TextStyle(color: softOnSurface),
        subtitleTextStyle: TextStyle(color: softOnSurfaceVariant),
        iconColor: softOnSurfaceVariant,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: s.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: isLight ? 4 : 0,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: const Radius.circular(28)),
        ),
      ),
    );
  }

  ColorScheme _createSoftColorScheme(
    ColorScheme raw,
    Color desatTarget,
    Color neutralBase,
    ColorAdjustments adj,
  ) {
    return raw.copyWith(
      primary: _lerp(raw.primary, desatTarget, adj.primaryDesat),
      primaryContainer: _lerp(
        raw.primaryContainer,
        desatTarget,
        adj.containerDesat,
      ),
      onPrimaryContainer: _lerp(raw.onPrimaryContainer, neutralBase, 0.10),
      secondary: _lerp(raw.secondary, desatTarget, 0.18),
      secondaryContainer: _lerp(raw.secondaryContainer, desatTarget, 0.35),
      tertiary: _lerp(raw.tertiary, desatTarget, 0.20),
      tertiaryContainer: _lerp(raw.tertiaryContainer, desatTarget, 0.35),
    );
  }

  ({Color lowest, Color low, Color medium, Color high, Color highest})
  _createSurfaceColors(Color baseSurface, Color desatTarget) {
    return (
      lowest: _lerp(baseSurface, desatTarget, 0.20),
      low: _lerp(baseSurface, desatTarget, 0.30),
      medium: _lerp(baseSurface, desatTarget, 0.45),
      high: _lerp(baseSurface, desatTarget, 0.60),
      highest: _lerp(baseSurface, desatTarget, 0.75),
    );
  }

  Color _lerp(Color a, Color b, double t) => Color.lerp(a, b, t)!;

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);
}
