// ─── HomePage M3 极致简约改版 ─────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/config/globals.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
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
    final playlistProvider = context.watch<PlaylistProvider>();
    final library = context.watch<MusicProvider>().library;
    final history = playlistProvider.getHistorySongs(library);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // 根据 M3 黄金比例计算轮播图高度
    final double carouselHeight = (MediaQuery.sizeOf(context).width * 0.52)
        .clamp(160.0, 220.0);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. 标准 Material 3 顶栏（去毛玻璃，纯色联动） ─────────────────────────
          Header(
            pinned: true,
            leading: IconButton(
              onPressed: () {
                rootScaffoldKey.currentState?.openDrawer();
              },
              icon: const Icon(Icons.menu), // M3 标准抽屉图标
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
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: carouselHeight),
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
              ),
            ),
          ),

          // ── 3. 最近播放标题栏（M3 左右对齐规范） ──────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
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

          // ── 4. 最近播放横向列表 ─────────────────────────────────────────────
          history.isEmpty
              ? SliverToBoxAdapter(
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

          // // ── 5. 精选排行榜（M3 列表卡片化设计） ──────────────────────────────────
          // SliverToBoxAdapter(
          //   child: Padding(
          //     padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
          //     child: Text(
          //       '精选榜单',
          //       style: textTheme.titleMedium?.copyWith(
          //         fontWeight: FontWeight.bold,
          //         color: colorScheme.onSurface,
          //       ),
          //     ),
          //   ),
          // ),

          // SliverPadding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16),
          //   sliver: SliverList(
          //     delegate: SliverChildBuilderDelegate((context, index) {
          //       final List<String> rankTitles = ['飙升榜', '新歌榜', '原创榜'];

          //       // 使用 M3 容器色系的变体，保持色调高级统一，拒绝大红大绿的高饱和度脏感
          //       final List<Color> rankIconBackgrounds = [
          //         colorScheme.primaryContainer,
          //         colorScheme.secondaryContainer,
          //         colorScheme.tertiaryContainer,
          //       ];
          //       final List<Color> rankIconForegrounds = [
          //         colorScheme.onPrimaryContainer,
          //         colorScheme.onSecondaryContainer,
          //         colorScheme.onTertiaryContainer,
          //       ];

          //       return Padding(
          //         padding: const EdgeInsets.only(bottom: 12),
          //         child: Card(
          //           elevation: 0,
          //           // 使用 M3 标准的 surfaceContainerHighest，提供细腻的扁平层级感
          //           color: colorScheme.surfaceContainerHighest.withValues(
          //             alpha: 0.4,
          //           ),
          //           shape: RoundedRectangleBorder(
          //             borderRadius: BorderRadius.circular(16),
          //           ),
          //           child: InkWell(
          //             borderRadius: BorderRadius.circular(16),
          //             onTap: () {
          //               // 进入榜单详情
          //             },
          //             child: Padding(
          //               padding: const EdgeInsets.all(12),
          //               child: Row(
          //                 children: [
          //                   // M3 规范小方块封面
          //                   Container(
          //                     width: 72,
          //                     height: 72,
          //                     decoration: BoxDecoration(
          //                       color: rankIconBackgrounds[index],
          //                       borderRadius: BorderRadius.circular(12),
          //                     ),
          //                     child: Center(
          //                       child: Text(
          //                         rankTitles[index][0],
          //                         style: textTheme.titleMedium?.copyWith(
          //                           color: rankIconForegrounds[index],
          //                           fontWeight: FontWeight.bold,
          //                         ),
          //                       ),
          //                     ),
          //                   ),
          //                   const SizedBox(width: 16),
          //                   // 右侧直观透出前 3 名，极简而实用
          //                   Expanded(
          //                     child: Column(
          //                       crossAxisAlignment: CrossAxisAlignment.start,
          //                       children: [
          //                         Text(
          //                           '1. 歌曲名称 - 歌手',
          //                           style: textTheme.bodyMedium,
          //                           maxLines: 1,
          //                           overflow: TextOverflow.ellipsis,
          //                         ),
          //                         const SizedBox(height: 4),
          //                         Text(
          //                           '2. 舒缓旋律 - 创作人',
          //                           style: textTheme.bodyMedium,
          //                           maxLines: 1,
          //                           overflow: TextOverflow.ellipsis,
          //                         ),
          //                         const SizedBox(height: 4),
          //                         Text(
          //                           '3. 经典老歌 - 歌手',
          //                           style: textTheme.bodyMedium,
          //                           maxLines: 1,
          //                           overflow: TextOverflow.ellipsis,
          //                         ),
          //                       ],
          //                     ),
          //                   ),
          //                   // IconButton 换成符合 M3 规范的轻量化图标
          //                   Icon(
          //                     Icons.play_arrow_rounded,
          //                     color: colorScheme.primary,
          //                     size: 24,
          //                   ),
          //                 ],
          //               ),
          //             ),
          //           ),
          //         ),
          //       );
          //     }, childCount: 3),
          //   ),
          // ),

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
        // M3 卡片组件标准大圆角 (16~28dp)，这里采用标准的 16 纯扁平修剪
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image(
            image: AssetImage(imageInfo.url),
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // 极简纯黑渐变遮罩，只沉淀在底部 40% 的区域，不污染整张卡片
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
