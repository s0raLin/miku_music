// ─── CoverFlow 独立页面 - 基于 coverflow_carousel 库 ──────────────────────────
//  使用 coverflow_carousel 提供的 3D Cover Flow 轮播组件，
//  支持数据驱动、平滑透视、重叠卡片与程序化导航。

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
      body: Consumer<MusicProvider>(
        builder: (context, mp, _) {
          final coverBytes = mp.currentMusic?.coverBytes;
          final coverUrl =
              mp.currentMusic != null
                  ? mp.getCoverUrl(mp.currentMusic!.id)
                  : null;
          final hasCover =
              (coverBytes?.isNotEmpty ?? false) ||
              (coverUrl != null && coverUrl.isNotEmpty);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 当前播放封面作为模糊背景
              if (hasCover)
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      coverBytes?.isNotEmpty == true
                          ? Image.memory(
                              coverBytes!,
                              fit: BoxFit.cover,
                            )
                          : CachedNetworkImage(
                              imageUrl: coverUrl!,
                              fit: BoxFit.cover,
                              httpHeaders: coverUrl.contains('music.126.net')
                                  ? {'Referer': 'https://music.163.com/'}
                                  : {},
                            ),
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 60,
                            sigmaY: 60,
                          ),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                      // 暗化蒙层，保证文字可读
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.35),
                              Colors.black.withValues(alpha: 0.65),
                            ],
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
                      colors: [cs.surface, Colors.black],
                    ),
                  ),
                ),

              // 前景内容
              SafeArea(
                child: Builder(
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
                      onItemTapped: (item) {
                        final idx = mp.queue.indexWhere(
                          (m) => m.id.hashCode == item.id,
                        );
                        if (idx >= 0 &&
                            mp.queue[idx].id != mp.currentMusic?.id) {
                          mp.playByIndex(idx);
                        }
                      },
                      onPageChanged: (item) {
                        final idx = mp.queue.indexWhere(
                          (m) => m.id.hashCode == item.id,
                        );
                        if (idx >= 0 &&
                            mp.queue[idx].id != mp.currentMusic?.id) {
                          mp.playByIndex(idx);
                        }
                      },
                    );
                  },
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

/// ── 基于 coverflow_carousel 的 Cover Flow 组件 ──────────────────────────────
class CoverFlow extends StatefulWidget {
  final List<CoverItem> items;
  final int initialIndex;
  final void Function(CoverItem)? onItemTapped;
  final void Function(CoverItem)? onPageChanged;
  final double itemWidth;
  final double itemHeight;

  const CoverFlow({
    super.key,
    required this.items,
    this.initialIndex = 0,
    this.onItemTapped,
    this.onPageChanged,
    this.itemWidth = 200,
    this.itemHeight = 200,
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
    if (widget.initialIndex >= 0 &&
        widget.initialIndex < widget.items.length) {
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

  // 播放中的歌曲变化（如自动下一首）时，让轮播跟随定位到该卡片
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
      return const Center(
        child: Text('暂无数据', style: TextStyle(color: Colors.white70)),
      );
    }

    final centerItem = widget.items[_currentIndex];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 歌曲信息
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

        const SizedBox(height: 20),

        // 3D Cover Flow 轮播
        SizedBox(
          height: widget.itemHeight + 60,
          child: CoverflowCarousel.builder(
            controller: _controller,
            itemCount: n,
            itemWidth: widget.itemWidth,
            itemHeight: widget.itemHeight,
            scrollDirection: Axis.horizontal,
            mode: CoverflowMode.coverflow,
            isInfinite: true,
            obscure: 0,
            viewportFraction: 0.32,
            enableShadow: false,
            elevation: 0,
            cardBorderRadius: BorderRadius.circular(18),
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
          ),
        ),

        const SizedBox(height: 16),

        // 导航按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () => _controller.previous(),
              icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
              iconSize: 32,
              tooltip: '上一张',
            ),
            const SizedBox(width: 32),
            IconButton(
              onPressed: () => _controller.next(),
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
              ),
              iconSize: 32,
              tooltip: '下一张',
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// ── 单张卡片 ───────────────────────────────────────────────────────────────
class _CoverCard extends StatelessWidget {
  final CoverItem item;

  const _CoverCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final hasCover =
        item.coverBytes?.isNotEmpty == true ||
        (item.imageUrl != null && item.imageUrl!.isNotEmpty);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
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
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 封面图片
            _buildCover(),

            // 底部渐变 + 标题
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
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
                child: Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => Container(
          color: item.color.withValues(alpha: 0.3),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white54,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: item.color.withValues(alpha: 0.3),
          child: const Icon(Icons.music_note, color: Colors.white54, size: 48),
        ),
      );
    }
    return Container(
      color: item.color.withValues(alpha: 0.3),
      child: const Icon(Icons.music_note, color: Colors.white54, size: 48),
    );
  }
}
