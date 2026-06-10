// ─── HomePage M3 极致简约改版 ─────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/config/globals.dart';
import 'package:myapp/model/Toplist/index.dart';
import 'package:myapp/router/Extensions/router.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/service/UpdateCheck/index.dart';
import 'package:myapp/views/Home/widgets/toplist_card.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum ImageInfo {
  image0("1", "", MyAssets.background),
  image1("2", "", MyAssets.background2),
  image2("3", "", MyAssets.background3),
  image3("4", "", MyAssets.background4),
  image4("5", "", MyAssets.background5);

  const ImageInfo(this.title, this.subtitle, this.url);
  final String title;
  final String subtitle;
  final String url;
}

class _HomePageState extends State<HomePage> {
  final CarouselController controller = CarouselController(initialItem: 1);
  bool _updateCheckStarted = false;
  ToplistInfo? _toplistInfo;

  @override
  void initState() {
    super.initState();
    // 首帧渲染完成后异步加载数据，不阻塞首页显示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_updateCheckStarted) {
        _updateCheckStarted = true;
        _checkForUpdate();
      }
      _fetchToplist();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _fetchToplist() async {
    final info = await MusicApi.fetchToplist();
    if (mounted) {
      setState(() {
        _toplistInfo = info;
      });
    }
  }

  /// 仅在 Android 平台检查更新，有新版则弹出更新弹窗
  Future<void> _checkForUpdate() async {
    if (!UpdateCheckService.isSupportedPlatform) return;

    try {
      final result = await UpdateCheckService.instance.checkForUpdate();
      if (!mounted) return;

      if (result.hasUpdate && result.latestRelease != null && mounted) {
        context.toUpdateDownload(result.latestRelease!);
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final library = context.watch<MusicProvider>().library;
    final history = playlistProvider.getHistorySongs(library);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          Header(
            pinned: true,
            leading: IconButton(
              onPressed: () {
                rootScaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(Icons.menu),
            ),
            title: Text(
              '发现',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
          ),

          // ── 2. M3 轮播图区域 ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double carouselHeight = (constraints.maxWidth * 0.52)
                      .clamp(160.0, 220.0);
                  return SizedBox(
                    height: carouselHeight,
                    child: CarouselView.weighted(
                      itemSnapping: true,
                      controller: controller,
                      flexWeights: const <int>[1, 7, 1],
                      onTap: (index) => controller.animateToItem(
                        index,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      ),
                      children: ImageInfo.values
                          .map((image) => HeroLayoutCard(imageInfo: image))
                          .toList(),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 3. 最近播放标题栏 ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '最近播放',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/user/recent'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                    label: const Icon(Icons.arrow_forward, size: 16),
                    icon: Text(
                      '查看更多',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. 最近播放横向列表 ────────────────────────────────────────────
          history.isEmpty
              ? SliverToBoxAdapter(
                  key: const ValueKey('history-empty'),
                  child: AppPanel(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: colorScheme.secondaryContainer,
                          foregroundColor: colorScheme.onSecondaryContainer,
                          child: const Icon(Icons.history_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "暂无历史播放\n快去听歌吧!",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverToBoxAdapter(
                  key: const ValueKey('history-list'),
                  child: SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: history.take(6).length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = history[index];
                        return ObservableMusicGridCard(
                          index: index,
                          music: item,
                          onTap: () {
                            final mp = context.read<MusicProvider>();
                            mp.replaceQueue(history, startIndex: index);
                            context.push('/music-detail');
                          },
                        );
                      },
                    ),
                  ),
                ),

          // ── 5. 排行榜模块 ──────────────────────────────────────────────────
          if (_toplistInfo != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  '热门榜单',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ToplistCard(
                  info: _toplistInfo!,
                  onTap: () => context.push('/toplist'),
                ),
              ),
            ),
          ],

          // 底部预留安全距离
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class HeroLayoutCard extends StatelessWidget {
  const HeroLayoutCard({super.key, required this.imageInfo});

  final ImageInfo imageInfo;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black38],
              stops: [0.6, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                imageInfo.title,
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (imageInfo.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  imageInfo.subtitle,
                  style: textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
