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
      appBar: AppBar(title: const Text("设置"), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildSectionHeader(context, "外观设置"),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.apps_rounded, size: 20),
                      title: const Text("应用图标"),
                      subtitle: Text(
                        _getIconFileName(themeProvider.appIconPath),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showAppIconPicker(context, themeProvider),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.brightness_medium_rounded),
                      title: const Text("主题模式"),
                      subtitle: Text(
                        _getThemeModeName(themeProvider.themeMode),
                      ),
                      trailing: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.settings_suggest_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {themeProvider.themeMode},
                        onSelectionChanged: (Set<ThemeMode> newSelection) {
                          themeProvider.setThemeMode(newSelection.first);
                        },
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.linear_scale_rounded),
                      title: const Text("进度条样式"),
                      subtitle: Text(
                        _getSliderStyleName(themeProvider.sliderStyle),
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
                        onSelectionChanged: (Set<SliderStyle> newSelection) {
                          themeProvider.setSliderStyle(newSelection.first);
                        },
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.color_lens_outlined, size: 20),
                              const SizedBox(width: 12),
                              Text("主题色", style: textTheme.bodyLarge),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: _themeColors.map((color) {
                                return _ThemeSeedButton(
                                  color: color,
                                  isSelected:
                                      themeProvider.seedColor.toARGB32() ==
                                      color.toARGB32(),
                                  onTap: () =>
                                      themeProvider.setSeedColor(color),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildSectionHeader(context, "播放设置"),

              Card(
                child: Column(
                  children: [
                    // 音质设置
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.music_note_outlined, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("音质设置", style: textTheme.bodyLarge),
                                Text(
                                  _getQualityName(themeProvider.audioQuality),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownButton<String>(
                            value: themeProvider.audioQuality,
                            items: const [
                              DropdownMenuItem(value: "low", child: Text("低")),
                              DropdownMenuItem(
                                value: "normal",
                                child: Text("标准"),
                              ),
                              DropdownMenuItem(value: "high", child: Text("高")),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                themeProvider.setAudioQuality(v);
                              }
                            },
                            underline: Container(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // 播放列表排序
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.sort_outlined, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("播放列表排序", style: textTheme.bodyLarge),
                                Text(
                                  _getSortByName(themeProvider.playlistSortBy),
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownButton<String>(
                            value: themeProvider.playlistSortBy,
                            items: const [
                              DropdownMenuItem(
                                value: "time",
                                child: Text("添加时间"),
                              ),
                              DropdownMenuItem(
                                value: "name",
                                child: Text("名称"),
                              ),
                              DropdownMenuItem(
                                value: "random",
                                child: Text("随机"),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                themeProvider.setPlaylistSortBy(v);
                              }
                            },
                            underline: Container(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // 最大历史数量
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        children: [
                          const Icon(Icons.history_outlined, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("最大历史记录", style: textTheme.bodyLarge),
                                Text(
                                  "${themeProvider.maxHistoryCount}条",
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.outline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DropdownButton<int>(
                            value: themeProvider.maxHistoryCount,
                            items: const [
                              DropdownMenuItem(value: 50, child: Text("50条")),
                              DropdownMenuItem(value: 100, child: Text("100条")),
                              DropdownMenuItem(value: 300, child: Text("300条")),
                              DropdownMenuItem(value: 500, child: Text("500条")),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                themeProvider.setMaxHistoryCount(v);
                              }
                            },
                            underline: Container(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildSectionHeader(context, "互动功能"),

              Card(
                child: Column(
                  children: [
                    // 双击播放
                    ListTile(
                      leading: const Icon(Icons.mouse_outlined, size: 20),
                      title: const Text("双击列表项快速播放"),
                      subtitle: Text(
                        "开启后双击音乐列表项可直接播放",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: Switch(
                        value: themeProvider.doubleTapToPlay,
                        onChanged: (v) {
                          themeProvider.setDoubleTapToPlay(v);
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // 歌词封面
                    ListTile(
                      leading: const Icon(Icons.image_outlined, size: 20),
                      title: const Text("显示歌词封面"),
                      subtitle: Text(
                        "在播放页面显示专辑封面",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: Switch(
                        value: themeProvider.showLyricCover,
                        onChanged: (v) {
                          themeProvider.setShowLyricCover(v);
                        },
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // 启动自动播放
                    ListTile(
                      leading: const Icon(Icons.play_arrow_outlined, size: 20),
                      title: const Text("启动时自动播放"),
                      subtitle: Text(
                        "应用启动后自动开始播放",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: Switch(
                        value: themeProvider.autoPlayOnStart,
                        onChanged: (v) {
                          themeProvider.setAutoPlayOnStart(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              _buildSectionHeader(context, "通知设置"),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.notifications_outlined,
                        size: 20,
                      ),
                      title: const Text("通知栏显示详情"),
                      subtitle: Text(
                        "在通知栏显示歌曲信息和封面",
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                      trailing: Switch(
                        value: themeProvider.showNotificationDetail,
                        onChanged: (v) {
                          themeProvider.setShowNotificationDetail(v);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              _buildSectionHeader(context, "关于"),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: const Text("软件版本"),
                      trailing: Text("$version (Build $buildNumber)"),
                      onTap: () => context.pushNamed('about'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: const Icon(Icons.code_rounded),
                      title: const Text("开源许可"),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => showLicensePage(context: context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return "跟随系统";
      case ThemeMode.light:
        return "浅色模式";
      case ThemeMode.dark:
        return "深色模式";
    }
  }

  String _getSliderStyleName(SliderStyle style) {
    switch (style) {
      case SliderStyle.straight:
        return "直线型";
      case SliderStyle.wave:
        return "蛇形波浪";
    }
  }

  String _getQualityName(String quality) {
    switch (quality) {
      case "low":
        return "低";
      case "normal":
        return "标准";
      case "high":
        return "高";
      default:
        return "标准";
    }
  }

  String _getSortByName(String sortBy) {
    switch (sortBy) {
      case "time":
        return "添加时间";
      case "name":
        return "名称";
      case "random":
        return "随机";
      default:
        return "添加时间";
    }
  }

  String _getIconFileName(String path) {
    return path.split('/').last;
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return _AppIconPickerSheet(
          iconPaths: iconPaths,
          currentIconPath: themeProvider.appIconPath,
          onConfirm: (selectedPath) {
            themeProvider.setAppIconPath(selectedPath);
            Navigator.of(sheetContext).pop();
          },
          onCancel: () {
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 拖拽指示条
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              "选择应用图标",
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // 横向滚动列表
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
                    .replaceAll('app_icon', '');

                return GestureDetector(
                  onTap: () => setState(() => _selectedPath = path),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 76,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1:1 圆角正方形图标预览
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.broken_image_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
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

          // 确定和取消按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("取消"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => widget.onConfirm(_selectedPath),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
      onTap: () {
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isSelected ? 12 : 24),
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
