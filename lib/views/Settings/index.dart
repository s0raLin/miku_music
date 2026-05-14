import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/contants/Theme/index.dart';
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
                           final mode = newSelection.first;
                           String msg;
                           if (mode == ThemeMode.light) {
                             msg = '浅色模式';
                           } else if (mode == ThemeMode.dark) {
                             msg = '深色模式';
                           } else {
                             msg = '跟随系统';
                           }
                           AppToast.neutral(
                             context,
                             message: '主题模式已切换为 $msg',
                           );
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
                                 String q = v == 'high' ? '高' : v == 'normal' ? '标准' : '低';
                                 AppToast.neutral(
                                   context,
                                   message: '音质已设置为 $q',
                                 );
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
                                 String sortName = v == 'time' ? '添加时间' : v == 'name' ? '名称' : '随机';
                                 AppToast.neutral(
                                   context,
                                   message: '排序方式已更新为 $sortName',
                                 );
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
                                 AppToast.neutral(
                                   context,
                                   message: '历史记录上限已设为 ${v} 条',
                                 );
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
                           AppToast.neutral(
                             context,
                             message: v ? '双击播放已开启' : '双击播放已关闭',
                           );
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
                           AppToast.neutral(
                             context,
                             message: v ? '歌词封面已开启' : '歌词封面已关闭',
                           );
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
                           AppToast.neutral(
                             context,
                             message: v ? '启动自动播放已开启' : '启动自动播放已关闭',
                           );
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
                           AppToast.neutral(
                             context,
                             message: v ? '通知栏详情已开启' : '通知栏详情已关闭',
                           );
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
         AppToast.neutral(
           context,
           message: '主题色已更新',
         );
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
