import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final version = context.select<MusicProvider, String>((p) => p.appVersion);
    final buildNumber = context.select<MusicProvider, String>(
      (p) => p.buildNumber,
    );

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
              tooltip: '返回',
            ),
            title: const Text('关于'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList.list(
              children: [
                _AppBanner(version: version),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.new_releases_outlined,
                        label: '版本号',
                        value: 'v$version',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.developer_board_outlined,
                        label: '构建号',
                        value: buildNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _TechStackCard(),
                const SizedBox(height: 8),
                const _FeaturesCard(),
                const SizedBox(height: 8),
                const _LinksCard(),
                const SizedBox(height: 24),
                _FooterText(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 应用标识 Banner
// ─────────────────────────────────────────────────────────────────────────────
class _AppBanner extends StatelessWidget {
  const _AppBanner({required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card.filled(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                MyAssets.mikulogo,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'M3Music',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '跨平台音乐播放器',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    children: [
                      _VersionBadge(label: 'v$version'),
                      _VersionBadge(label: 'Stable', filled: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 版本徽标 — 用 Container 替代不可交互的 FilterChip
// ─────────────────────────────────────────────────────────────────────────────
class _VersionBadge extends StatelessWidget {
  const _VersionBadge({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontSize: 11,
      color: filled ? cs.onSecondaryContainer : cs.onSurfaceVariant,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? cs.secondaryContainer : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: textStyle),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 指标卡片 — M3 OutlinedCard，固定高度避免 IntrinsicHeight
// ─────────────────────────────────────────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 技术栈卡片 — 独立全宽卡片，使用标准 ListTile
// ─────────────────────────────────────────────────────────────────────────────
class _TechStackCard extends StatelessWidget {
  const _TechStackCard();

  static const _items = [
    (label: '框架', value: 'Flutter 3.x'),
    (label: '设计系统', value: 'Material 3'),
    (label: '分发平台', value: 'GitHub'),
    (label: '协议', value: 'MIT License'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 18, color: cs.secondary),
                const SizedBox(width: 8),
                Text(
                  '技术栈',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20, indent: 16, endIndent: 16),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    item.value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 核心特性卡片 — 独立全宽，M3 AssistChip 替代自定义 Chip
// ─────────────────────────────────────────────────────────────────────────────
class _FeaturesCard extends StatelessWidget {
  const _FeaturesCard();

  static const _features = ['动态主题', '歌词同步', '本地管理', '跨平台'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: cs.tertiary),
                const SizedBox(width: 8),
                Text(
                  '核心特性',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _features
                  .map(
                    (f) => Chip(
                      label: Text(f, style: theme.textTheme.labelSmall),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      backgroundColor: cs.secondaryContainer,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 链接列表 — clipBehavior + 标准 ListTile
// ─────────────────────────────────────────────────────────────────────────────
class _LinksCard extends StatelessWidget {
  const _LinksCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LinkTile(
            icon: Icons.code_rounded,
            title: '源代码',
            subtitle: 'GitHub / s0raLin',
            url: 'https://github.com/s0raLin/miku_music',
          ),
          const Divider(indent: 56, endIndent: 16, height: 1),
          _LinkTile(
            icon: Icons.history_rounded,
            title: '更新日志',
            subtitle: '查看版本动态',
            url: 'https://github.com/s0raLin/miku_music/releases',
          ),
          const Divider(indent: 56, endIndent: 16, height: 1),
          _LinkTile(
            icon: Icons.gavel_rounded,
            title: '开源协议',
            subtitle: 'MIT License',
            url: 'https://opensource.org/licenses/MIT',
          ),
          const Divider(indent: 56, endIndent: 16, height: 1),
          const _LinkTile(
            icon: Icons.favorite_rounded,
            title: '开发者',
            subtitle: '蒼璃 · Made with care',
            url: '',
            isAction: false,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 链接行
// ─────────────────────────────────────────────────────────────────────────────
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.url,
    this.isAction = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String url;
  final bool isAction;

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: cs.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isAction
          ? Icon(
              Icons.open_in_new_rounded,
              size: 18,
              color: cs.onSurfaceVariant,
            )
          : null,
      onTap: isAction ? () => _launch(context) : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 页脚
// ─────────────────────────────────────────────────────────────────────────────
class _FooterText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Text(
        'M3Music · Built with Flutter & Material 3',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
