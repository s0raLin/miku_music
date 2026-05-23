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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
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
                ),
                const SizedBox(height: 8),
                _AdaptiveRow(
                  children: const [
                    Expanded(flex: 3, child: _SystemInfoCard()),
                    SizedBox(width: 8),
                    Expanded(flex: 2, child: _FeaturesCard()),
                  ],
                ),
                const SizedBox(height: 8),
                const _LinksCard(),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'M3Music · Built with Flutter & Material 3',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 应用标识 Banner — M3 FilledCard
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
        child: IntrinsicHeight(
          // IntrinsicHeight 让左右两侧等高：
          // 右侧文字有多高，左侧图标容器就有多高
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // AspectRatio(1:1) 保证始终正方形；
              // 高度由 IntrinsicHeight 从右侧文字列推导，
              // 因此图标的顶部和底部与文字列严格对齐
              SizedBox(
                width: 100,
                height: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    MyAssets.mikulogo,
                    fit: BoxFit.cover, // 或 BoxFit.fill，按图片比例选
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        FilterChip(
                          label: Text(
                            'v$version',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onSelected: null,
                          selected: false,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 6),
                        const FilterChip(
                          label: Text('Stable', style: TextStyle(fontSize: 11)),
                          onSelected: null,
                          selected: true,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ],
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
// 指标卡片 — M3 OutlinedCard
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
            Column(
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
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 系统信息 — M3 ElevatedCard
// ─────────────────────────────────────────────────────────────────────────────
class _SystemInfoCard extends StatelessWidget {
  const _SystemInfoCard();

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
                Icon(Icons.info_outline_rounded, size: 18, color: cs.secondary),
                const SizedBox(width: 8),
                Text(
                  '技术栈',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            _InfoRow(label: '框架', value: 'Flutter 3.x'),
            const SizedBox(height: 6),
            _InfoRow(label: '设计系统', value: 'Material 3'),
            const SizedBox(height: 6),
            _InfoRow(label: '分发平台', value: 'GitHub'),
            const SizedBox(height: 6),
            _InfoRow(label: '协议', value: 'MIT License'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 特性标签 — M3 Card + Chip
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
              spacing: 6,
              runSpacing: 6,
              children: _features
                  .map(
                    (f) => Chip(
                      label: Text(f),
                      labelStyle: theme.textTheme.labelSmall,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      side: BorderSide.none,
                      backgroundColor: cs.secondaryContainer,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
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
// 链接列表 — M3 ElevatedCard + 原生 ListTile
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
// 链接行 — 严格原生 M3 ListTile
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
// 辅助：信息键值行
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 辅助：自适应横向布局
// ─────────────────────────────────────────────────────────────────────────────
class _AdaptiveRow extends StatelessWidget {
  const _AdaptiveRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
