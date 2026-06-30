import 'package:flutter/material.dart';

/// M3 distinctly-differentiated preset color palette.
/// Each color is from a completely different color family.
const List<({Color color, String label})> kM3PresetColors = [
  (color: Color(0xFFC49B8A), label: '玫瑰'),    // Dusty rose (default)
  (color: Color(0xFF4169E1), label: '皇家蓝'),   // Sapphire blue
  (color: Color(0xFF00A86B), label: '翡翠绿'),   // Emerald green
  (color: Color(0xFF7B1FA2), label: '紫罗兰'),   // Deep purple
  (color: Color(0xFFDC143C), label: '胭脂红'),   // Crimson red
  (color: Color(0xFFFF8F00), label: '琥珀'),     // Amber
  (color: Color(0xFF00897B), label: '青碧'),     // Teal
  (color: Color(0xFF546E7A), label: '岩灰'),     // Blue-grey slate
];

/// M3-style theme color picker — circular swatch grid with check indicator.
class ThemeColorPicker extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const ThemeColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.color_lens_outlined, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Text("主题色", style: tt.bodyLarge),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 14,
            children: kM3PresetColors.map((entry) {
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
    final cs = Theme.of(context).colorScheme;
    final checkIconColor =
        color.computeLuminance() > 0.5 ? cs.inverseSurface : cs.onInverseSurface;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(isSelected ? 16 : 28),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.45),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: isSelected
            ? Icon(Icons.check_rounded, color: checkIconColor, size: 22)
            : null,
      ),
    );
  }
}
