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
    final double height = MediaQuery.sizeOf(context).height;

    final colorScheme = Theme.of(context).colorScheme;
    final history = context.read<MusicProvider>().history;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Flutter 原生 CarouselView ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: height / 2),
                child: CarouselView.weighted(
                  itemSnapping: true,
                  controller: controller,
                  flexWeights: const <int>[1, 7, 1],
                  // 建议加上 tap 自动居中，这样交互更顺滑
                  onTap: (index) => controller.animateToItem(
                    index,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut, // 维持你想要的果冻感
                  ),
                  children: ImageInfo.values.map((image) {
                    return HeroLayoutCard(imageInfo: image);
                  }).toList(),
                ),
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
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text('播放全部'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      visualDensity: VisualDensity.compact,
                    ),
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
                selectedTileColor: colorScheme.surfaceContainer,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: SliverList.separated(
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () => context.push("/music/$index"),
                    leading: const Icon(Icons.library_music, size: 42),
                    title: Text(history[index].title),
                    subtitle: Text(
                      '${history[index].artist} · ${history[index].album}',
                    ),
                    horizontalTitleGap: 4,
                    trailing: const Icon(Icons.chevron_right),
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
    final double width = MediaQuery.sizeOf(context).width;
    return Stack(
      alignment: AlignmentDirectional.bottomStart,
      children: <Widget>[
        ClipRect(
          child: OverflowBox(
            maxWidth: width * 7 / 8,
            minWidth: width * 7 / 8,
            child: Image(
              fit: BoxFit.cover,
              // image: NetworkImage(
              //   'https://flutter.github.io/assets-for-api-docs/assets/material/${imageInfo.url}',
              // ),
              image: AssetImage(imageInfo.url),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                imageInfo.title,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                imageInfo.subtitle,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
