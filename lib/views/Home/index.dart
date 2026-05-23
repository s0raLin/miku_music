// ─── HomePage ─────────────────────────────────────────────────────────────────
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/config/globals.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum ImageInfo {
  image0("1", "", MyAssets.background),
  image1("2", "", MyAssets.background2),
  image2("3", "", MyAssets.background3),
  image3("4", "", MyAssets.background4);

  const ImageInfo(this.title, this.subtitle, this.url);
  final String title;
  final String subtitle;
  final String url;
}

class _HomePageState extends State<HomePage> {
  final CarouselController controller = CarouselController(initialItem: 1);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = context.watch<MusicProvider>().history;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final double carouselHeight = (MediaQuery.sizeOf(context).width * 0.5)
        .clamp(160.0, 220.0); // 最小160，最大220

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leading: IconButton(
              onPressed: () {
                rootScaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(Icons.menu),
            ),
            pinned: true,
            title: const Text('发现'),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () {
                  context.push("/settings");
                },
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          // ── 轮播图区域 ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: carouselHeight),
                  child: CarouselView.weighted(
                    itemSnapping: true,
                    controller: controller,
                    flexWeights: const <int>[1, 7, 1],

                    onTap: (index) => controller.animateToItem(
                      index,
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                    ),
                    children: ImageInfo.values
                        .map((image) => HeroLayoutCard(imageInfo: image))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),

          // ── 最近播放标题栏 ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: AppSectionHeader(
                title: '最近播放',
                subtitle: '继续你最近在听的内容',
                action: TextButton(
                  onPressed: () => context.push('/user/recent'),
                  child: const Text('查看更多'),
                ),
              ),
            ),
          ),

          // ── 最近播放横向列表 ─────────────────────────────────────────────────
          history.isEmpty
              ? SliverToBoxAdapter(
                  child: SizedBox(
                    height: 150,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 32,
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '暂无播放记录',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  child: SizedBox(
                    height: 186,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: history.take(6).length,
                      separatorBuilder: (BuildContext context, int index) {
                        return SizedBox(width: 4);
                      },
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return ObservableMusicListItem(
                          index: index,
                          music: item,
                          onTap: () {
                            final mp = context.read<MusicProvider>();
                            mp.replaceQueue(mp.history, startIndex: index);
                            context.push('/music-detail');
                          },
                        );
                      },
                    ),
                  ),
                ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: AppSectionHeader(title: '排行榜'),
            ),
          ),
        ],
      ),
    );
  }
}

class ObservableMusicListItem extends StatefulWidget {
  final int index;
  final MusicInfo music;
  final VoidCallback? onTap;

  const ObservableMusicListItem({
    super.key,
    required this.music,
    this.onTap,
    required this.index,
  });

  @override
  State<ObservableMusicListItem> createState() =>
      _ObservableMusicListItemState();
}

class _ObservableMusicListItemState extends State<ObservableMusicListItem> {
  Uint8List? _coverBytes;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('initState: ${widget.music.title}');
    _loadCover();
  }

  // 加这个方法
  Future<Uint8List?> _resizeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 144,
      targetHeight: 144,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    return byteData?.buffer.asUint8List();
  }

  void _loadCover() async {
    if (widget.music.coverBytes != null &&
        widget.music.coverBytes!.isNotEmpty) {
      // 已有封面也压缩后再用
      final small = await _resizeImage(widget.music.coverBytes!);
      if (!mounted) return;
      setState(() {
        _coverBytes = small;
        widget.music.coverBytes = small; // 回写小图，下次直接用
      });
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final updatedMusic = await MusicService.parse(widget.music.id);
      final small = await _resizeImage(updatedMusic.coverBytes!);
      if (mounted) {
        setState(() {
          _coverBytes = small;
          widget.music.coverBytes = small; // 回写小图
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = Stopwatch()..start();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final badgeBackground = colorScheme.surfaceContainerHigh.withValues(
      alpha: colorScheme.brightness == Brightness.dark ? 0.88 : 0.82,
    );

    final w = SizedBox(
      width: 156,
      child: MediaGridCard(
        title: widget.music.title,
        subtitle: widget.music.artist,
        coverBytes: _coverBytes,
        fallbackIcon: Icon(Icons.music_note_rounded, size: 32),
        coverAspectRatio: 1.28,
        titleLines: 1,
        contentSpacing: 2,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        onTap: widget.onTap,
        badge: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBackground,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '#${widget.index + 1}',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
    ;
    debugPrint('AlbumDetailPage build: ${sw.elapsedMilliseconds}ms');
    return w;
  }
}

class HeroLayoutCard extends StatelessWidget {
  const HeroLayoutCard({super.key, required this.imageInfo});

  final ImageInfo imageInfo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image(
            image: AssetImage(imageInfo.url),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                colorScheme.scrim.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                imageInfo.title,
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.onInverseSurface,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                imageInfo.subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onInverseSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
