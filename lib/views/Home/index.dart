// ─── HomePage ─────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/contants/Assets/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
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
    final history = context.read<MusicProvider>().history;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Flutter 原生 CarouselView ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxCarouselWidth = constraints.maxWidth > 1800
                      ? 1700.0
                      : constraints.maxWidth;
                  final aspectRatio = constraints.maxWidth > 900 ? 21 / 9 : 16 / 9;
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxCarouselWidth),
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: CarouselView.weighted(
                          itemSnapping: true,
                          controller: controller,
                          flexWeights: const <int>[1, 7, 1],
                          padding: EdgeInsets.zero,
                          onTap: (index) => controller.animateToItem(
                            index,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                          ),
                          children: ImageInfo.values
                              .map((image) => HeroLayoutCard(imageInfo: image))
                              .toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── 歌曲推荐标题栏 ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
              child: Row(
                children: [
                  Text(
                    '歌曲推荐',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('播放全部'),
                  ),
                ],
              ),
            ),
          ),

          // ── 歌曲列表 ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: ListTileTheme(
              data: ListTileThemeData(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: SliverList.separated(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      onTap: () => context.push("/music/$index"),
                      leading: const Icon(Icons.library_music, size: 42),
                      title: Text(history[index].title),
                      subtitle: Text(
                        '${history[index].artist} · ${history[index].album}',
                      ),
                      horizontalTitleGap: 4,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  );
                },
                separatorBuilder: (_, _) => const SizedBox(height: 6),
              ),
            ),
          ),
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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
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
                style: textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                imageInfo.subtitle,
                style: textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
