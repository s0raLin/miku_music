import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/SettingsProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/views/Settings/widgets/app_icon_picker_sheet.dart';
import 'package:myapp/views/Settings/widgets/folder_pick_dialog.dart';
import 'package:myapp/views/Settings/widgets/scan_directories_tile.dart';
import 'package:myapp/views/Settings/widgets/theme_color_picker.dart';
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

  @override
  void initState() {
    super.initState();
    _initPaths();
  }

  Future<void> _initPaths() async {
    final paths = await FileService.loadPaths();
    if (mounted) setState(() { _scanPaths = paths; _isPathsLoading = false; });
  }

  Future<void> _showPickDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => FolderPickDialog(
        initialPaths: _scanPaths,
        onPathsChanged: (p) => setState(() => _scanPaths = p),
      ),
    );
  }

  /// ── M3 SettingsPage — thin orchestrator ──────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final sp = context.watch<SettingsProvider>();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final ver = context.select<MusicProvider, String>((p) => p.appVersion);
    final bld = context.select<MusicProvider, String>((p) => p.buildNumber);

    return Scaffold(
      appBar: AppBar(title: const Text("设置")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ── 外观 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "外观"),
              Card.filled(
                child: Column(children: [
                  ThemeColorPicker(
                    selectedColor: tp.seedColor,
                    onColorSelected: (c) => tp.setSeedColor(c),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    secondary: _icon(Icons.dark_mode_outlined),
                    title: const Text("深色模式"),
                    subtitle: Text(
                      tp.themeMode == ThemeMode.system ? "跟随系统"
                          : tp.themeMode == ThemeMode.dark ? "已开启" : "已关闭",
                      style: tt.bodySmall?.copyWith(color: cs.outline),
                    ),
                    value: tp.themeMode == ThemeMode.dark,
                    onChanged: (v) => tp.setThemeMode(
                        v ? ThemeMode.dark : ThemeMode.light),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _segmentedTile(
                    icon: Icons.density_medium_outlined,
                    title: "列表密度",
                    subtitle: tp.listDensity == "compact" ? "紧凑" : "舒适",
                    segments: const [
                      ButtonSegment(value: "compact", label: Text("紧凑")),
                      ButtonSegment(value: "normal", label: Text("舒适")),
                    ],
                    selected: {tp.listDensity},
                    onChanged: (v) => tp.setListDensity(v.first),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _segmentedTile<SliderStyle>(
                    icon: Icons.show_chart_outlined,
                    title: "进度条样式",
                    subtitle: tp.sliderStyle == SliderStyle.wave ? "波浪形" : "直线形",
                    segments: const [
                      ButtonSegment(value: SliderStyle.straight,
                          icon: Icon(Icons.horizontal_rule_rounded)),
                      ButtonSegment(value: SliderStyle.wave,
                          icon: Icon(Icons.waves_rounded)),
                    ],
                    selected: {tp.sliderStyle},
                    onChanged: (v) => tp.setSliderStyle(v.first),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: _icon(Icons.apps_outlined),
                    title: const Text("应用图标"),
                    subtitle: Text(_iconFileName(sp.appIconPath),
                        style: tt.bodySmall?.copyWith(color: cs.outline)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAppIconPicker(context, sp),
                  ),
                ]),
              ),

              const SizedBox(height: 20),
              // ── 播放 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "播放"),
              Card.filled(
                child: Column(children: [
                  _switchTile(Icons.play_circle_outline, "启动时自动播放",
                      "应用启动后恢复上次播放",
                      sp.autoPlayOnStart, sp.setAutoPlayOnStart),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _switchTile(Icons.touch_app_outlined, "双击快速播放",
                      "双击列表中的歌曲立即播放",
                      sp.doubleTapToPlay, sp.setDoubleTapToPlay),
                ]),
              ),

              const SizedBox(height: 20),
              // ── 显示 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "显示"),
              Card.filled(
                child: Column(children: [
                  _switchTile(Icons.album_outlined, "显示专辑封面",
                      "播放页面展示专辑封面图",
                      sp.showLyricCover, sp.setShowLyricCover),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _switchTile(Icons.notifications_outlined, "通知栏显示详情",
                      "通知栏展示歌曲名与封面",
                      sp.showNotificationDetail, sp.setShowNotificationDetail),
                ]),
              ),

              const SizedBox(height: 20),
              // ── 数据 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "数据"),
              Card.filled(
                child: Column(children: [
                  ScanDirectoriesTile(
                    scanPaths: _scanPaths,
                    isLoading: _isPathsLoading,
                    onPickDialog: _showPickDialog,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: _icon(Icons.history_outlined),
                    title: const Text("历史记录上限"),
                    subtitle: Text("最多保留 ${sp.maxHistoryCount} 条",
                        style: tt.bodySmall?.copyWith(color: cs.outline)),
                    trailing: DropdownButton<int>(
                      value: sp.maxHistoryCount,
                      items: const [
                        DropdownMenuItem(value: 50, child: Text("50")),
                        DropdownMenuItem(value: 100, child: Text("100")),
                        DropdownMenuItem(value: 300, child: Text("300")),
                        DropdownMenuItem(value: 500, child: Text("500")),
                      ],
                      onChanged: (v) { if (v != null) sp.setMaxHistoryCount(v); },
                      underline: Container(),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: _icon(Icons.cleaning_services_outlined),
                    title: const Text("清除缓存"),
                    subtitle: Text("清除专辑封面、歌词等临时文件",
                        style: tt.bodySmall?.copyWith(color: cs.outline)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => _showClearCache(context),
                  ),
                ]),
              ),

              const SizedBox(height: 20),
              // ── 关于 ──────────────────────────────────────────────────────
              AppSectionHeader(title: "关于"),
              Card.filled(
                child: Column(children: [
                  ListTile(
                    leading: _icon(Icons.info_outline_rounded),
                    title: const Text("软件版本"),
                    trailing: Text("$ver ($bld)",
                        style: tt.bodyMedium?.copyWith(color: cs.outline)),
                    onTap: () => context.pushNamed('about'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: _icon(Icons.description_outlined),
                    title: const Text("开源许可"),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => showLicensePage(context: context),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── reusable tile helpers ──────────────────────────────────────────────

  Widget _icon(IconData icon) =>
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant);

  Widget _switchTile(IconData icon, String title, String subtitle,
      bool value, ValueChanged<bool> onChanged) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: _icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.outline)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _segmentedTile<T>({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<ButtonSegment<T>> segments,
    required Set<T> selected,
    required ValueChanged<Set<T>> onChanged,
  }) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: _icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.outline)),
      trailing: SegmentedButton<T>(
        segments: segments,
        selected: selected,
        onSelectionChanged: onChanged,
        showSelectedIcon: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
      ),
    );
  }

  String _iconFileName(String p) => p
      .split('/').last
      .replaceAll(RegExp(r'\.(png|jpeg|jpg)$'), '')
      .replaceAll('app_icon', '风格 ').trim();

  void _showAppIconPicker(BuildContext context, SettingsProvider sp) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => AppIconPickerSheet(
        iconPaths: const [
          MyAssets.app_icon, MyAssets.app_icon1, MyAssets.app_icon2,
          MyAssets.app_icon3, MyAssets.app_icon4, MyAssets.app_icon5,
          MyAssets.app_icon6, MyAssets.app_icon7, MyAssets.app_icon8,
          MyAssets.app_icon9,
        ],
        currentIconPath: sp.appIconPath,
        onConfirm: (p) { sp.setAppIconPath(p); Navigator.pop(context); },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _showClearCache(BuildContext context) async {
    final cs = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("清除缓存"),
        content: const Text("将清除专辑封面、歌词等临时缓存文件，不会影响您的音乐库和播放列表。"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("取消")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("确定清除")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final tmp = await getTemporaryDirectory();
      if (await tmp.exists()) await tmp.delete(recursive: true);
      final cache = await getApplicationCacheDirectory();
      if (await cache.exists()) {
        await for (final e in cache.list(recursive: true)) {
          if (e is File) { try { await e.delete(); } catch (_) {} }
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text("缓存已清除"), backgroundColor: cs.primaryContainer),
      );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("清除失败: $e"), backgroundColor: cs.error),
      );
      }
    }
  }
}
