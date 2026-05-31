import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.list(
              children: [
                _AppBanner(version: version, buildNumber: buildNumber),
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
  const _AppBanner({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
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
            _VersionBadge(label: buildNumber, filled: true),
          ],
        ),
      ],
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

// // ─────────────────────────────────────────────────────────────────────────────
// // 链接列表 — clipBehavior + 标准 ListTile
// // ─────────────────────────────────────────────────────────────────────────────
// class _LinksCard extends StatelessWidget {
//   const _LinksCard();

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: EdgeInsets.zero,
//       clipBehavior: Clip.antiAlias,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _LinkTile(
//             icon: Icons.code_rounded,
//             title: '项目信息',
//             subtitle: '查看源代码/报告问题',
//             url: 'https://github.com/s0raLin/miku_music',
//           ),
//           const Divider(indent: 56, endIndent: 16, height: 1),
//           _LinkTile(
//             icon: Icons.history_rounded,
//             title: '更新日志',
//             subtitle: '查看版本动态',
//             url: 'https://github.com/s0raLin/miku_music/releases',
//           ),
//           const Divider(indent: 56, endIndent: 16, height: 1),
//           _LinkTile(
//             icon: Icons.gavel_rounded,
//             title: '开源协议',
//             subtitle: 'MIT License',
//             url: 'https://opensource.org/licenses/MIT',
//           ),
//           const Divider(indent: 56, endIndent: 16, height: 1),
//           const _LinkTile(
//             icon: Icons.favorite_rounded,
//             title: '开发者',
//             subtitle: '蒼璃 · Made with care',
//             url: '',
//             isAction: false,
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // 链接行
// // ─────────────────────────────────────────────────────────────────────────────
// class _LinkTile extends StatelessWidget {
//   const _LinkTile({
//     required this.icon,
//     required this.title,
//     required this.subtitle,
//     required this.url,
//     this.isAction = true,
//   });

//   final IconData icon;
//   final String title;
//   final String subtitle;
//   final String url;
//   final bool isAction;

//   Future<void> _launch(BuildContext context) async {
//     final uri = Uri.parse(url);
//     if (await canLaunchUrl(uri)) {
//       await launchUrl(uri, mode: LaunchMode.externalApplication);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cs = Theme.of(context).colorScheme;

//     return ListTile(
//       leading: Icon(icon, color: cs.onSurfaceVariant),
//       title: Text(title),
//       subtitle: Text(subtitle),
//       trailing: isAction
//           ? Icon(
//               Icons.open_in_new_rounded,
//               size: 18,
//               color: cs.onSurfaceVariant,
//             )
//           : null,
//       onTap: isAction ? () => _launch(context) : null,
//     );
//   }
// }

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

// 彩色图标容器
class _ColoredIcon extends StatelessWidget {
  const _ColoredIcon({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: iconColor, size: 18),
    );
  }
}

// _LinksCard — 增加 section 标题 + 彩色图标
class _LinksCard extends StatelessWidget {
  const _LinksCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '链接',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LinkTile(
                icon: Icons.code_rounded,
                iconBg: cs.primaryContainer,
                iconColor: cs.onPrimaryContainer,
                title: '项目信息',
                subtitle: '查看源代码 / 报告问题',
                url: 'https://github.com/s0raLin/miku_music',
              ),
              const Divider(indent: 66, endIndent: 16, height: 1),
              _LinkTile(
                icon: Icons.history_rounded,
                iconBg: cs.tertiaryContainer,
                iconColor: cs.onTertiaryContainer,
                title: '更新日志',
                subtitle: '查看版本动态',
                url: 'https://github.com/s0raLin/miku_music/releases',
              ),
              const Divider(indent: 66, endIndent: 16, height: 1),
              _LinkTile(
                icon: Icons.gavel_rounded,
                iconBg: cs.secondaryContainer,
                iconColor: cs.onSecondaryContainer,
                title: '开源协议',
                subtitle: 'MIT License',
                url: 'https://opensource.org/licenses/MIT',
              ),
              const Divider(indent: 66, endIndent: 16, height: 1),
              Builder(
                builder: (ctx) => ListTile(
                  leading: _ColoredIcon(
                    icon: Icons.favorite_rounded,
                    backgroundColor: const Color(0xFFFFE4EF),
                    iconColor: const Color(0xFF993556),
                  ),
                  title: const Text('开发者'),
                  subtitle: const Text('蒼璃 · Made with care'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                  onTap: () => _showDeveloperDialog(ctx),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// _LinkTile — 替换 leading 为彩色容器
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.url,
  }) : isAction = true;

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
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
      leading: _ColoredIcon(
        icon: icon,
        backgroundColor: iconBg,
        iconColor: iconColor,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isAction
          ? Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: cs.onSurfaceVariant,
            )
          : null,
      onTap: isAction ? () => _launch(context) : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 开发者联系弹窗
// ─────────────────────────────────────────────────────────────────────────────
void _showDeveloperDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    showDragHandle: true,
    builder: (_) => const _DeveloperSheet(),
  );
}

class _DeveloperSheet extends StatelessWidget {
  const _DeveloperSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 头部
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '蒼璃',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Made with care',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 8),
            // 联系方式列表
            _ContactTile(
              icon: Icons.chat_bubble_rounded,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1565C0),
              label: 'QQ',
              value: '892581781',
            ),
            _ContactTile(
              icon: Icons.email_rounded,
              iconBg: cs.tertiaryContainer,
              iconColor: cs.onTertiaryContainer,
              label: '邮箱',
              value: '892581781@qq.com',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 单条联系方式 — 点击复制
// ─────────────────────────────────────────────────────────────────────────────
class _ContactTile extends StatefulWidget {
  const _ContactTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: widget.iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(widget.icon, color: widget.iconColor, size: 18),
      ),
      title: Text(widget.label),
      subtitle: Text(widget.value),
      trailing: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _copied
            ? Icon(
                Icons.check_circle_rounded,
                key: const ValueKey('check'),
                color: cs.primary,
                size: 20,
              )
            : Icon(
                Icons.copy_rounded,
                key: const ValueKey('copy'),
                color: cs.onSurfaceVariant,
                size: 20,
              ),
      ),
      onTap: _copy,
    );
  }
}
