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

class ThemeProvider extends ChangeNotifier {
  // 设置默认值，防止在数据加载完成前出现空引用
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = const Color(0xFF6750A4);
  String _sliderStyle = "straight";
  String _listDensity = "normal";
  String _audioQuality = "normal";
  bool _showLyricCover = true;
  bool _autoPlayOnStart = false;
  bool _showNotificationDetail = true;
  bool _doubleTapToPlay = true;
  String _playlistSortBy = "time";
  int _maxHistoryCount = 100;

  ThemeProvider();

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  String get sliderStyle => _sliderStyle;
  String get listDensity => _listDensity;
  String get audioQuality => _audioQuality;
  bool get showLyricCover => _showLyricCover;
  bool get autoPlayOnStart => _autoPlayOnStart;
  bool get showNotificationDetail => _showNotificationDetail;
  bool get doubleTapToPlay => _doubleTapToPlay;
  String get playlistSortBy => _playlistSortBy;
  int get maxHistoryCount => _maxHistoryCount;

  void updateFromMap(Map<String, dynamic> data) {
    // 使用 ?? 语法确保如果 Map 里的值缺失，保留当前的默认值
    _seedColor = data['seedColor'] ?? _seedColor;
    _themeMode = data['themeMode'] ?? _themeMode;
    _sliderStyle = data['sliderStyle'] ?? _sliderStyle;
    _listDensity = data['listDensity'] ?? _listDensity;
    _audioQuality = data['audioQuality'] ?? _audioQuality;
    _showLyricCover = data['showLyricCover'] ?? _showLyricCover;
    _autoPlayOnStart = data['autoPlayOnStart'] ?? _autoPlayOnStart;
    _showNotificationDetail =
        data['showNotificationDetail'] ?? _showNotificationDetail;
    _doubleTapToPlay = data['doubleTapToPlay'] ?? _doubleTapToPlay;
    _playlistSortBy = data['playlistSortBy'] ?? _playlistSortBy;
    _maxHistoryCount = data['maxHistoryCount'] ?? _maxHistoryCount;

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

  void setSliderStyle(String sliderStyle) {
    _sliderStyle = sliderStyle;
    notifyListeners();
    SettingService.setSliderStyle(sliderStyle);
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

  // M3 颜色谐波化算法：让自定义颜色（如链接色）适配主题种子色
  Color blend(Color targetColor) {
    return Color(
      Blend.harmonize(targetColor.toARGB32(), _seedColor.toARGB32()),
    );
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
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
          TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
        },
      ),

      // 整合：你的 GoogleFonts，根据字体缩放调整
      textTheme: GoogleFonts.notoSansScTextTheme(baseTheme.textTheme),

      // 整合：新代码中更精细的组件样式
      appBarTheme: AppBarTheme(
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surfaceContainerLow,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
      ),

      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: scheme.surfaceContainerHigh,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        surfaceTintColor: Colors.transparent,
      ),

      drawerTheme: DrawerThemeData(backgroundColor: scheme.surface),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        selectedColor: scheme.secondary,
        dense: _listDensity == "compact",
      ),

      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
      ),

      // 配置 DropdownMenu 的统一样式
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          // 设置下拉列表的背景色（通常使用 surfaceContainer 系列）
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
          // 设置统一的圆角
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          // 这里的 elevation 可以控制投影
          elevation: const WidgetStatePropertyAll(6),
        ),
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
