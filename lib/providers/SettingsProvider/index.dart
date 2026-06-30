import 'package:flutter/material.dart';
import 'package:myapp/service/AppIcon/index.dart';
import 'package:myapp/service/Settings/index.dart';

/// Pure configuration settings not related to theming.
/// Extracted from ThemeProvider to respect single responsibility.
class SettingsProvider extends ChangeNotifier {
  String _audioQuality = "normal";
  bool _showLyricCover = true;
  bool _autoPlayOnStart = false;
  bool _showNotificationDetail = true;
  bool _doubleTapToPlay = true;
  String _playlistSortBy = "time";
  int _maxHistoryCount = 100;
  String _appIconPath = "assets/app_icon/app_icon1.png";

  SettingsProvider();

  // ── Getters ───────────────────────────────────────────────────────────────
  String get audioQuality => _audioQuality;
  bool get showLyricCover => _showLyricCover;
  bool get autoPlayOnStart => _autoPlayOnStart;
  bool get showNotificationDetail => _showNotificationDetail;
  bool get doubleTapToPlay => _doubleTapToPlay;
  String get playlistSortBy => _playlistSortBy;
  int get maxHistoryCount => _maxHistoryCount;
  String get appIconPath => _appIconPath;

  // ── Batch update (from InitializationService) ─────────────────────────────
  void updateFromMap(Map<String, dynamic> data) {
    _audioQuality = data['audioQuality'] ?? _audioQuality;
    _showLyricCover = data['showLyricCover'] ?? _showLyricCover;
    _autoPlayOnStart = data['autoPlayOnStart'] ?? _autoPlayOnStart;
    _showNotificationDetail =
        data['showNotificationDetail'] ?? _showNotificationDetail;
    _doubleTapToPlay = data['doubleTapToPlay'] ?? _doubleTapToPlay;
    _playlistSortBy = data['playlistSortBy'] ?? _playlistSortBy;
    _maxHistoryCount = data['maxHistoryCount'] ?? _maxHistoryCount;
    _appIconPath = data['appIconPath'] ?? _appIconPath;

    notifyListeners();
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  void setAudioQuality(String v) {
    _audioQuality = v;
    notifyListeners();
    SettingService.setAudioQuality(v);
  }

  void setShowLyricCover(bool v) {
    _showLyricCover = v;
    notifyListeners();
    SettingService.setShowLyricCover(v);
  }

  void setAutoPlayOnStart(bool v) {
    _autoPlayOnStart = v;
    notifyListeners();
    SettingService.setAutoPlayOnStart(v);
  }

  void setShowNotificationDetail(bool v) {
    _showNotificationDetail = v;
    notifyListeners();
    SettingService.setShowNotificationDetail(v);
  }

  void setDoubleTapToPlay(bool v) {
    _doubleTapToPlay = v;
    notifyListeners();
    SettingService.setDoubleTapToPlay(v);
  }

  void setPlaylistSortBy(String v) {
    _playlistSortBy = v;
    notifyListeners();
    SettingService.setPlaylistSortBy(v);
  }

  void setMaxHistoryCount(int v) {
    _maxHistoryCount = v;
    notifyListeners();
    SettingService.setMaxHistoryCount(v);
  }

  void setAppIconPath(String v) {
    _appIconPath = v;
    notifyListeners();
    SettingService.setAppIcon(v);
    AppIconService.switchAppIcon(v);
  }
}
