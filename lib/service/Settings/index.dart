import 'package:flutter/material.dart';
import 'package:myapp/constants/Theme/index.dart';
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
    return MyTheme.kAppDefaultSeedColor;
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

  static Future<bool> loadIsDark() async {
    final pfs = await SharedPreferences.getInstance();
    final isDark = pfs.getBool("isDark");
    if (isDark != null) {
      return isDark;
    }
    return false;
  }

  static Future<void> setSliderStyle(String sliderStyle) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setString("sliderStyle", "straight");
  }

  static Future<String> loadSliderStyle() async {
    final pfs = await SharedPreferences.getInstance();
    final sliderStyle = pfs.getString("sliderStyle");
    if (sliderStyle != null && sliderStyle.isNotEmpty) {
      return sliderStyle;
    }
    return "straight";
  }

  // 列表显示密度设置 (compact: 紧凑, normal: 正常, loose: 宽松)
  static Future setListDensity(String density) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setString("listDensity", density);
  }

  static Future<String> loadListDensity() async {
    final pfs = await SharedPreferences.getInstance();
    final density = pfs.getString("listDensity");
    if (density != null) {
      return density;
    }
    return "normal";
  }

  // 最大播放历史数量
  static Future setMaxHistoryCount(int count) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setInt("maxHistoryCount", count);
  }

  static Future<int> loadMaxHistoryCount() async {
    final pfs = await SharedPreferences.getInstance();
    final count = pfs.getInt("maxHistoryCount");
    if (count != null) {
      return count;
    }
    return 100;
  }

  // 是否显示歌词封面
  static Future setShowLyricCover(bool show) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setBool("showLyricCover", show);
  }

  static Future<bool> loadShowLyricCover() async {
    final pfs = await SharedPreferences.getInstance();
    final show = pfs.getBool("showLyricCover");
    if (show != null) {
      return show;
    }
    return true;
  }

  // 是否开启桌面端窗口置顶
  static Future setWindowAlwaysOnTop(bool onTop) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setBool("windowAlwaysOnTop", onTop);
  }

  static Future<bool> loadWindowAlwaysOnTop() async {
    final pfs = await SharedPreferences.getInstance();
    final onTop = pfs.getBool("windowAlwaysOnTop");
    if (onTop != null) {
      return onTop;
    }
    return false;
  }

  // 播放列表排序方式 (name: 名称, time: 添加时间, random: 随机)
  static Future setPlaylistSortBy(String sortBy) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setString("playlistSortBy", sortBy);
  }

  static Future<String> loadPlaylistSortBy() async {
    final pfs = await SharedPreferences.getInstance();
    final sortBy = pfs.getString("playlistSortBy");
    if (sortBy != null) {
      return sortBy;
    }
    return "time";
  }

  // 音质设置 (low: 低, normal: 标准, high: 高)
  static Future setAudioQuality(String quality) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setString("audioQuality", quality);
  }

  static Future<String> loadAudioQuality() async {
    final pfs = await SharedPreferences.getInstance();
    final quality = pfs.getString("audioQuality");
    if (quality != null) {
      return quality;
    }
    return "normal";
  }

  // 启动时自动播放
  static Future setAutoPlayOnStart(bool autoPlay) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setBool("autoPlayOnStart", autoPlay);
  }

  static Future<bool> loadAutoPlayOnStart() async {
    final pfs = await SharedPreferences.getInstance();
    final autoPlay = pfs.getBool("autoPlayOnStart");
    if (autoPlay != null) {
      return autoPlay;
    }
    return false;
  }

  // 通知栏显示详情
  static Future setShowNotificationDetail(bool show) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setBool("showNotificationDetail", show);
  }

  static Future<bool> loadShowNotificationDetail() async {
    final pfs = await SharedPreferences.getInstance();
    final show = pfs.getBool("showNotificationDetail");
    if (show != null) {
      return show;
    }
    return true;
  }

  // 双击列表项快速播放
  static Future setDoubleTapToPlay(bool enable) async {
    final pfs = await SharedPreferences.getInstance();
    await pfs.setBool("doubleTapToPlay", enable);
  }

  static Future<bool> loadDoubleTapToPlay() async {
    final pfs = await SharedPreferences.getInstance();
    final enable = pfs.getBool("doubleTapToPlay");
    if (enable != null) {
      return enable;
    }
    return true;
  }
}
