// ─── CoverFlow 独立页面 - 基于 coverflow_carousel 库 (Material 3 Expressive) ──
//  全屏沉浸式 3D Cover Flow 轮播，极大化卡片视觉占比，完全移除 Standard App Bar。

import 'dart:typed_data';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:coverflow_carousel/coverflow_carousel.dart';
import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class CoverFlowPage extends StatelessWidget {
  const CoverFlowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Consumer<MusicProvider>(
        builder: (context, mp, _) {
          final coverBytes = mp.currentMusic?.coverBytes;
          final coverUrl = mp.currentMusic != null
              ? mp.getCoverUrl(mp.currentMusic!.id)
              : null;
          final hasCover =
              (coverBytes?.isNotEmpty ?? false) ||
              (coverUrl != null && coverUrl.isNotEmpty);

          final isDark = cs.brightness == Brightness.dark;

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. 全屏沉浸式磨砂背景
              if (hasCover)
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      coverBytes?.isNotEmpty == true
                          ? Image.memory(coverBytes!, fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: coverUrl!,
                              fit: BoxFit.cover,
                              httpHeaders: coverUrl.contains('music.126.net')
                                  ? {'Referer': 'https://music.163.com/'}
                                  : {},
                            ),
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.compose(
                            outer: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                            inner: ImageFilter.matrix(
                              Matrix4.diagonal3Values(1.05, 1.05, 1.0).storage,
                            ),
                          ),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      // 径向暗角与极简遮罩，避免背景喧宾夺主
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 1.3,
                            colors: isDark
                                ? [
                                    Colors.black.withValues(alpha: 0.15),
                                    Colors.black.withValues(alpha: 0.55),
                                    Colors.black.withValues(alpha: 0.92),
                                  ]
                                : [
                                    cs.surface.withValues(alpha: 0.1),
                                    cs.surface.withValues(alpha: 0.45),
                                    cs.surface.withValues(alpha: 0.92),
                                  ],
                            stops: const [0.0, 0.65, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [cs.surface, cs.surfaceContainerLowest],
                    ),
                  ),
                ),

              // 2. 沉浸式前景内容（尽可能占据全屏）
              Builder(
                builder: (context) {
                  if (mp.currentMusic == null) {
                    return const AppEmptyState(
                      icon: Icons.album_rounded,
                      title: '未选择歌曲',
                      subtitle: '播放一首歌曲后，可在此浏览封面轮播',
                    );
                  }
                  if (mp.queue.isEmpty) {
                    return const AppEmptyState(
                      icon: Icons.queue_music_rounded,
                      title: '播放队列为空',
                      subtitle: '添加到播放队列后即可浏览封面',
                    );
                  }
                  return CoverFlow(
                    key: ValueKey(mp.queue.length),
                    items: mp.queue
                        .map(
                          (m) => CoverItem(
                            id: m.id.hashCode,
                            title: m.title,
                            subtitle: '${m.artist}  ·  ${m.album}',
                            imageUrl: mp.getCoverUrl(m.id),
                            coverBytes: m.coverBytes,
                            isNetwork: m.source == MusicSource.network,
                            color: _palette[m.id.hashCode % _palette.length],
                          ),
                        )
                        .toList(),
                    initialIndex: mp.currentMusic != null
                        ? mp.queue
                              .indexOf(mp.currentMusic!)
                              .clamp(0, mp.queue.length - 1)
                        : 0,
                    isPlaying: ValueNotifier(mp.player.playing),
                    onTogglePlay: () => mp.togglePlay(),
                    onItemTapped: (item) {
                      final idx = mp.queue.indexWhere(
                        (m) => m.id.hashCode == item.id,
                      );
                      if (idx >= 0 && mp.queue[idx].id != mp.currentMusic?.id) {
                        mp.playByIndex(idx);
                      }
                    },
                    onPageChanged: (item) {
                      final idx = mp.queue.indexWhere(
                        (m) => m.id.hashCode == item.id,
                      );
                      if (idx >= 0 && mp.queue[idx].id != mp.currentMusic?.id) {
                        mp.playByIndex(idx);
                      }
                    },
                  );
                },
              ),

              // 3. 极简悬浮返回按钮（替代 AppBar）
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                child: SafeArea(
                  top: false,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Material(
                        color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: cs.onSurface,
                          tooltip: '返回',
                          splashRadius: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static const _palette = [
    Color(0xFF6C5CE7),
    Color(0xFFFD7272),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFF0984E3),
    Color(0xFF9B59B6),
    Color(0xFFE84393),
    Color(0xFF00CEC9),
    Color(0xFFF39C12),
    Color(0xFF57606F),
    Color(0xFF3742FA),
    Color(0xFFE15F41),
  ];
}

/// ── 数据模型 ───────────────────────────────────────────────────────────────
class CoverItem {
  final int id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final Uint8List? coverBytes;
  final bool isNetwork;
  final Color color;

  const CoverItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.coverBytes,
    this.isNetwork = false,
    required this.color,
  });
}

/// ── 极小化的 Cover Flow 容器组件 ───────────────────────────────────────────
class CoverFlow extends StatefulWidget {
  final List<CoverItem> items;
  final int initialIndex;
  final void Function(CoverItem)? onItemTapped;
  final void Function(CoverItem)? onPageChanged;
  final VoidCallback? onTogglePlay;
  final ValueNotifier<bool> isPlaying;

  const CoverFlow({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onItemTapped,
    this.onPageChanged,
    this.onTogglePlay,
    required this.isPlaying,
  });

  @override
  State<CoverFlow> createState() => _CoverFlowState();
}

class _CoverFlowState extends State<CoverFlow> {
  late final CoverflowCarouselController _controller;
  MusicProvider? _mp;
  int _currentIndex = 0;
  int? _lastSyncedId;

  @override
  void initState() {
    super.initState();
    _controller = CoverflowCarouselController();
    _currentIndex = widget.initialIndex;
    _controller.pageListenable.addListener(_onControllerChanged);
    if (widget.initialIndex >= 0 && widget.initialIndex < widget.items.length) {
      _lastSyncedId = widget.items[widget.initialIndex].id;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mp = Provider.of<MusicProvider>(context, listen: false);
    if (mp != _mp) {
      _mp?.removeListener(_onProviderChanged);
      _mp = mp;
      _mp!.addListener(_onProviderChanged);
    }
  }

  @override
  void dispose() {
    _mp?.removeListener(_onProviderChanged);
    _controller.pageListenable.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final page = _controller.page.round();
    if (page != _currentIndex && page >= 0 && page < widget.items.length) {
      _currentIndex = page;
      _lastSyncedId = widget.items[page].id;
      setState(() {});
    }
  }

  void _onProviderChanged() {
    final mp = _mp;
    if (mp == null) return;
    final current = mp.currentMusic;
    if (current == null) return;
    final idx = mp.queue.indexWhere((m) => m.id == current.id);
    if (idx < 0 || idx >= widget.items.length) return;
    if (idx == _currentIndex && _lastSyncedId == current.id.hashCode) return;
    _lastSyncedId = current.id.hashCode;
    _currentIndex = idx;
    _controller.animateTo(idx);
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant CoverFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncToInitial();
  }

  void _syncToInitial() {
    final idx = widget.initialIndex;
    if (idx < 0 || idx >= widget.items.length) return;
    _currentIndex = idx;
    _lastSyncedId = widget.items[idx].id;
    _controller.animateTo(idx);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    if (n == 0) {
      return Center(
        child: Text(
          '暂无数据',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final centerItem = widget.items[_currentIndex];
    final cs = Theme.of(context).colorScheme;
    final fg = cs.onSurface;
    final shadow = const Shadow(color: Colors.black45, blurRadius: 10);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        // 极大化计算卡片尺寸:
        // 竖屏：使用屏宽 88% 的超大卡片，只为底部保留必要的 110px 悬浮控制区域
        // 横屏：卡片以全屏高度为最大极限
        final bottomControlHeight = isLandscape ? 0.0 : 110.0;
        final availableHeight = constraints.maxHeight - bottomControlHeight;

        double cardSize;
        if (isLandscape) {
          cardSize = (constraints.maxHeight * 0.78).clamp(240.0, 520.0);
        } else {
          // 尽量取宽度的 88%，且不超过垂直最大可用空间
          final targetWidth = constraints.maxWidth * 0.88;
          cardSize = targetWidth.clamp(260.0, availableHeight * 0.85);
        }

        final carousel = CoverflowCarousel.builder(
          controller: _controller,
          itemCount: n,
          itemWidth: cardSize,
          itemHeight: cardSize,
          scrollDirection: Axis.horizontal,
          mode: CoverflowMode.coverflow,
          isInfinite: true,
          obscure: 0,
          // 调小 viewportFraction 使两侧堆叠卡片露出更多、视角更宽阔
          viewportFraction: isLandscape ? 0.45 : 0.68,
          enableShadow: true,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          elevation: 12,
          cardBorderRadius: AppRadius.cardBR,
          // 放大卡片间距适应更大号的封面
          nearCardSpacing: isLandscape ? 90 : 64,
          farCardSpacing: isLandscape ? 110 : 80,
          initialPage: widget.initialIndex,
          onPageChanged: (index) {
            _currentIndex = index;
            _lastSyncedId = widget.items[index].id;
            setState(() {});
            widget.onPageChanged?.call(widget.items[index]);
          },
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => widget.onItemTapped?.call(widget.items[index]),
              child: _CoverCard(item: widget.items[index]),
            );
          },
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. 核心轮播（微调位置，使其稍微偏上居中，平衡底部悬浮栏）
            Positioned.fill(
              child: Align(
                alignment: isLandscape
                    ? Alignment.center
                    : const Alignment(0.0, -0.15),
                child: SizedBox(
                  height: cardSize * 1.15, // 预留 3D 旋转溢出高度
                  child: carousel,
                ),
              ),
            ),

            // 2. 悬浮控制组件 (按屏幕形态响应式布局)
            if (isLandscape)
              Positioned(
                right: 24,
                top: 0,
                bottom: 0,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: cs.outlineVariant.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _OverlayButton(
                              onPressed: () => widget.onTogglePlay?.call(),
                              tooltip: '播放 / 暂停',
                              child: ValueListenableBuilder<bool>(
                                valueListenable: widget.isPlaying,
                                builder: (_, playing, _) => Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: fg,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _OverlayButton(
                              onPressed: () => _showInfoSheet(
                                context,
                                centerItem,
                                fg,
                                shadow,
                              ),
                              tooltip: '歌曲信息',
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Positioned(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(36),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 播放 / 暂停胶囊按钮
                          _OverlayButton(
                            onPressed: () => widget.onTogglePlay?.call(),
                            tooltip: '播放 / 暂停',
                            child: ValueListenableBuilder<bool>(
                              valueListenable: widget.isPlaying,
                              builder: (_, playing, _) => Icon(
                                playing
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: fg,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 当前卡片的标题文本快速浏览
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  centerItem.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: cs.onSurface,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  centerItem.subtitle,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 信息详情弹窗按钮
                          _OverlayButton(
                            onPressed: () =>
                                _showInfoSheet(context, centerItem, fg, shadow),
                            tooltip: '歌曲信息',
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: fg,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showInfoSheet(
    BuildContext context,
    CoverItem item,
    Color fg,
    Shadow shadow,
  ) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: AppRadius.cardBR,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              item.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// ── 悬浮磨砂控制按钮 ────────────────────────────────────────────────────────
class _OverlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final Widget child;

  const _OverlayButton({
    required this.onPressed,
    required this.tooltip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onPressed,
        icon: child,
        tooltip: tooltip,
        splashRadius: 24,
        padding: const EdgeInsets.all(10),
      ),
    );
  }
}

/// ── 单张卡片（极大化全高清显示） ──────────────────────────────────────────────
class _CoverCard extends StatelessWidget {
  final CoverItem item;

  const _CoverCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasCover =
        item.coverBytes?.isNotEmpty == true ||
        (item.imageUrl != null && item.imageUrl!.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardBR,
        color: cs.surfaceContainerHigh,
        gradient: hasCover
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withValues(alpha: 0.95),
                  item.color.withValues(alpha: 0.65),
                ],
              ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardBR,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 封面图（填满大卡片）
            _buildCover(),

            // 底部轻柔渐变（仅突出卡片内部的文本层，保持画面通透）
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 8),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover() {
    if (item.coverBytes?.isNotEmpty == true) {
      return Image.memory(item.coverBytes!, fit: BoxFit.cover);
    }
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        httpHeaders: item.imageUrl!.contains('music.126.net')
            ? {'Referer': 'https://music.163.com/'}
            : {},
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (_, _) => Container(
          color: item.color.withValues(alpha: 0.3),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (_, _, _) => Container(
          color: item.color.withValues(alpha: 0.3),
          child: const Icon(Icons.music_note, color: Colors.white54, size: 56),
        ),
      );
    }
    return Container(
      color: item.color.withValues(alpha: 0.3),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 56),
    );
  }
}
