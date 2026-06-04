import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/constants/Theme/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
                          Icon(Icons.color_lens_outlined,
                              size: 20, color: colorScheme.onSurfaceVariant),
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
                      secondary: Icon(Icons.dark_mode_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("深色模式"),
                      subtitle: Text(
                        themeProvider.themeMode == ThemeMode.system
                            ? "跟随系统"
                            : themeProvider.themeMode == ThemeMode.dark
                                ? "已开启"
                                : "已关闭",
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.outline),
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
                      leading: Icon(Icons.density_medium_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("列表密度"),
                      subtitle: Text(
                        themeProvider.listDensity == "compact" ? "紧凑" : "舒适",
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: "compact",
                            label: Text("紧凑"),
                          ),
                          ButtonSegment(
                            value: "normal",
                            label: Text("舒适"),
                          ),
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
                      leading: Icon(Icons.show_chart_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("进度条样式"),
                      subtitle: Text(
                        themeProvider.sliderStyle == SliderStyle.wave
                            ? "波浪形"
                            : "直线形",
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.outline),
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
                      leading: Icon(Icons.apps_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("应用图标"),
                      subtitle: Text(
                        _getIconFileName(themeProvider.appIconPath),
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAppIconPicker(context, themeProvider),
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
                      secondary: Icon(Icons.play_circle_outline,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("启动时自动播放"),
                      subtitle: Text(
                        "应用启动后恢复上次播放",
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      value: themeProvider.autoPlayOnStart,
                      onChanged: (v) => themeProvider.setAutoPlayOnStart(v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 双击播放 ──
                    SwitchListTile(
                      secondary: Icon(Icons.touch_app_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("双击快速播放"),
                      subtitle: Text(
                        "双击列表中的歌曲立即播放",
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      value: themeProvider.doubleTapToPlay,
                      onChanged: (v) => themeProvider.setDoubleTapToPlay(v),
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
                      secondary: Icon(Icons.album_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("显示专辑封面"),
                      subtitle: Text(
                        "播放页面展示专辑封面图",
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      value: themeProvider.showLyricCover,
                      onChanged: (v) => themeProvider.setShowLyricCover(v),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // ── 通知栏详情 ──
                    SwitchListTile(
                      secondary: Icon(Icons.notifications_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("通知栏显示详情"),
                      subtitle: Text(
                        "通知栏展示歌曲名与封面",
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      value: themeProvider.showNotificationDetail,
                      onChanged: (v) =>
                          themeProvider.setShowNotificationDetail(v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              _buildSectionHeader(context, "数据"),

              Card.filled(
                child: Column(
                  children: [
                    // ── 最大历史记录 ──
                    ListTile(
                      leading: Icon(Icons.history_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("历史记录上限"),
                      subtitle: Text(
                        "最多保留 ${themeProvider.maxHistoryCount} 条",
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      trailing: DropdownButton<int>(
                        value: themeProvider.maxHistoryCount,
                        items: const [
                          DropdownMenuItem(value: 50, child: Text("50")),
                          DropdownMenuItem(value: 100, child: Text("100")),
                          DropdownMenuItem(value: 300, child: Text("300")),
                          DropdownMenuItem(value: 500, child: Text("500")),
                        ],
                        onChanged: (v) {
                          if (v != null) themeProvider.setMaxHistoryCount(v);
                        },
                        underline: Container(),
                      ),
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
                      leading: Icon(Icons.info_outline_rounded,
                          size: 20, color: colorScheme.onSurfaceVariant),
                      title: const Text("软件版本"),
                      trailing: Text(
                        "$version ($buildNumber)",
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colorScheme.outline),
                      ),
                      onTap: () => context.pushNamed('about'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.description_outlined,
                          size: 20, color: colorScheme.onSurfaceVariant),
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
    final name = path.split('/').last.replaceAll(RegExp(r'\.(png|jpeg|jpg)$'), '');
    return name.replaceAll('app_icon', '风格 ').trim();
  }

  void _showAppIconPicker(BuildContext context, ThemeProvider themeProvider) {
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
          currentIconPath: themeProvider.appIconPath,
          onConfirm: (selectedPath) {
            themeProvider.setAppIconPath(selectedPath);
            Navigator.of(sheetContext).pop();
          },
          onCancel: () => Navigator.of(sheetContext).pop(),
        );
      },
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
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
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
    final checkIconColor =
        color.computeLuminance() > 0.5 ? cs.inverseSurface : cs.onInverseSurface;

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
        child:
            isSelected ? Icon(Icons.check_rounded, color: checkIconColor) : null,
      ),
    );
  }
}
