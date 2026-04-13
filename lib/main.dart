import 'package:flutter/material.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/router/IndexRouter/index.dart';
import 'package:myapp/service/Settings/index.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  //确保与原生层通信准备就绪
  WidgetsFlutterBinding.ensureInitialized();

  // 预加载配置
  final initialColor = await SettingService.loadColor();
  final initialThemeMode = await SettingService.loadThemeMode();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(
        initialColor: initialColor,
        initialMode: initialThemeMode,
        
      ),
      child: const IndexRouter(),
    ),
  );
}
