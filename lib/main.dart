import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/NavProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/providers/StartupProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:myapp/router/IndexRouter/index.dart';
import 'package:myapp/service/Audio/index.dart';
import 'package:myapp/service/Initialization/index.dart';
import 'package:myapp/service/Tray/index.dart';
import 'package:provider/provider.dart';

late MyAudioHandler globalAudioHandler; // 定义全局句柄

Future<void> main() async {
  await InitializationService.preRunInit();

  globalAudioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.m3music.audio',
      androidNotificationChannelName: 'M3Music 播放控制',
      androidNotificationOngoing: true, // 防止误滑动删除
      androidShowNotificationBadge: true, //暂停时降低优先级(变为普通通知)
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        // 先注入 MusicProvider，因为下面的 PlaylistProvider 需要依赖它
        ChangeNotifierProvider(
          create: (_) => MusicProvider(audioHandler: globalAudioHandler),
        ),
        ChangeNotifierProxyProvider<MusicProvider, PlaylistProvider>(
          create: (_) => PlaylistProvider(),
          update: (context, musicProvider, playlistProvider) {
            if (playlistProvider == null) return PlaylistProvider();
            // 拿到当前内存中真实存在的本地歌曲 ID 集合
            final localSongIds = musicProvider.library.map((s) => s.id).toSet();
            // 反应式通知：本地乐库一变，歌单展示数量立刻计算并刷新
            return playlistProvider..updateActivePlaylists(localSongIds);
          },
        ),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => StartupProvider()),
      ],
      child: const IndexRouter(),
    ),
  );

  try {
    await AppTrayManager().init();
  } catch (e) {
    debugPrint('托盘初始化失败: $e');
  }
}
