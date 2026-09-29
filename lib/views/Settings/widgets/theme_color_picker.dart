import 'package:flutter/material.dart';
import 'package:myapp/views/Settings/widgets/custom_color_picker.dart';

/// M3 风格主题色预设选项（柔色 Morandi 向 + 少量高饱和点缀）
const List<({Color color, String label})> kM3PresetColors = [
  (color: Color(0xFFC49B8A), label: '豆沙'),
  (color: Color(0xFFE0A7A0), label: '藕荷'),
  (color: Color(0xFFD4A373), label: '麦浪'),
  (color: Color(0xFFB5838D), label: '玫瑰'),
  (color: Color(0xFF9C6B7B), label: '绛紫'),
  (color: Color(0xFF7B8FA1), label: '雾蓝'),
  (color: Color(0xFF4169E1), label: '克莱因'),
  (color: Color(0xFF5B8A72), label: '青竹'),
  (color: Color(0xFF00A86B), label: '森绿'),
  (color: Color(0xFF00897B), label: '青瓷'),
  (color: Color(0xFFFF8F00), label: '落日'),
  (color: Color(0xFFE07A5F), label: '珊瑚'),
  (color: Color(0xFF546E7A), label: '岩灰'),
  (color: Color(0xFF7B1FA2), label: '葡萄'),
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

          // 实时主题预览
          _ThemePreview(seedColor: selectedColor),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              ...presetColors.map((entry) {
                final isSelected =
                    selectedColor.toARGB32() == entry.color.toARGB32();
                return _ColorSwatch(
                  color: entry.color,
                  label: entry.label,
                  isSelected: isSelected,
                  onTap: () => onColorSelected(entry.color),
                );
              }),
              _CustomSwatch(
                isSelected: !presetColors.any(
                  (e) => e.color.toARGB32() == selectedColor.toARGB32(),
                ),
                onTap: () async {
                  final picked = await showCustomColorPickerDialog(
                    context,
                    initialColor: selectedColor,
                  );
                  if (picked != null) onColorSelected(picked);
                },
              ),
            ],
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
    final iconColor =
        brightness == Brightness.light ? Colors.black87 : Colors.white;
    final splashColor = iconColor.withValues(alpha: 0.2);

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        selected: isSelected,
        button: true,
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
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
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 自定义取色入口 — 彩虹色环，点击打开 HSV 取色对话框
// ─────────────────────────────────────────────────────────────────────────────
class _CustomSwatch extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomSwatch({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: '自定义',
      child: Semantics(
        label: '自定义',
        selected: isSelected,
        button: true,
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: isSelected ? 44 : 40,
                  height: isSelected ? 44 : 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(isSelected ? 14 : 20),
                    gradient: const SweepGradient(
                      colors: [
                        Color(0xFFFF5252),
                        Color(0xFFFFEB3B),
                        Color(0xFF4CAF50),
                        Color(0xFF2196F3),
                        Color(0xFF9C27B0),
                        Color(0xFFFF5252),
                      ],
                    ),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant.withValues(alpha: 0.4),
                      width: isSelected ? 2.5 : 1.0,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    ),
                  ),
                  child: Center(
                    child: isSelected
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 22)
                        : const Icon(Icons.colorize_rounded,
                            color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '自定义',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 实时主题预览 — 展示种子色在浅/深色下生成的真实配色
// ─────────────────────────────────────────────────────────────────────────────
class _ThemePreview extends StatelessWidget {
  final Color seedColor;
  const _ThemePreview({required this.seedColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final dark = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '实时预览',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _SchemeRow(label: '浅色', scheme: light),
          const SizedBox(height: 8),
          _SchemeRow(label: '深色', scheme: dark),
        ],
      ),
    );
  }
}

class _SchemeRow extends StatelessWidget {
  final String label;
  final ColorScheme scheme;
  const _SchemeRow({required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: [
              _SchemeChip(color: scheme.primary, name: '主色'),
              _SchemeChip(color: scheme.primaryContainer, name: '主色容器'),
              _SchemeChip(color: scheme.secondary, name: '次要色'),
              _SchemeChip(color: scheme.secondaryContainer, name: '次要容器'),
              _SchemeChip(color: scheme.tertiary, name: '第三色'),
              _SchemeChip(color: scheme.tertiaryContainer, name: '第三容器'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SchemeChip extends StatelessWidget {
  final Color color;
  final String name;
  const _SchemeChip({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: name,
        child: Container(
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
      ),
    );
  }
}
