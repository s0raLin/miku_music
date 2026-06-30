import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/service/Files/index.dart';

/// M3 scan-directories inline tile — refined card-style header + chip cloud.
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.folder_copy_rounded,
                    size: 22, color: cs.primary),
              ),
              const SizedBox(width: 14),
              // title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("音乐扫描目录",
                        style: tt.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: Text(
                        isLoading
                            ? "加载中…"
                            : scanPaths.isEmpty
                                ? "未添加任何目录"
                                : "${scanPaths.length} 个目录已配置",
                        key: ValueKey("${isLoading}_${scanPaths.length}"),
                        style: tt.bodySmall?.copyWith(
                          color: cs.outline,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // manage button
              FilledButton.tonalIcon(
                onPressed: isLoading ? null : onPickDialog,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text("管理"),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),

          // ── Chips area ──────────────────────────────────────────────────
          if (!isLoading && scanPaths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                children: scanPaths.map((path) {
                  final folderName = path
                      .split(Platform.pathSeparator)
                      .lastWhere((e) => e.isNotEmpty, orElse: () => path);

                  return Material(
                    color: Colors.transparent,
                    child: InputChip(
                      avatar: Icon(Icons.folder_rounded,
                          size: 16, color: cs.primary),
                      label: Text(folderName,
                          style: tt.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500)),
                      labelPadding: const EdgeInsets.only(left: 2),
                      deleteIcon: Icon(Icons.close_rounded,
                          size: 16, color: cs.onSurfaceVariant),
                      onDeleted: () {
                        final newPaths =
                            List<String>.from(scanPaths)..remove(path);
                        FileService.savePaths(newPaths);
                        onPathRemoved?.call();
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      tooltip: path,
                      side: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: cs.surfaceContainerLow,
                      elevation: 0,
                      pressElevation: 0,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
