import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/NavProvider/index.dart';
import 'package:myapp/providers/StartupProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:myapp/router/IndexRouter/index.dart';
import 'package:myapp/service/Initialization/index.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  await InitializationService.preRunInit();

  await dotenv.load(fileName: ".env");

  //初始化窗口管理器
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    final windowOptions = const WindowOptions(
      size: Size(800, 600),
      center: true,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => StartupProvider()),
      ],
      child: const IndexRouter(),
    ),
  );
}
