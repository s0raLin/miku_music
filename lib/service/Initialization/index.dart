import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/service/Settings/index.dart';

class StartupScanProgress {
  final String module;
  final String detail;
  final int scannedCount;
  final int foundCount;

  const StartupScanProgress({
    required this.module,
    required this.detail,
    this.scannedCount = 0,
    this.foundCount = 0,
  });
}

class InitializationService {
  // 1. 启动前的硬性初始化
  static Future<void> preRunInit() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!kIsWeb && Platform.isLinux || Platform.isWindows) {
      JustAudioMediaKit.ensureInitialized(
        linux: true,
        windows: false,
        android: true,
      );
    }
  }

  /// 2. 异步业务数据加载
  static Future<Map<String, dynamic>> loadInitialSettings() async {
    // 聚合所有 SettingService 的加载调用
    final results = await Future.wait([
      SettingService.loadColor(),
      SettingService.loadThemeMode(),
      SettingService.loadListDensity(),
      SettingService.loadAudioQuality(),
      SettingService.loadShowLyricCover(),
      SettingService.loadAutoPlayOnStart(),
      SettingService.loadShowNotificationDetail(),
      SettingService.loadDoubleTapToPlay(),
      SettingService.loadPlaylistSortBy(),
      SettingService.loadMaxHistoryCount(),
    ]);

    return {
      'seedColor': results[0],
      'themeMode': results[1],
      'listDensity': results[2],
      'audioQuality': results[3],
      'showLyricCover': results[4],
      'autoPlayOnStart': results[5],
      'showNotificationDetail': results[6],
      'doubleTapToPlay': results[7],
      'playlistSortBy': results[8],
      'maxHistoryCount': results[9],
    };
  }

  static Future<List<MusicInfo>> scanInitialMusic({
    void Function(StartupScanProgress progress)? onProgress,
  }) async {
    final List<MusicInfo> fetchedLibrary = [];
    final paths = await FileService.loadPaths();

    onProgress?.call(
      StartupScanProgress(
        module: '读取本地目录',
        detail: paths.isEmpty ? '没有已保存的音乐目录' : '已读取 ${paths.length} 个目录',
      ),
    );

    if (paths.isEmpty) return [];

    // 使用 await for 等待扫描流完成（这可能会让启动页停留稍久，但能保证数据完整）
    var scannedCount = 0;
    await for (final s in MusicService.scanDirectories(paths)) {
      scannedCount++;

      if (s.music != null) {
        fetchedLibrary.add(s.music!);
      }

      onProgress?.call(
        StartupScanProgress(
          module: '扫描本地音乐库',
          detail: s.currentPath,
          scannedCount: scannedCount,
          foundCount: fetchedLibrary.length,
        ),
      );
    }
    return fetchedLibrary;
  }
}
