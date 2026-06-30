import 'package:flutter/material.dart';

import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/providers/SettingsProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/service/AppIcon/index.dart';
import 'package:myapp/service/Initialization/index.dart';

enum StartupStatus { idle, running, completed, failed }

class StartupProvider extends ChangeNotifier {
  StartupStatus _status = StartupStatus.idle;
  String _currentModule = '准备启动';
  String _currentDetail = '等待初始化';
  String? _errorMessage;
  int _completedSteps = 0;

  static const int _totalSteps = 4;

  StartupStatus get status => _status;
  String get currentModule => _currentModule;
  String get currentDetail => _currentDetail;
  String? get errorMessage => _errorMessage;
  int get completedSteps => _completedSteps;
  int get totalSteps => _totalSteps;
  double get progress => _completedSteps / _totalSteps;
  bool get isRunning => _status == StartupStatus.running;
  bool get isCompleted => _status == StartupStatus.completed;

  Future<void> run({
    required ThemeProvider themeProvider,
    required SettingsProvider settingsProvider,
    required MusicProvider musicProvider,
    required PlaylistProvider playlistProvider,
  }) async {
    if (_status == StartupStatus.running ||
        _status == StartupStatus.completed) {
      return;
    }

    _status = StartupStatus.running;
    _errorMessage = null;
    _completedSteps = 0;
    _setStage('加载界面设置', '正在读取主题与偏好配置');

    try {
      final settings = await InitializationService.loadInitialSettings();
      themeProvider.updateFromMap(settings);
      settingsProvider.updateFromMap(settings);
      await AppIconService.switchAppIcon(settingsProvider.appIconPath);

      _finishStep('加载界面设置', '主题设置已应用');

      _setStage('扫描本地音乐', '正在读取已保存目录');
      final songs = await InitializationService.scanInitialMusic(
        onProgress: (progress) {
          _setStage(progress.module, _formatScanDetail(progress));
        },
      );
      _finishStep('扫描本地音乐', '已载入 ${songs.length} 首歌曲');

      _setStage('恢复播放器状态', '正在恢复播放数据');
      await musicProvider.bootstrap(
        scannedSongs: songs,
        onProgress: (module, detail) => _setStage(module, detail),
      );

      await playlistProvider.bootstrap(
        onProgress: (module, detail) => _setStage(module, detail),
        currentLibrary: songs,
        musicProvider: musicProvider,
      );
      _finishStep('恢复播放器状态', '播放器状态恢复完成');

      _status = StartupStatus.completed;
      _finishStep('启动完成', '正在进入首页');
    } catch (e) {
      _status = StartupStatus.failed;
      _errorMessage = e.toString();
      _setStage('启动失败', '请检查日志或稍后重试');
    }
  }

  void _finishStep(String module, String detail) {
    _completedSteps++;
    _currentModule = module;
    _currentDetail = detail;
    notifyListeners();
  }

  void _setStage(String module, String detail) {
    _currentModule = module;
    _currentDetail = detail;
    notifyListeners();
  }

  String _formatScanDetail(StartupScanProgress progress) {
    final currentTarget = progress.detail.split(RegExp(r'[/\\]')).last;

    if (progress.foundCount == 0) {
      return currentTarget.isEmpty
          ? '已扫描 ${progress.scannedCount} 项'
          : '正在处理 $currentTarget，已扫描 ${progress.scannedCount} 项';
    }

    return currentTarget.isEmpty
        ? '已扫描 ${progress.scannedCount} 项，发现 ${progress.foundCount} 首歌曲'
        : '正在处理 $currentTarget，已发现 ${progress.foundCount} 首歌曲';
  }
}
