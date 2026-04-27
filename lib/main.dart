import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:myapp/router/IndexRouter/index.dart';
import 'package:myapp/service/Settings/index.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  //确保与原生层通信准备就绪flu
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows) {
    JustAudioMediaKit.ensureInitialized(
      linux: true, // default: true  - dependency: media_kit_libs_linux
      windows:
          false, // default: true  - dependency: media_kit_libs_windows_audio
      // android: true, // default: false - dependency: media_kit_libs_android_audio
      // iOS: true, // default: false - dependency: media_kit_libs_ios_audio
      // macOS: true, // default: false - dependency: media_kit_libs_macos_audio
    );
  }

  // 预加载配置
  final initialColor = await SettingService.loadColor();
  final initialThemeMode = await SettingService.loadThemeMode();

  runApp(
    MultiProvider(
      providers: [
        //注册主题Provider
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(
            initialColor: initialColor,
            initialMode: initialThemeMode,
          ),
        ),
        //注册全局音乐播放器Provider
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        //注册用户Provider
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const IndexRouter(),
    ),
  );
}
