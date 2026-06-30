import 'package:flutter/material.dart';

/// M3 bottom-sheet for selecting app icons from a horizontal list.
class AppIconPickerSheet extends StatefulWidget {
  final List<String> iconPaths;
  final String currentIconPath;
  final ValueChanged<String> onConfirm;
  final VoidCallback onCancel;

  const AppIconPickerSheet({
    super.key,
    required this.iconPaths,
    required this.currentIconPath,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<AppIconPickerSheet> createState() => _AppIconPickerSheetState();
}

class _AppIconPickerSheetState extends State<AppIconPickerSheet> {
  late String _selectedPath;

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.currentIconPath;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                final displayName = path
                    .split('/')
                    .last
                    .replaceAll(RegExp(r'\.(png|jpeg|jpg)$'), '')
                    .replaceAll('app_icon', '')
                    .trim();

                return GestureDetector(
                  onTap: () => setState(() => _selectedPath = path),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: 76,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primaryContainer
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected
                          ? Border.all(color: cs.primary, width: 2)
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
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName.isEmpty ? "默认" : displayName,
                          style: tt.labelSmall?.copyWith(
                            color: isSelected
                                ? cs.primary
                                : cs.onSurfaceVariant,
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
