import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/service/Files/index.dart';

/// Compact M3 scan-directories inline tile with chip cloud.
class ScanDirectoriesTile extends StatelessWidget {
  final List<String> scanPaths;
  final bool isLoading;
  final VoidCallback onPickDialog;
  final VoidCallback? onPathRemoved;

  const ScanDirectoriesTile({
    super.key,
    required this.scanPaths,
    required this.isLoading,
    required this.onPickDialog,
    this.onPathRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.folder_copy_rounded, size: 16, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("音乐扫描目录",
                        style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Text(
                        isLoading
                            ? "加载中…"
                            : scanPaths.isEmpty
                                ? "未添加任何目录"
                                : "${scanPaths.length} 个目录已配置",
                        key: ValueKey("${isLoading}_${scanPaths.length}"),
                        style: tt.bodySmall?.copyWith(color: cs.outline, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: isLoading ? null : onPickDialog,
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text("管理", style: TextStyle(fontSize: 12)),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          if (!isLoading && scanPaths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: scanPaths.map((path) {
                  final folderName = path
                      .split(Platform.pathSeparator)
                      .lastWhere((e) => e.isNotEmpty, orElse: () => path);
                  return InputChip(
                    avatar: Icon(Icons.folder_rounded, size: 14, color: cs.primary),
                    label: Text(folderName,
                        style: tt.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500)),
                    labelPadding: const EdgeInsets.only(left: 1),
                    deleteIcon: Icon(Icons.close_rounded, size: 14, color: cs.onSurfaceVariant),
                    onDeleted: () {
                      FileService.savePaths(List<String>.from(scanPaths)..remove(path));
                      onPathRemoved?.call();
                    },
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    tooltip: path,
                    side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    backgroundColor: cs.surfaceContainerLow,
                    padding: EdgeInsets.zero,
                    elevation: 0,
                    pressElevation: 0,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
