import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/constants/Theme/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/SettingsProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> _scanPaths = [];
  bool _isPathsLoading = true;
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _initPaths();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initPaths() async {
    final loadedPaths = await FileService.loadPaths();
    if (mounted) {
      setState(() {
        _scanPaths = loadedPaths;
        _isPathsLoading = false;
      });
    }
  }

  Future<void> _showPickDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FolderPickDialog(
        initialPaths: _scanPaths,
        onPathsChanged: (newPaths) {
          setState(() => _scanPaths = newPaths);
        },
      ),
    );
  }

  static final List<Color> _themeColors = [
    MyTheme.kAppDefaultSeedColor,
    const Color(0xFF39C5BB),
    const Color(0xFF00B0FF),
    const Color(0xFFFF4081),
    const Color(0xFF4CAF50),
    const Color(0xFFFF9800),
    const Color(0xFF795548),
    const Color(0xFF607D8B),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final version = context.select<MusicProvider, String>((p) => p.appVersion);
    final buildNumber = context.select<MusicProvider, String>(
      (p) => p.buildNumber,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("设置")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildSectionHeader(context, "外观"),
              Card.filled(
                child: Column(
                  children: [
                    // ── 主题色 ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.color_lens_outlined,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Text("主题色", style: textTheme.bodyLarge),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _themeColors.map((color) {
                          return _ThemeSeedButton(
                            color: color,
                            isSelected:
                                themeProvider.seedColor.toARGB32() ==
                                color.toARGB32(),
                            onTap: () => themeProvider.setSeedColor(color),
                          );
                        }).toList(),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 主题模式 ──
                    SwitchListTile(
                      secondary: Icon(
                        Icons.dark_mode_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("深色模式"),
                      subtitle: Text(
                        themeProvider.themeMode == ThemeMode.system
                            ? "跟随系统"
                            : themeProvider.themeMode == ThemeMode.dark
                            ? "已开启"
                            : "已关闭",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (v) {
                        themeProvider.setThemeMode(
                          v ? ThemeMode.dark : ThemeMode.light,
                        );
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 列表密度 ──
                    ListTile(
                      leading: Icon(
                        Icons.density_medium_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("列表密度"),
                      subtitle: Text(
                        themeProvider.listDensity == "compact" ? "紧凑" : "舒适",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: "compact", label: Text("紧凑")),
                          ButtonSegment(value: "normal", label: Text("舒适")),
                        ],
                        selected: {themeProvider.listDensity},
                        onSelectionChanged: (Set<String> v) {
                          themeProvider.setListDensity(v.first);
                        },
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 进度条样式 ──
                    ListTile(
                      leading: Icon(
                        Icons.show_chart_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("进度条样式"),
                      subtitle: Text(
                        themeProvider.sliderStyle == SliderStyle.wave
                            ? "波浪形"
                            : "直线形",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: SegmentedButton<SliderStyle>(
                        segments: const [
                          ButtonSegment(
                            value: SliderStyle.straight,
                            icon: Icon(Icons.horizontal_rule_rounded),
                          ),
                          ButtonSegment(
                            value: SliderStyle.wave,
                            icon: Icon(Icons.waves_rounded),
                          ),
                        ],
                        selected: {themeProvider.sliderStyle},
                        onSelectionChanged: (Set<SliderStyle> v) {
                          themeProvider.setSliderStyle(v.first);
                        },
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 应用图标 ──
                    ListTile(
                      leading: Icon(
                        Icons.apps_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("应用图标"),
                      subtitle: Text(
                        _getIconFileName(settingsProvider.appIconPath),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAppIconPicker(context, settingsProvider),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionHeader(context, "播放"),

              Card.filled(
                child: Column(
                  children: [
                    // ── 启动自动播放 ──
                    SwitchListTile(
                      secondary: Icon(
                        Icons.play_circle_outline,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("启动时自动播放"),
                      subtitle: Text(
                        "应用启动后恢复上次播放",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      value: settingsProvider.autoPlayOnStart,
                      onChanged: (v) => settingsProvider.setAutoPlayOnStart(v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 双击播放 ──
                    SwitchListTile(
                      secondary: Icon(
                        Icons.touch_app_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("双击快速播放"),
                      subtitle: Text(
                        "双击列表中的歌曲立即播放",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      value: settingsProvider.doubleTapToPlay,
                      onChanged: (v) => settingsProvider.setDoubleTapToPlay(v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionHeader(context, "显示"),

              Card.filled(
                child: Column(
                  children: [
                    // ── 歌词封面 ──
                    SwitchListTile(
                      secondary: Icon(
                        Icons.album_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("显示专辑封面"),
                      subtitle: Text(
                        "播放页面展示专辑封面图",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      value: settingsProvider.showLyricCover,
                      onChanged: (v) => settingsProvider.setShowLyricCover(v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 通知栏详情 ──
                    SwitchListTile(
                      secondary: Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("通知栏显示详情"),
                      subtitle: Text(
                        "通知栏展示歌曲名与封面",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      value: settingsProvider.showNotificationDetail,
                      onChanged: (v) =>
                          settingsProvider.setShowNotificationDetail(v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionHeader(context, "数据"),

              Card.filled(
                child: Column(
                  children: [
                    // ── 扫描目录 ──
                    _buildScanDirectoriesTile(context),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 最大历史记录 ──
                    ListTile(
                      leading: Icon(
                        Icons.history_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("历史记录上限"),
                      subtitle: Text(
                        "最多保留 ${settingsProvider.maxHistoryCount} 条",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: DropdownButton<int>(
                        value: settingsProvider.maxHistoryCount,
                        items: const [
                          DropdownMenuItem(value: 50, child: Text("50")),
                          DropdownMenuItem(value: 100, child: Text("100")),
                          DropdownMenuItem(value: 300, child: Text("300")),
                          DropdownMenuItem(value: 500, child: Text("500")),
                        ],
                        onChanged: (v) {
                          if (v != null) settingsProvider.setMaxHistoryCount(v);
                        },
                        underline: Container(),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 清除缓存 ──
                    ListTile(
                      leading: Icon(
                        Icons.cleaning_services_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("清除缓存"),
                      subtitle: Text(
                        "清除专辑封面、歌词等临时文件",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => _showClearCacheDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionHeader(context, "关于"),

              Card.filled(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("软件版本"),
                      trailing: Text(
                        "$version ($buildNumber)",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      onTap: () => context.pushNamed('about'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      title: const Text("开源许可"),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => showLicensePage(context: context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  /// 清除缓存对话框
  Future<void> _showClearCacheDialog(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("清除缓存"),
        content: const Text("将清除专辑封面、歌词等临时缓存文件，不会影响您的音乐库和播放列表。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("确定清除"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final tmpDir = await getTemporaryDirectory();
      if (await tmpDir.exists()) {
        await tmpDir.delete(recursive: true);
      }
      final cacheDir = await getApplicationCacheDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list(recursive: true)) {
          if (entity is File) {
            try {
              await entity.delete();
            } catch (_) {}
          }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("缓存已清除"),
            backgroundColor: cs.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("清除失败: $e"),
            backgroundColor: cs.error,
          ),
        );
      }
    }
  }

  /// 扫描目录设置项 — 内联于父级 Card，与其它设置项风格统一
  Widget _buildScanDirectoriesTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 扫描目录标题行（仿 ListTile 但适配宽屏和窄屏） ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.folder_copy_rounded,
                  size: 22,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "音乐扫描目录",
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _isPathsLoading
                            ? "加载中…"
                            : _scanPaths.isEmpty
                            ? "未添加任何目录"
                            : "${_scanPaths.length} 个目录",
                        key: ValueKey("${_isPathsLoading}_${_scanPaths.length}"),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: _isPathsLoading ? null : _showPickDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("管理"),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 已添加目录 chips ──
        if (!_isPathsLoading && _scanPaths.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(68, 2, 16, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: _scanPaths.map((path) {
                final folderName = path
                    .split(Platform.pathSeparator)
                    .lastWhere((e) => e.isNotEmpty, orElse: () => path);
                return InputChip(
                  avatar: Icon(Icons.folder_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                  label: Text(folderName, style: textTheme.bodySmall),
                  deleteIcon: Icon(Icons.close, size: 16, color: colorScheme.onSurfaceVariant),
                  onDeleted: () {
                    setState(() => _scanPaths.remove(path));
                    FileService.savePaths(_scanPaths);
                  },
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  tooltip: path,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getIconFileName(String path) {
    final name = path
        .split('/')
        .last
        .replaceAll(RegExp(r'\.(png|jpeg|jpg)$'), '');
    return name.replaceAll('app_icon', '风格 ').trim();
  }

  void _showAppIconPicker(BuildContext context, SettingsProvider settingsProvider) {
    final List<String> iconPaths = [
      MyAssets.app_icon,
      MyAssets.app_icon1,
      MyAssets.app_icon2,
      MyAssets.app_icon3,
      MyAssets.app_icon4,
      MyAssets.app_icon5,
      MyAssets.app_icon6,
      MyAssets.app_icon7,
      MyAssets.app_icon8,
      MyAssets.app_icon9,
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _AppIconPickerSheet(
          iconPaths: iconPaths,
          currentIconPath: settingsProvider.appIconPath,
          onConfirm: (selectedPath) {
            settingsProvider.setAppIconPath(selectedPath);
            Navigator.of(sheetContext).pop();
          },
          onCancel: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 目录选择弹窗（已统一风格）
// ────────────────────────────────────────────────────────────────────────────
class _FolderPickDialog extends StatefulWidget {
  final List<String> initialPaths;
  final ValueChanged<List<String>> onPathsChanged;

  const _FolderPickDialog({
    required this.initialPaths,
    required this.onPathsChanged,
  });

  @override
  State<_FolderPickDialog> createState() => _FolderPickDialogState();
}

class _FolderPickDialogState extends State<_FolderPickDialog> {
  late List<String> _tmpPaths;
  bool _isScanning = false;
  int _scannedCount = 0;
  int _foundCount = 0;
  String? _error;
  StreamSubscription? _scanSub;
  final List<Music> _scannedSongs = [];
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _tmpPaths = [...widget.initialPaths];
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  void _deletePath(int index) {
    setState(() => _tmpPaths.removeAt(index));
  }

  Future<void> _startScan() async {
    if (_tmpPaths.isEmpty) return;
    if (Platform.isAndroid &&
        !(await MusicService.ensureAndroidAudioPermission())) {
      if (mounted) {
        setState(() => _error = '请授予存储和音频权限以扫描音乐');
      }
      return;
    }
    if (!mounted) return;

    setState(() {
      _isScanning = true;
      _scannedCount = 0;
      _foundCount = 0;
      _scannedSongs.clear();
      _error = null;
      _hasScanned = false;
    });

    _scanSub?.cancel();
    _scanSub = MusicService.scanDirectories(_tmpPaths).listen(
      (progress) {
        if (!mounted) return;
        if (progress.music != null) {
          _scannedSongs.add(progress.music!);
        }
        setState(() {
          _scannedCount++;
          _foundCount = _scannedSongs.length;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isScanning = false;
          _hasScanned = true;
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isScanning = false;
          _error = '扫描出错: $err';
        });
      },
    );
  }

  void _handleConfirm() {
    FileService.savePaths(_tmpPaths);
    widget.onPathsChanged(_tmpPaths);
    if (_scannedSongs.isNotEmpty) {
      context.read<MusicProvider>().updateLibrary(List.from(_scannedSongs));
    }
    Navigator.pop(context);
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      title: Row(
        children: [
          Icon(Icons.folder_special_rounded, color: colorScheme.primary),
          const SizedBox(width: 10),
          const Text("管理扫描目录"),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.88,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 添加目录按钮
              FilledButton.tonalIcon(
                onPressed: _isScanning
                    ? null
                    : () async {
                        final selectedPath =
                            await FilePicker.getDirectoryPath();
                        if (selectedPath != null && mounted) {
                          setState(() {
                            _tmpPaths.add(selectedPath);
                            _hasScanned = false;
                          });
                        }
                      },
                icon: const Icon(Icons.add_rounded),
                label: const Text("添加新扫描目录"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 目录列表
              Container(
                constraints: const BoxConstraints(maxHeight: 260),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.6,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: _tmpPaths.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_off_rounded,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "暂无扫描目录\n点击上方按钮添加",
                              textAlign: TextAlign.center,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: _tmpPaths.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (context, index) {
                          final path = _tmpPaths[index];
                          final folderName = path
                              .split(Platform.pathSeparator)
                              .last;
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: Icon(
                              Icons.folder_rounded,
                              color: colorScheme.primary,
                            ),
                            title: Text(
                              folderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                            trailing: _isScanning
                                ? null
                                : IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: colorScheme.error,
                                    ),
                                    onPressed: () => _deletePath(index),
                                  ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // 扫描状态区域
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    if (_isScanning) ...[
                      _buildScanningStatus(colorScheme, textTheme),
                    ] else if (_tmpPaths.isNotEmpty && !_hasScanned) ...[
                      FilledButton.icon(
                        onPressed: _startScan,
                        icon: const Icon(Icons.youtube_searched_for_rounded),
                        label: const Text("开始扫描歌曲"),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                    if (!_isScanning && _hasScanned)
                      _buildScanSuccess(colorScheme, textTheme),
                    if (_error != null)
                      _buildErrorMessage(colorScheme, textTheme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isScanning ? null : _handleCancel,
          child: const Text("取消"),
        ),
        FilledButton(
          onPressed: _isScanning ? null : _handleConfirm,
          child: Text(_hasScanned ? "完成" : "确定"),
        ),
      ],
    );
  }

  Widget _buildScanningStatus(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const LinearProgressIndicator(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 12),
              Text("正在扫描…", style: tt.titleSmall?.copyWith(color: cs.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "已检查 $_scannedCount 个文件 · 找到 $_foundCount 首音乐",
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildScanSuccess(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: cs.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "扫描完成",
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  "成功导入 $_foundCount 首歌曲",
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: tt.bodyMedium?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 应用图标选择器
// ────────────────────────────────────────────────────────────────────────────

class _AppIconPickerSheet extends StatefulWidget {
  final List<String> iconPaths;
  final String currentIconPath;
  final ValueChanged<String> onConfirm;
  final VoidCallback onCancel;

  const _AppIconPickerSheet({
    required this.iconPaths,
    required this.currentIconPath,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_AppIconPickerSheet> createState() => _AppIconPickerSheetState();
}

class _AppIconPickerSheetState extends State<_AppIconPickerSheet> {
  late String _selectedPath;

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.currentIconPath;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              "选择应用图标",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.iconPaths.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final path = widget.iconPaths[index];
                final isSelected = _selectedPath == path;
                final fileName = path.split('/').last;
                final displayName = fileName
                    .replaceAll(RegExp(r'\.(png|jpeg|jpg)$'), '')
                    .replaceAll('app_icon', '')
                    .trim();

                return GestureDetector(
                  onTap: () => setState(() => _selectedPath = path),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 76,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            path,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.broken_image_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName.isEmpty ? "默认" : displayName,
                          style: textTheme.labelSmall?.copyWith(
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text("取消"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => widget.onConfirm(_selectedPath),
                  child: const Text("确定"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// 主题色块
// ────────────────────────────────────────────────────────────────────────────

class _ThemeSeedButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeSeedButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final checkIconColor = color.computeLuminance() > 0.5
        ? cs.inverseSurface
        : cs.onInverseSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isSelected ? 16 : 28),
          border: isSelected
              ? Border.all(
                  color: cs.primaryContainer,
                  width: 4,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: isSelected
            ? Icon(Icons.check_rounded, color: checkIconColor)
            : null,
      ),
    );
  }
}
