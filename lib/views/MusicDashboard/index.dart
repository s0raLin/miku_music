import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class MusicDashboardPage extends StatelessWidget {
  const MusicDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 响应式阈值：宽度小于 480 视为窄屏（竖屏手机）
          final bool isNarrow = constraints.maxWidth < 480;
          final int crossAxisCount = isNarrow ? 2 : 4;

          // 这里的 Tile 逻辑模仿了 Dashboard 的错落感
          final List<QuiltedGridTile> pattern = isNarrow
              ? const [
                  QuiltedGridTile(2, 2), // 专辑封面 (大)
                  QuiltedGridTile(1, 2), // 播放控制 (宽)
                  QuiltedGridTile(1, 1), // 采样率 (小)
                  QuiltedGridTile(1, 1), // 输出设备 (小)
                  QuiltedGridTile(2, 2), // 歌词预览 (长)
                ]
              : const [
                  QuiltedGridTile(2, 2), // 专辑封面
                  QuiltedGridTile(1, 2), // 播放控制
                  QuiltedGridTile(1, 1), // 采样率
                  QuiltedGridTile(1, 1), // 输出设备
                  QuiltedGridTile(2, 4), // 宽屏下歌词横向拉长
                ];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Text("MikuMusic"),
                centerTitle: false,
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0,
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate: SliverQuiltedGridDelegate(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    repeatPattern: QuiltedGridRepeatPattern.inverted,
                    pattern: pattern,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _DashboardCard(index: index, isNarrow: isNarrow),
                    childCount: 5,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final int index;
  final bool isNarrow;

  const _DashboardCard({required this.index, required this.isNarrow});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 根据索引分配不同的语义颜色和内容
    final Color bgColor;
    final Color onColor;
    final String label;
    final IconData icon;

    switch (index) {
      case 0:
        bgColor = colorScheme.primaryContainer;
        onColor = colorScheme.onPrimaryContainer;
        label = "Now Playing";
        icon = Icons.album_rounded;
        break;
      case 1:
        bgColor = colorScheme.secondaryContainer;
        onColor = colorScheme.onSecondaryContainer;
        label = "Control";
        icon = Icons.play_arrow_rounded;
        break;
      case 2:
        bgColor = colorScheme.surfaceVariant.withOpacity(0.5);
        onColor = colorScheme.onSurfaceVariant;
        label = "96kHz";
        icon = Icons.high_quality_rounded;
        break;
      case 3:
        bgColor = colorScheme.surfaceVariant.withOpacity(0.5);
        onColor = colorScheme.onSurfaceVariant;
        label = "LDAC";
        icon = Icons.bluetooth_audio_rounded;
        break;
      default:
        bgColor = colorScheme.tertiaryContainer;
        onColor = colorScheme.onTertiaryContainer;
        label = "Lyrics Preview";
        icon = Icons.short_text_rounded;
    }

    return Container(
      padding: EdgeInsets.all(isNarrow && (index == 2 || index == 3) ? 12 : 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: onColor, size: isNarrow ? 20 : 28),
          const Spacer(),
          // 使用 FittedBox 解决窄屏下文字挤压导致的越界问题
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: textTheme.labelLarge?.copyWith(
                color: onColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
