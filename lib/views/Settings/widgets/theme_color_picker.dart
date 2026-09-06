import 'package:flutter/material.dart';

/// M3 风格主题色预设选项
const List<({Color color, String label})> kM3PresetColors = [
  (color: Color(0xFFC49B8A), label: '豆沙'),     // 原来的玫瑰
  (color: Color(0xFF4169E1), label: '克莱因'),   // 原来的皇家蓝
  (color: Color(0xFF00A86B), label: '森绿'),     // 原来的翡翠绿
  (color: Color(0xFF7B1FA2), label: '葡萄'),     // 原来的紫罗兰
  (color: Color(0xFFDC143C), label: '朱红'),     // 原来的胭脂红
  (color: Color(0xFFFF8F00), label: '落日'),     // 原来的琥珀
  (color: Color(0xFF00897B), label: '青瓷'),     // 原来的青碧
  (color: Color(0xFF546E7A), label: '雾灰'),     // 原来的岩灰
];

/// M3 风格主题颜色选择器
class ThemeColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final List<({Color color, String label})> presetColors;
  final EdgeInsetsGeometry contentPadding;

  const ThemeColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.presetColors = kM3PresetColors,
    this.contentPadding = const EdgeInsets.fromLTRB(16, 12, 16, 12),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: contentPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.color_lens_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Text(
                '主题色',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: presetColors.map((entry) {
              final isSelected =
                  selectedColor.toARGB32() == entry.color.toARGB32();
              return _ColorSwatch(
                color: entry.color,
                label: entry.label,
                isSelected: isSelected,
                onTap: () => onColorSelected(entry.color),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 根据背景色亮度精确选择勾选图标和水波纹颜色
    final brightness = ThemeData.estimateBrightnessForColor(color);
    final iconColor = brightness == Brightness.light ? Colors.black87 : Colors.white;
    final splashColor = iconColor.withValues(alpha: 0.2);

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        selected: isSelected,
        button: true,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              width: isSelected ? 44 : 40,
              height: isSelected ? 44 : 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(isSelected ? 14 : 20),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant.withValues(alpha: 0.4),
                  width: isSelected ? 2.5 : 1.0,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(isSelected ? 14 : 20),
                  splashColor: splashColor,
                  highlightColor: splashColor,
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              key: const ValueKey('check_icon'),
                              color: iconColor,
                              size: 22,
                            )
                          : const SizedBox.shrink(
                              key: ValueKey('empty_space'),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
