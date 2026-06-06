import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/service/MusicDb/index.dart';
import 'package:myapp/service/Settings/index.dart';
import 'package:myapp/src/rust/frb_generated.dart';
import 'package:window_manager/window_manager.dart';

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
    // 先通电，把 Flutter 底层环境和原生通道拉起来
    WidgetsFlutterBinding.ensureInitialized();

    // 避免在无 TLS/无外网时从 gstatic 拉字体导致启动崩溃
    GoogleFonts.config.allowRuntimeFetching = false;

    // 环境好了，放心初始化 Rust 库和本地配置
    if (!kIsWeb) {
      await RustLib.init();
    }

    // 本地sqlite初始化
    await MusicDbService().init();

    // 加载环境变量
   String fileName = kReleaseMode ? ".env.production" : ".env.development";
    try {
      await dotenv.load(fileName: fileName);
      debugPrint("自动选择并加载环境: $fileName");
    } catch (e) {
      debugPrint("Warning: Could not load $fileName file.");
    }

    try {
      JustAudioMediaKit.ensureInitialized(
        android: false,
        iOS: false,
        windows: Platform.isWindows,
        linux: Platform.isLinux,
        macOS: Platform.isMacOS,
      );
      debugPrint("JustAudioMediaKit 初始化成功");
    } catch (e, stackTrace) {
      // 就算报错了，也只是打印出来，不破坏整个主流程
      debugPrint("❌ JustAudioMediaKit 初始化失败: $e");
      debugPrint("堆栈信息: $stackTrace");
    }

    //初始化窗口管理器
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.ensureInitialized();
      final windowOptions = const WindowOptions(
        size: Size(800, 600),
        center: true,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );

      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  /// 2. 异步业务数据加载
  static Future<Map<String, dynamic>> loadInitialSettings() async {
    // 聚合所有 SettingService 的加载调用
    final results = await Future.wait([
      SettingService.loadColor(),
      SettingService.loadThemeMode(),
      SettingService.loadSliderStyle(),
      SettingService.loadListDensity(),
      SettingService.loadAudioQuality(),
      SettingService.loadShowLyricCover(),
      SettingService.loadAutoPlayOnStart(),
      SettingService.loadShowNotificationDetail(),
      SettingService.loadDoubleTapToPlay(),
      SettingService.loadPlaylistSortBy(),
      SettingService.loadMaxHistoryCount(),
      SettingService.loadAppIcon(),
    ]);

    return {
      'seedColor': results[0],
      'themeMode': results[1],
      "sliderStyle": results[2],
      'listDensity': results[3],
      'audioQuality': results[4],
      'showLyricCover': results[5],
      'autoPlayOnStart': results[6],
      'showNotificationDetail': results[7],
      'doubleTapToPlay': results[8],
      'playlistSortBy': results[9],
      'maxHistoryCount': results[10],
      'appIconPath': results[11],
    };
  }

  static Future<List<Music>> scanInitialMusic({
    void Function(StartupScanProgress progress)? onProgress,
  }) async {
    final List<Music> fetchedLibrary = [];
    final paths = await FileService.loadPaths();
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final hasSelectedPaths = paths.isNotEmpty;

    onProgress?.call(
      StartupScanProgress(
        module: '读取本地目录',
        detail: isAndroid && hasSelectedPaths
            ? 'Android 使用已保存目录扫描音频'
            : isAndroid
            ? 'Android 使用系统媒体库扫描音频'
            : paths.isEmpty
            ? '没有已保存的音乐目录'
            : '已读取 ${paths.length} 个目录',
      ),
    );

    if (!isAndroid && paths.isEmpty) return [];

    // 使用 await for 等待扫描流完成（这可能会让启动页停留稍久，但能保证数据完整）
    var scannedCount = 0;
    final scanProgressStream = MusicService.scanDirectories(paths);

    await for (final s in scanProgressStream) {
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
