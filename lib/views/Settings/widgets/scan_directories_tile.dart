import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/service/Files/index.dart';

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. 标准化头部控制栏 (对齐其他 ListTile)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            Icons.folder_special_outlined,
            size: 20,
            color: cs.onSurfaceVariant,
          ),
          title: const Text("音乐扫描目录"),
          subtitle: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              isLoading
                  ? "加载目录中..."
                  : scanPaths.isEmpty
                  ? "未配置本地扫描路径"
                  : "已配置 ${scanPaths.length} 个扫描目录",
              key: ValueKey("${isLoading}_${scanPaths.length}"),
              style: tt.bodySmall?.copyWith(color: cs.outline),
            ),
          ),
          trailing: FilledButton.tonalIcon(
            onPressed: isLoading ? null : onPickDialog,
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text("管理", style: TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // 2. 动态展出的 Chip Cloud 区域
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 220),
          crossFadeState: (!isLoading && scanPaths.isNotEmpty)
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          secondChild: const SizedBox(width: double.infinity),
          firstChild: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: scanPaths.map((path) {
                  final folderName = path
                      .split(Platform.pathSeparator)
                      .lastWhere((e) => e.isNotEmpty, orElse: () => path);

                  return CustomPathChip(
                    folderName: folderName,
                    fullPath: path,
                    onDelete: () {
                      FileService.savePaths(
                        List<String>.from(scanPaths)..remove(path),
                      );
                      onPathRemoved?.call();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 自定义的精美路径 Chip，避免 InputChip 原生的生硬边框与间距
class CustomPathChip extends StatelessWidget {
  final String folderName;
  final String fullPath;
  final VoidCallback onDelete;

  const CustomPathChip({
    super.key,
    required this.folderName,
    required this.fullPath,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Tooltip(
      message: fullPath,
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {}, // 仅提供点击涟漪反馈
          child: Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 4,
              top: 4,
              bottom: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open_rounded, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    folderName,
                    style: tt.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 2),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
