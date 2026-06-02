// 桌面端无动画切换逻辑
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_color_utilities/blend/blend.dart';
import 'package:myapp/service/AppIcon/index.dart';
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

/// 进度条样式
enum SliderStyle {
  straight, // 标准直线
  wave, // 蛇形波浪
}

class ThemeProvider extends ChangeNotifier {
  // 设置默认值，防止在数据加载完成前出现空引用
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = const Color(0xFF6750A4);
  SliderStyle _sliderStyle = SliderStyle.wave;
  String _listDensity = "normal";
  String _audioQuality = "normal";
  bool _showLyricCover = true;
  bool _autoPlayOnStart = false;
  bool _showNotificationDetail = true;
  bool _doubleTapToPlay = true;
  String _playlistSortBy = "time";
  int _maxHistoryCount = 100;
  String _appIconPath = "assets/app_icon/app_icon1.png";

  ThemeProvider();

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  SliderStyle get sliderStyle => _sliderStyle;
  String get listDensity => _listDensity;
  String get audioQuality => _audioQuality;
  bool get showLyricCover => _showLyricCover;
  bool get autoPlayOnStart => _autoPlayOnStart;
  bool get showNotificationDetail => _showNotificationDetail;
  bool get doubleTapToPlay => _doubleTapToPlay;
  String get playlistSortBy => _playlistSortBy;
  int get maxHistoryCount => _maxHistoryCount;
  String get appIconPath => _appIconPath;

  void updateFromMap(Map<String, dynamic> data) {
    // 使用 ?? 语法确保如果 Map 里的值缺失，保留当前的默认值
    _seedColor = data['seedColor'] ?? _seedColor;
    _themeMode = data['themeMode'] ?? _themeMode;
    // 3. 从本地恢复时，将字符串安全地解析回枚举
    final savedStyleStr = data['sliderStyle'];
    if (savedStyleStr == 'wave') {
      _sliderStyle = SliderStyle.wave;
    } else {
      _sliderStyle = SliderStyle.straight;
    }
    _listDensity = data['listDensity'] ?? _listDensity;
    _audioQuality = data['audioQuality'] ?? _audioQuality;
    _showLyricCover = data['showLyricCover'] ?? _showLyricCover;
    _autoPlayOnStart = data['autoPlayOnStart'] ?? _autoPlayOnStart;
    _showNotificationDetail =
        data['showNotificationDetail'] ?? _showNotificationDetail;
    _doubleTapToPlay = data['doubleTapToPlay'] ?? _doubleTapToPlay;
    _playlistSortBy = data['playlistSortBy'] ?? _playlistSortBy;
    _maxHistoryCount = data['maxHistoryCount'] ?? _maxHistoryCount;
    _appIconPath = data['appIconPath'] ?? _appIconPath;

    // 关键：通知 UI 刷新样式
    notifyListeners();
  }

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

  void setSliderStyle(SliderStyle sliderStyle) {
    _sliderStyle = sliderStyle;
    notifyListeners();
    SettingService.setSliderStyle(sliderStyle.name);
  }

  void setListDensity(String density) {
    _listDensity = density;
    notifyListeners();
    SettingService.setListDensity(density);
  }

  void setAudioQuality(String quality) {
    _audioQuality = quality;
    notifyListeners();
    SettingService.setAudioQuality(quality);
  }

  void setShowLyricCover(bool show) {
    _showLyricCover = show;
    notifyListeners();
    SettingService.setShowLyricCover(show);
  }

  void setAutoPlayOnStart(bool autoPlay) {
    _autoPlayOnStart = autoPlay;
    notifyListeners();
    SettingService.setAutoPlayOnStart(autoPlay);
  }

  void setShowNotificationDetail(bool show) {
    _showNotificationDetail = show;
    notifyListeners();
    SettingService.setShowNotificationDetail(show);
  }

  void setDoubleTapToPlay(bool enable) {
    _doubleTapToPlay = enable;
    notifyListeners();
    SettingService.setDoubleTapToPlay(enable);
  }

  void setPlaylistSortBy(String sortBy) {
    _playlistSortBy = sortBy;
    notifyListeners();
    SettingService.setPlaylistSortBy(sortBy);
  }

  void setMaxHistoryCount(int count) {
    _maxHistoryCount = count;
    notifyListeners();
    SettingService.setMaxHistoryCount(count);
  }

  void setAppIconPath(String iconPath) {
    _appIconPath = iconPath;
    notifyListeners();
    SettingService.setAppIcon(iconPath);
    AppIconService.switchAppIcon(iconPath);
  }

  // M3 颜色谐波化算法：让自定义颜色（如链接色）适配主题种子色
  Color blend(Color targetColor) {
    return Color(
      Blend.harmonize(targetColor.toARGB32(), _seedColor.toARGB32()),
    );
  }

  // --- 主题构建 ---

  // M3 圆角 Token 体系
  static const _kShapeSmall = 8.0;
  static const _kShapeMedium = 12.0;
  static const _kShapeLarge = 16.0;
  static const _kShapeExtraLarge = 28.0;

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

    // ── 通用 Button 样式基座 ──
    final filledBtnStyle = FilledButton.styleFrom(
      foregroundColor: scheme.onPrimary,
      backgroundColor: scheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kShapeLarge),
      ),
    );
    final elevatedBtnStyle = ElevatedButton.styleFrom(
      foregroundColor: scheme.onSurface,
      backgroundColor: scheme.surfaceContainerLow,
      elevation: 1,
      shadowColor: Colors.transparent,
      surfaceTintColor: scheme.surfaceTint,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kShapeLarge),
      ),
    );
    final outlinedBtnStyle = OutlinedButton.styleFrom(
      foregroundColor: scheme.primary,
      side: BorderSide(color: scheme.outline, width: 1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kShapeLarge),
      ),
    );
    final textBtnStyle = TextButton.styleFrom(
      foregroundColor: scheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_kShapeLarge),
      ),
    );

    return baseTheme.copyWith(
      // ── 平台转场动画 ──
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
        },
      ),

      // ── Typography ──
      textTheme: GoogleFonts.notoSansScTextTheme(baseTheme.textTheme),

      // ── Scaffold Background（M3 分层） ──
      scaffoldBackgroundColor: scheme.surface,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kShapeMedium),
        ),
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      ),

      // ── NavigationBar (Bottom) ──
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainerHigh,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
      ),

      // ── NavigationRail (Sidebar) ──
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.onSecondaryContainer),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: TextStyle(color: scheme.onSecondaryContainer),
        unselectedLabelTextStyle: TextStyle(color: scheme.onSurfaceVariant),
      ),

      // ── Drawer ──
      drawerTheme: DrawerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),

      // ── ListTile (M3 默认无 shape 约束，保留原生波纹) ──
      listTileTheme: ListTileThemeData(
        selectedColor: scheme.secondaryContainer,
        selectedTileColor: scheme.secondaryContainer,
        dense: _listDensity == "compact",
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // ── Buttons (完整 M3 Extended) ──
      filledButtonTheme: FilledButtonThemeData(style: filledBtnStyle),
      elevatedButtonTheme: ElevatedButtonThemeData(style: elevatedBtnStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlinedBtnStyle),
      textButtonTheme: TextButtonThemeData(style: textBtnStyle),

      // ── IconButton (M3 默认圆形 ink splash，不强制 shape) ──

      // ── FloatingActionButton ──
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kShapeLarge),
        ),
      ),

      // ── InputDecoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kShapeSmall),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kShapeSmall),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kShapeSmall),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kShapeSmall),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kShapeSmall),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        labelStyle: TextStyle(color: scheme.onSurfaceVariant),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        selectedColor: scheme.secondaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 13),
        secondaryLabelStyle: TextStyle(color: scheme.onSecondaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kShapeSmall),
        ),
        side: BorderSide.none,
        elevation: 0,
      ),

      // ── Dialog (covers both Dialog and AlertDialog in M3) ──
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kShapeExtraLarge),
        ),
        elevation: 6,
      ),

      // ── SnackBar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kShapeMedium),
        ),
      ),

      // ── BottomSheet ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_kShapeExtraLarge)),
        ),
        elevation: 6,
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── DropdownMenu ──
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kShapeLarge),
            ),
          ),
          elevation: const WidgetStatePropertyAll(6),
          surfaceTintColor: WidgetStatePropertyAll(scheme.surfaceTint),
        ),
      ),

      // ── Menu ──
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
          surfaceTintColor: WidgetStatePropertyAll(scheme.surfaceTint),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_kShapeLarge),
            ),
          ),
          elevation: const WidgetStatePropertyAll(3),
        ),
      ),

      // ── Progress Indicator ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
      ),

      // ── Slider ──
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        activeTickMarkColor: scheme.onPrimary,
        inactiveTickMarkColor: scheme.surfaceContainerHighest,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
        valueIndicatorColor: scheme.primary,
        valueIndicatorTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 12,
        ),
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return scheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return scheme.primary.withValues(alpha: 0.4);
          }
          return scheme.surfaceContainerHighest;
        }),
      ),

      // ── Checkbox ──
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return scheme.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll(scheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Tooltip ──
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.inverseSurface,
          borderRadius: BorderRadius.circular(_kShapeSmall),
        ),
        textStyle: TextStyle(color: scheme.onInverseSurface, fontSize: 12),
      ),

      // ── PopupMenu ──
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainer,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kShapeLarge),
        ),
        elevation: 3,
      ),
    );
  }

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);
}
