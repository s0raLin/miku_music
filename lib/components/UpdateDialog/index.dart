import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/service/UpdateCheck/index.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDialog extends StatelessWidget {
  final ReleaseInfo releaseInfo;
  final String currentVersion;

  const UpdateDialog({
    super.key,
    required this.releaseInfo,
    required this.currentVersion,
  });

  /// 显示更新弹窗（可点击外部区域取消）
  static Future<void> show(
    BuildContext context, {
    required ReleaseInfo releaseInfo,
    required String currentVersion,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _UpdateDialogContent(
        releaseInfo: releaseInfo,
        currentVersion: currentVersion,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 此 Widget 通过静态方法 show 使用
    throw UnimplementedError('请使用 UpdateDialog.show() 静态方法');
  }
}

class _UpdateDialogContent extends StatefulWidget {
  final ReleaseInfo releaseInfo;
  final String currentVersion;

  const _UpdateDialogContent({
    required this.releaseInfo,
    required this.currentVersion,
  });

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final release = widget.releaseInfo;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBR),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      titlePadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      actionsPadding: const EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: 20,
        top: 8,
      ),
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.card),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.inner),
              ),
              child: Icon(
                Icons.system_update_rounded,
                color: colorScheme.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '发现新版本',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    release.tagName,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 版本对比
              _VersionCompareRow(
                currentVersion: widget.currentVersion,
                latestVersion: release.tagName,
              ),
              const SizedBox(height: 20),

              // 更新描述标题
              Text(
                '更新内容',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),

              // 更新描述内容
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(AppRadius.inner),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    release.description.isNotEmpty
                        ? release.description
                        : '暂无更新描述',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '取消',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 8),

        // 前往更新按钮
        FilledButton.icon(
          onPressed: () async {
            final url = Uri.parse(release.htmlUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
            if (!context.mounted) return;
            
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.download_rounded, size: 20),
          label: const Text('前往更新'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        ),
      ],
    );
  }
}

/// 版本对比行
class _VersionCompareRow extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;

  const _VersionCompareRow({
    required this.currentVersion,
    required this.latestVersion,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // 当前版本
        Expanded(
          child: _VersionBadge(
            label: '当前版本',
            version: currentVersion,
            backgroundColor: colorScheme.surfaceContainerHighest,
            textColor: colorScheme.onSurfaceVariant,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.arrow_forward_rounded,
            color: colorScheme.primary,
            size: 20,
          ),
        ),
        // 最新版本
        Expanded(
          child: _VersionBadge(
            label: '最新版本',
            version: latestVersion,
            backgroundColor: colorScheme.primaryContainer,
            textColor: colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String label;
  final String version;
  final Color backgroundColor;
  final Color textColor;

  const _VersionBadge({
    required this.label,
    required this.version,
    required this.backgroundColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.inner),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            version,
            style: textTheme.titleMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
