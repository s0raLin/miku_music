import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/service/UpdateCheck/index.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateDownloadPage extends StatelessWidget {
  final ReleaseInfo releaseInfo;

  const UpdateDownloadPage({super.key, required this.releaseInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar.large(title: Text('获取更新'), centerTitle: false),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.list(
              children: [
                // ── 版本信息头部 ──
                _VersionHeader(
                  tagName: releaseInfo.tagName,
                  description: releaseInfo.description,
                ),
                const SizedBox(height: 28),

                // ── 下载方式标题 ──
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    '下载方式',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // ── GitHub 发布页卡片 ──
                if (releaseInfo.htmlUrl.isNotEmpty)
                  _DownloadCard(
                    icon: Icons.code_rounded,
                    iconBg: colorScheme.primaryContainer,
                    iconColor: colorScheme.onPrimaryContainer,
                    title: 'GitHub Releases',
                    subtitle: '前往 GitHub 获取官方完整 Build 构件',
                    buttonLabel: '前往下载',
                    onTap: () async {
                      final url = Uri.parse(releaseInfo.htmlUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),

                // ── 网盘下载卡片 ──
                if (releaseInfo.cloudDriveUrl.isNotEmpty) ...[
                  if (releaseInfo.htmlUrl.isNotEmpty)
                    const SizedBox(height: 12),
                  _CloudDriveCard(
                    icon: Icons.cloud_download_rounded,
                    iconBg: colorScheme.tertiaryContainer,
                    iconColor: colorScheme.onTertiaryContainer,
                    title: '网盘下载',
                    subtitle: '通过镜像网盘快速获取 APK 安装包',
                    url: releaseInfo.cloudDriveUrl,
                    password: releaseInfo.cloudDrivePassword,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 版本信息头部 (支持完整的 Markdown 排版)
// ─────────────────────────────────────────────────────────────────────────────
class _VersionHeader extends StatelessWidget {
  final String tagName;
  final String description;

  const _VersionHeader({required this.tagName, required this.description});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 版本 Header 头部
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.system_update_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '新版本可用',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tagName,
                      style: textTheme.bodyMedium?.copyWith(
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

        // 更新日志列表 (Markdown 格式化)
        if (description.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '更新日志',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 320),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Markdown(
                data: description,
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                selectable: true,
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                    .copyWith(
                      p: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      h1: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      h2: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      h3: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      listBullet: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      code: textTheme.bodySmall?.copyWith(
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 通用下载卡片
// ─────────────────────────────────────────────────────────────────────────────
class _DownloadCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const _DownloadCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 网盘下载卡片（解决抖动与尺寸不一致问题）
// ─────────────────────────────────────────────────────────────────────────────
class _CloudDriveCard extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String url;
  final String password;

  const _CloudDriveCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.url,
    required this.password,
  });

  @override
  State<_CloudDriveCard> createState() => _CloudDriveCardState();
}

class _CloudDriveCardState extends State<_CloudDriveCard> {
  bool _passwordCopied = false;

  Future<void> _copyPassword() async {
    await Clipboard.setData(ClipboardData(text: widget.password));
    if (!mounted) return;
    setState(() => _passwordCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _passwordCopied = false);
  }

  Future<void> _openUrl() async {
    final url = Uri.parse(widget.url);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 提取码高亮模块
          if (widget.password.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.only(
                left: 12,
                right: 4,
                top: 4,
                bottom: 4,
              ),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.key_rounded,
                    size: 16,
                    color: colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '提取码',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.password,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  // 修复布局抖动的核心：固定 36x36 级别的约束容器
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _passwordCopied
                          ? Icon(
                              Icons.check_circle_rounded,
                              key: const ValueKey('check'),
                              color: colorScheme.primary,
                              size: 20,
                            )
                          : IconButton(
                              key: const ValueKey('copy'),
                              icon: Icon(
                                Icons.copy_rounded,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onPressed: _copyPassword,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _openUrl,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('前往网盘下载'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
