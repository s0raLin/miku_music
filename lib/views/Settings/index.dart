import 'package:flutter/material.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<Color> _themeColors = [
    Colors.deepPurple,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('外观'),
          const SizedBox(height: 8),
          _buildCard([
            _buildSwitchTile(
              icon: Icons.dark_mode,
              title: '深色模式',
              value: themeProvider.isDark,
              onChanged: (value) => themeProvider.toggleThemeMode(),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionHeader('主题色'),
          const SizedBox(height: 8),
          _buildCard([
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _themeColors.map((color) {
                  final isSelected = themeProvider.seedColor == color;
                  return GestureDetector(
                    onTap: () => themeProvider.setSeedColor(color),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: colorScheme.primary, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSectionHeader('关于'),
          const SizedBox(height: 8),
          _buildCard([
            _buildListTile(
              icon: Icons.info_outline,
              title: '版本',
              trailing: Text(
                '1.0.0',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: TextStyle(color: colorScheme.onSurface)),
      trailing: trailing,
    );
  }
}
