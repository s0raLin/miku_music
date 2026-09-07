import 'dart:async';
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
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  String _splashIconPath = AppIconService.defaultIconPath;

  @override
  void initState() {
    super.initState();
    _initAnimation();
    _startInitializationSequence();
  }

  void _initAnimation() {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  Future<void> _loadSplashIcon() async {
    try {
      final path = await AppIconService.getCurrentAppIconPath();
      if (mounted) {
        setState(() => _splashIconPath = path);
      }
    } catch (e) {
      debugPrint("获取启动页图标失败: $e");
    }
  }

  Future<void> _startInitializationSequence() async {
    final stopwatch = Stopwatch()..start();

    // 加载页面图标与准备各项 Provider
    unawaited(_loadSplashIcon());

    final startupProvider = context.read<StartupProvider>();
    final themeProvider = context.read<ThemeProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final musicProvider = context.read<MusicProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    final userProvider = context.read<UserProvider>();

    // 绑定播放历史监听
    musicProvider.onMusicPlayed = (song) {
      playlistProvider.addToHistory(
        song,
        settingsProvider.maxHistoryCount,
        musicProvider: musicProvider,
      );
    };

    var startupSucceeded = false;

    try {
      // 1. 登录与持久化歌曲数据同步恢复
      await Future.wait([
        userProvider.tryAutoLogin().catchError((e) {
          debugPrint("自动登录失败: $e");
        }),
        musicProvider.loadPersistedNetworkSongs().catchError((e) {
          debugPrint("加载本地持久化歌曲失败: $e");
        }),
      ]);

      // 2. 核心初始化服务
      await startupProvider.run(
        themeProvider: themeProvider,
        settingsProvider: settingsProvider,
        musicProvider: musicProvider,
        playlistProvider: playlistProvider,
      );

      startupSucceeded = startupProvider.status == StartupStatus.completed;
    } catch (e, stack) {
      debugPrint("启动过程发生严重未捕获异常: $e\n$stack");
    }

    // 保证 Splash 最少展示时间（如 1.2 秒），避免闪烁
    final remainingMs = 1200 - stopwatch.elapsedMilliseconds;
    if (remainingMs > 0) {
      await Future.delayed(Duration(milliseconds: remainingMs));
    }

    if (!mounted) return;

    if (!startupSucceeded) {
      AppToast.error(
        context,
        message: startupProvider.errorMessage ?? '初始化失败，请重试',
        title: '启动错误',
      );
      return;
    }

    // 路由跳转判定
    final prefs = await SharedPreferences.getInstance();
    final isFirstRun = prefs.getBool("is_first_run") ?? true;

    if (!mounted) return;

    if (Platform.isAndroid && isFirstRun) {
      context.go("/setup");
    } else {
      context.go("/home");
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<StartupProvider>(
      builder: (context, startup, _) {
        final isFailed = startup.status == StartupStatus.failed;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // 1. App Icon & Title
                _BrandHeader(
                  fadeAnimation: _fadeAnimation,
                  scaleAnimation: _scaleAnimation,
                  iconPath: _splashIconPath,
                ),

                const SizedBox(height: 32),

                // 2. 初始化进度与状态展示
                _ProgressSection(
                  fadeAnimation: _fadeAnimation,
                  startup: startup,
                  onRetry: _startInitializationSequence,
                ),

                const Spacer(flex: 2),

                // 3. 底部 Loader 或 Error 图标
                _BottomIndicator(
                  fadeAnimation: _fadeAnimation,
                  isFailed: isFailed,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== 私有子组件 ====================

class _BrandHeader extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final Animation<double> scaleAnimation;
  final String iconPath;

  const _BrandHeader({
    required this.fadeAnimation,
    required this.scaleAnimation,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: scaleAnimation,
            child: Image.asset(
              iconPath,
              width: 96,
              height: 96,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                MyAssets.app_icon,
                width: 96,
                height: 96,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'M3Music',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final StartupProvider startup;
  final VoidCallback onRetry;

  const _ProgressSection({
    required this.fadeAnimation,
    required this.startup,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isFailed = startup.status == StartupStatus.failed;

    return FadeTransition(
      opacity: fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            startup.currentModule,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              startup.errorMessage ?? startup.currentDetail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isFailed
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: LinearProgressIndicator(
              value: startup.completedSteps == 0 ? null : startup.progress,
              minHeight: 4,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${startup.completedSteps}/${startup.totalSteps}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (isFailed) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试启动'),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomIndicator extends StatelessWidget {
  final Animation<double> fadeAnimation;
  final bool isFailed;

  const _BottomIndicator({required this.fadeAnimation, required this.isFailed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: fadeAnimation,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isFailed
            ? Icon(
                Icons.error_outline_rounded,
                key: const ValueKey('error_icon'),
                size: 28,
                color: colorScheme.error,
              )
            : SizedBox(
                key: const ValueKey('loading_indicator'),
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  strokeCap: StrokeCap.round,
                  color: colorScheme.primary,
                ),
              ),
      ),
    );
  }
}
