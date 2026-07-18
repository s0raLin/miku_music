// ─── CoverFlow 独立页面 ───────────────────────────────────────────────────────
//  全屏展示 3D 透视专辑封面轮播。

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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: '返回',
        ),
        title: const Text('封面轮播'),
        centerTitle: true,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<MusicProvider>(
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
          return const CoverFlow();
        },
      ),
    );
  }
}

// ─── CoverFlow ─────────────────────────────────────────────────────────────────
//  3D 透视专辑轮播：队列中的歌曲以带景深效果的横向封面卡片展示，居中卡片放大高亮。

class CoverFlow extends StatefulWidget {
  final double coverHeight;

  const CoverFlow({super.key, this.coverHeight = 340});

  @override
  State<CoverFlow> createState() => _CoverFlowState();
}

class _CoverFlowState extends State<CoverFlow> {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final mp = context.read<MusicProvider>();
    final music = mp.currentMusic;
    final queue = mp.queue;
    final initialIdx = music != null ? queue.indexOf(music) : 0;
    _pageController = PageController(
      viewportFraction: 0.62,
      initialPage: initialIdx.clamp(0, (queue.length - 1).clamp(0, queue.length)),
    );
    _currentPage = _pageController.initialPage.toDouble();
    _pageController.addListener(() {
      final page = _pageController.page;
      if (page != null && page != _currentPage) {
        setState(() => _currentPage = page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MusicProvider>();
    final queue = mp.queue;
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: queue.length,
            onPageChanged: (idx) {
              if (queue[idx].id != mp.currentMusic?.id) {
                mp.playByIndex(idx);
              }
            },
            itemBuilder: (context, idx) {
              final pageDelta = idx - _currentPage;
              final absDelta = pageDelta.abs().clamp(0.0, 1.0);

              final rotationY = pageDelta * 0.42;
              final scale = 1.0 - absDelta * 0.18;
              final opacity = (1.0 - absDelta * 0.45).clamp(0.15, 1.0);
              final offsetY = absDelta * 24;
              final isCenter = absDelta < 0.01;

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: opacity,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0012)
                    ..rotateY(rotationY)
                    ..scale(scale)
                    ..translate(0.0, offsetY, 0.0),
                  child: _CoverCard(
                    music: queue[idx],
                    height: widget.coverHeight,
                    isCenter: isCenter,
                  ),
                ),
              );
            },
          ),
        ),
        // ── 进度指示 ──
        _PositionIndicator(
          currentIndex: _currentPage.round(),
          count: queue.length,
          accent: cs.primary,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PositionIndicator extends StatefulWidget {
  final int currentIndex;
  final int count;
  final Color accent;

  const _PositionIndicator({
    required this.currentIndex,
    required this.count,
    required this.accent,
  });

  @override
  State<_PositionIndicator> createState() => _PositionIndicatorState();
}

class _PositionIndicatorState extends State<_PositionIndicator> {
  @override
  Widget build(BuildContext context) {
    final count = widget.count;
    if (count <= 1) return const SizedBox.shrink();

    final shown = count > 30 ? 30 : count;
    return SizedBox(
      height: 6,
      child: ListView.separated(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: shown,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final active = i == widget.currentIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: active ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: active
                  ? widget.accent
                  : widget.accent.withValues(alpha: 0.25),
            ),
          );
        },
      ),
    );
  }
}

class _CoverCard extends StatelessWidget {
  final Music music;
  final double height;
  final bool isCenter;

  const _CoverCard({
    required this.music,
    required this.height,
    required this.isCenter,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mp = context.watch<MusicProvider>();
    final coverUrl = mp.getCoverUrl(music.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 封面 ──
          Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: isCenter ? 0.22 : 0.08),
                  blurRadius: isCenter ? 32 : 16,
                  spreadRadius: isCenter ? 2 : 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildCover(cs, coverUrl),
            ),
          ),
          const SizedBox(height: 16),
          // ── 居中卡片的歌曲信息 ──
          AnimatedOpacity(
            opacity: isCenter ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 220),
            child: SizedBox(
              width: height * 0.9,
              child: Column(
                children: [
                  Text(
                    music.title,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${music.artist}  ·  ${music.album}',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(ColorScheme cs, String? coverUrl) {
    if (music.coverBytes?.isNotEmpty == true) {
      return Image.memory(music.coverBytes!, fit: BoxFit.cover);
    }
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl,
        fit: BoxFit.cover,
        httpHeaders: coverUrl.contains('music.126.net')
            ? {'Referer': 'https://music.163.com/'}
            : {},
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, __) => _fallback(cs),
        errorWidget: (_, __, ___) => _fallback(cs),
      );
    }
    return _fallback(cs);
  }

  Widget _fallback(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.surfaceContainerHighest,
            cs.surfaceContainerHighest.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: height * 0.3,
        color: cs.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
