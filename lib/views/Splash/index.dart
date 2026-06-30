import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/providers/SettingsProvider/index.dart';
import 'package:myapp/providers/StartupProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/providers/UserProvider/index.dart';
import 'package:myapp/router/Extensions/router.dart';
import 'package:myapp/service/AppIcon/index.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  String _splashIconPath = AppIconService.defaultIconPath;

  @override
  void initState() {
    super.initState();
    _loadSplashIcon();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _startInitialization();
  }

  Future<void> _loadSplashIcon() async {
    final path = await AppIconService.getCurrentAppIconPath();
    if (mounted) {
      setState(() => _splashIconPath = path);
    }
  }

  Future<void> _startInitialization() async {
    final stopwatch = Stopwatch()..start();
    var startupSucceeded = false;
    final startupProvider = context.read<StartupProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final musicProvider = context.read<MusicProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    musicProvider.onMusicPlayed = (song) {
      playlistProvider.addToHistory(song, settingsProvider.maxHistoryCount, musicProvider: musicProvider);
    };

    final pfs = await SharedPreferences.getInstance();
    final bool isFirstRun = pfs.getBool("is_first_run") ?? true;

    try {
      // 尝试恢复登录状态（从本地加密存储）
      final userProvider = context.read<UserProvider>();
      await userProvider.tryAutoLogin();

      // Load persisted network songs so history/favorites survive restarts
      await musicProvider.loadPersistedNetworkSongs();

      await startupProvider.run(
        themeProvider: themeProvider,
        settingsProvider: settingsProvider,
        musicProvider: musicProvider,
        playlistProvider: playlistProvider,
      );
      await _loadSplashIcon();
      startupSucceeded = startupProvider.status == StartupStatus.completed;
    } catch (e) {
      debugPrint("初始化失败: $e");
    }

    final remaining = 1800 - stopwatch.elapsedMilliseconds;
    if (remaining > 0) await Future.delayed(Duration(milliseconds: remaining));
    if (!mounted) return;

    if (!startupSucceeded && mounted) {
      AppToast.error(
        context,
        message: startupProvider.errorMessage ?? '初始化失败，请重试',
        title: '启动错误',
      );
    }

    if (startupSucceeded) {
      if (!Platform.isAndroid) {
        context.toHome();
        return;
      }
      if (isFirstRun) {
        context.go("/setup");
      } else {
        context.go("/home");
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Consumer<StartupProvider>(
      builder: (context, startup, _) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Image.asset(
                      _splashIconPath,
                      width: 108,
                      height: 108,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Image.asset(
                        MyAssets.app_icon,
                        width: 108,
                        height: 108,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'M3Music',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        startup.currentModule,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          startup.errorMessage ?? startup.currentDetail,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: LinearProgressIndicator(
                          value: startup.completedSteps == 0
                              ? null
                              : startup.progress,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${startup.completedSteps}/${startup.totalSteps}',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (startup.status == StartupStatus.failed) ...[
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: _startInitialization,
                          child: const Text('重试启动'),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 64),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: startup.status == StartupStatus.failed
                        ? Icon(
                            Icons.error_outline_rounded,
                            size: 30,
                            color: colorScheme.error,
                          )
                        : SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              strokeCap: StrokeCap.round,
                              color: colorScheme.primary,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
