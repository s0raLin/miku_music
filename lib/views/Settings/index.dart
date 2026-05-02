import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // 定义一套更符合 MikuMusic 调性的调色盘
  static final List<Color> _themeColors = [
    const Color(0xFF6750A4), // 原生紫
    const Color(0xFF39C5BB), // 初音绿 (Miku Green)
    const Color(0xFF00B0FF), // 链接蓝
    const Color(0xFFFF4081), // 赛博粉
    const Color(0xFF4CAF50), // 护眼绿
    const Color(0xFFFF9800), // 活力橙
    const Color(0xFF795548), // 磁带棕
    const Color(0xFF607D8B), // 工业灰
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("设置"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader(context, "外观设置"),

          // 外观配置卡片
          Card(
            child: Column(
              children: [
                // 亮度模式切换
                ListTile(
                  leading: const Icon(Icons.brightness_medium_rounded),
                  title: const Text("主题模式"),
                  subtitle: Text(_getThemeModeName(themeProvider.themeMode)),
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

                // 主题色选择器
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
                                  themeProvider.seedColor.value == color.value,
                              onTap: () => themeProvider.setSeedColor(color),
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
          _buildSectionHeader(context, "关于"),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text("软件版本"),
                  trailing: const Text("v1.0.0 (Build 2026)"),
                  onTap: () {
                    // 可以跳转到 AboutPage
                    context.pushNamed('about');
                  },
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
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    // 这里使用了 colorScheme
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.primary, // 使用了变量
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          // 选中时变成圆角矩形，未选中时是圆形，增加动效感
          borderRadius: BorderRadius.circular(isSelected ? 12 : 24),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primaryContainer,
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
            ? Icon(
                Icons.check_rounded,
                color: color.computeLuminance() > 0.5
                    ? Colors.black87
                    : Colors.white,
              )
            : null,
      ),
    );
  }
}
