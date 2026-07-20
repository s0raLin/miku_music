// ─── CoverFlow 独立页面 ───────────────────────────────────────────────────────
//  3D 透视封面轮播：PageView + Matrix4 透视变换，
//  居中卡片放大凸出、两侧卡片绕 Y 轴旋转并向右后方沉陷，
//  滑动时随进度实时响应，松手自动吸附；支持无限循环、
//  上一/下一 按钮、圆点指示器。

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: '返回',
        ),
        title: const Text('封面轮播'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        // 深灰到纯黑的深色渐变背景，突出卡片主体
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.surface, Colors.black],
          ),
        ),
        child: SafeArea(
          child: Consumer<MusicProvider>(
            builder: (context, mp, _) {
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
                    .map((m) => CoverItem(
                          id: m.id.hashCode,
                          title: m.title,
                          subtitle: '${m.artist}  ·  ${m.album}',
                          imageUrl: mp.getCoverUrl(m.id),
                          coverBytes: m.coverBytes,
                          isNetwork: m.source == MusicSource.network,
                          color: _palette[m.id.hashCode %
                              _palette.length],
                        ))
                    .toList(),
                initialIndex: mp.currentMusic != null
                    ? mp.queue.indexOf(mp.currentMusic!).clamp(0, mp.queue.length - 1)
                    : 0,
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
                cardWidth: 220,
                cardHeight: 300,
                viewportFraction: 0.45,
              );
            },
          ),
        ),
      ),
    );
  }

  // 无封面时用作卡片渐变背景的调色板
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

/// ── Apple 风格 CoverFlow 组件 ──────────────────────────────────────────────
class CoverFlow extends StatefulWidget {
  final List<CoverItem> items;
  final int initialIndex;
  final void Function(CoverItem)? onItemTapped;
  final void Function(CoverItem)? onPageChanged;
  final double cardWidth;
  final double cardHeight;
  final double viewportFraction;

  const CoverFlow({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onItemTapped,
    this.onPageChanged,
    this.cardWidth = 180,
    this.cardHeight = 260,
    this.viewportFraction = 0.42,
  }) : assert(cardWidth > 0 && cardHeight > 0,
            '卡片宽高必须为正数');

  @override
  State<CoverFlow> createState() => _CoverFlowState();
}

class _CoverFlowState extends State<CoverFlow> {
  // ── 可调参数（类级常量，便于统一微调）──────────────────────────────
  static const double _kMaxRotation = 25.0; // 两侧最大旋转角(度)
  static const double _kScaleCenter = 1.0; // 中心缩放
  static const double _kScaleEdge = 0.7; // 两侧最小缩放
  static const double _kOpacityEdge = 0.6; // 两侧最小透明度
  static const double _kZEdge = -40.0; // 两侧向后沉陷的 Z 偏移(px)
  static const double _kShadowCenter = 0.45; // 中心阴影强度
  static const double _kShadowEdge = 0.12; // 两侧阴影强度
  static const int _kVirtualCount = 100000; // 虚拟页数（实现无限循环）

  late final PageController _pageController;
  late int _currentIndex;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final n = widget.items.length;
    // 从虚拟序列中间某个对齐到真实数据的位置出发，确保首尾都能无限前滚/后滚
    _currentIndex = (n > 0 ? widget.initialIndex : 0) + n * 100;
    _pageController = PageController(
      viewportFraction: widget.viewportFraction,
      initialPage: _currentIndex,
    );
    _currentPage = _currentIndex.toDouble();
    _pageController.addListener(() {
      final page = _pageController.page;
      if (page != null && page != _currentPage) {
        // 监听滚动，随进度实时更新中心距离，实现滑动时 3D 变换平滑响应
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 取模映射：把虚拟页索引换算为真实的 CoverItem
  CoverItem _itemAt(int virtualIndex) {
    final n = widget.items.length;
    if (n == 0) throw StateError('items 不能为空');
    // 处理负数取模，保证结果在 [0, n) 区间
    final real = ((virtualIndex % n) + n) % n;
    return widget.items[real];
  }

  /// 平滑切换到相邻卡片（上一 / 下一）
  void _animateTo(int target) {
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    if (n == 0) {
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.white70)),
      );
    }

    // 当前真实索引（用于顶部标题与底部圆点指示器）
    final realIndex = ((_currentIndex % n) + n) % n;
    final centerItem = _itemAt(_currentIndex);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 顶部：当前选中卡片标题
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Column(
            children: [
              Text(
                centerItem.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                centerItem.subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // 主体：3D 轮播
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _kVirtualCount,
            onPageChanged: (idx) {
              if (idx == _currentIndex) return;
              setState(() => _currentIndex = idx);
              widget.onPageChanged?.call(_itemAt(idx));
            },
            itemBuilder: (context, virtualIndex) {
              // 与中心的「带符号距离」，0=正中间，负=左侧，正=右侧
              final pageDelta = virtualIndex - _currentPage;
              // 距离的绝对值限制在 [0,1]，便于做线性插值
              final absDelta = pageDelta.abs().clamp(0.0, 1.0);

              // 旋转：左侧 +角，右侧 -角，随距离线性变化
              final rotation = pageDelta * _kMaxRotation;
              // 缩放：中心 1.0 → 两侧 0.7
              final scale = _lerp(_kScaleCenter, _kScaleEdge, absDelta);
              // 透明度：中心 1.0 → 两侧 0.6
              final opacity = _lerp(1.0, _kOpacityEdge, absDelta);
              // Z 轴偏移：中心 0 → 两侧向后沉陷(负值)
              final translateZ = _lerp(0.0, _kZEdge, absDelta);
              // 阴影：中心最重，两侧最轻
              final shadowAlpha = _lerp(_kShadowCenter, _kShadowEdge, absDelta);
              final isCenter = absDelta < 0.01;

              return _CoverCard(
                item: _itemAt(virtualIndex),
                width: widget.cardWidth,
                height: widget.cardHeight,
                isCenter: isCenter,
                scale: scale,
                rotation: rotation,
                opacity: opacity,
                translateZ: translateZ,
                shadowAlpha: shadowAlpha,
                onTap: () => widget.onItemTapped?.call(_itemAt(virtualIndex)),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // 底部：上一 / 下一 按钮 + 圆点指示器
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _animateTo(_currentIndex - 1),
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
              tooltip: '上一张',
            ),
            _DotsIndicator(
              count: n,
              currentIndex: realIndex,
              color: Colors.white,
            ),
            IconButton(
              onPressed: () => _animateTo(_currentIndex + 1),
              icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
              tooltip: '下一张',
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 线性插值：t=0 返回 a，t=1 返回 b
  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

/// ── 单张 3D 卡片 ──────────────────────────────────────────────────────────
class _CoverCard extends StatefulWidget {
  final CoverItem item;
  final double width;
  final double height;
  final bool isCenter;
  final double scale;
  final double rotation;
  final double opacity;
  final double translateZ;
  final double shadowAlpha;
  final VoidCallback onTap;

  const _CoverCard({
    required this.item,
    required this.width,
    required this.height,
    required this.isCenter,
    required this.scale,
    required this.rotation,
    required this.opacity,
    required this.translateZ,
    required this.shadowAlpha,
    required this.onTap,
  });

  @override
  State<_CoverCard> createState() => _CoverCardState();
}

class _CoverCardState extends State<_CoverCard>
    with SingleTickerProviderStateMixin {
  // 点击时的缩放回弹（先缩到 0.95 再恢复）
  late final AnimationController _tapCtrl;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _tapCtrl.reverse();
      }
    });
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // 优先用真实封面图；无封面时用调色板同色系渐变兜底
    final hasCover =
        widget.item.coverBytes?.isNotEmpty == true ||
        (widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty);

    final card = GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTap: widget.onTap,
      child: Opacity(
        opacity: widget.opacity,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            // 开启透视：第 4 行第 3 列设一个小数，制造近大远小
            ..setEntry(3, 2, 0.001)
            // 绕 Y 轴旋转（弧度）
            ..rotateY(widget.rotation * math.pi / 180)
            // 缩放
            ..scale(widget.scale)
            // 沿 Z 轴平移（负值=向后沉陷）
            ..translate(0.0, 0.0, widget.translateZ),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              // 柔和阴影，中心最重、两侧最轻（由 shadowAlpha 控制）
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.shadowAlpha),
                  blurRadius: widget.isCenter ? 30 : 14,
                  spreadRadius: widget.isCenter ? 2 : 0,
                  offset: const Offset(0, 12),
                ),
              ],
              // 渐变背景色（无封面时用卡片 color 生成同色系渐变）
              gradient: hasCover
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.item.color.withValues(alpha: 0.95),
                        widget.item.color.withValues(alpha: 0.65),
                      ],
                    ),
              color: hasCover ? null : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCover(cs),
                  // 底部标题：白色带阴影
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                      child: Text(
                        widget.item.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _tapScale,
        builder: (_, child) => Transform.scale(
          scale: _tapScale.value,
          child: child,
        ),
        child: card,
      ),
    );
  }

  Widget _buildCover(ColorScheme cs) {
    final item = widget.item;
    // 1. 内存字节封面（本地歌曲常见）
    if (item.coverBytes?.isNotEmpty == true) {
      return Image.memory(item.coverBytes!, fit: BoxFit.cover);
    }
    // 2. 网络封面（带网易云防盗链 Referer）
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: item.imageUrl!,
        fit: BoxFit.cover,
        httpHeaders: item.imageUrl!.contains('music.126.net')
            ? {'Referer': 'https://music.163.com/'}
            : {},
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => const SizedBox.shrink(),
        errorWidget: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    // 3. 无封面：已在 Container 渐变兜底，这里返回空
    return const SizedBox.shrink();
  }
}

/// ── 圆点指示器（窗口化：数量多时只显示以当前点为中心的若干点）──────────────
class _DotsIndicator extends StatelessWidget {
  final int count;
  final int currentIndex;
  final Color color;

  const _DotsIndicator({
    required this.count,
    required this.currentIndex,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();

    const maxVisible = 11; // 最多可见圆点数（奇数，便于居中）
    const sideDots = (maxVisible - 1) ~/ 2;

    List<int> visible;
    if (count <= maxVisible) {
      visible = List.generate(count, (i) => i);
    } else {
      // 滑动窗口：以当前点为中心，向两侧各展开 sideDots 个
      int start = currentIndex - sideDots;
      int end = currentIndex + sideDots;
      // 处理窗口越界（头/尾处补满）
      if (start < 0) {
        start = 0;
        end = maxVisible - 1;
      } else if (end >= count) {
        end = count - 1;
        start = end - maxVisible + 1;
      }
      visible = [for (int i = start; i <= end; i++) i];
    }

    return SizedBox(
      height: 8,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final idx = visible[i];
          final active = idx == currentIndex;
          final isEdge = idx == visible.first || idx == visible.last;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: active ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3.5),
              color: active
                  ? color
                  : (isEdge
                      ? color.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.4)),
            ),
          );
        },
      ),
    );
  }
}
