
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/NavProvider/index.dart';
import 'package:myapp/providers/StartupProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:myapp/router/IndexRouter/index.dart';
import 'package:myapp/service/Audio/index.dart';
import 'package:myapp/service/Initialization/index.dart';
import 'package:provider/provider.dart';

late MyAudioHandler globalAudioHandler; // 定义全局句柄
Future<void> main() async {
  await InitializationService.preRunInit();

  globalAudioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.myapp.audio',
      androidNotificationChannelName: 'M3Music 播放控制',
      // 设置为 true，防止用户在播放时手动右滑误删通知栏
      androidNotificationOngoing: true,
      androidShowNotificationBadge: true,
  
      androidStopForegroundOnPause: true,  //左滑停止
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MusicProvider(audioHandler: globalAudioHandler)),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => StartupProvider()),
      ],
      child: const IndexRouter(),
    ),
  );
}
