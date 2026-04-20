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
    final colorScheme = Theme.of(context).colorScheme;
    final history = context.read<MusicProvider>().history;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Flutter 原生 CarouselView ──────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
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
    return Stack(
      fit: StackFit.expand, // ← 关键：让 Stack 充满父容器
      children: [
        // 图片部分 - 确保完全充满
        ClipRRect(
          // 推荐换成 ClipRRect，支持圆角（如果需要）
          borderRadius: BorderRadius.circular(16), // 可根据设计加圆角
          child: Image(
            image: AssetImage(imageInfo.url),
            fit: BoxFit.cover, // cover 会自动裁剪并充满，无空白
            width: double.infinity, // 强制宽度充满
            height: double.infinity, // 强制高度充满（配合 StackFit.expand）
          ),
        ),

        // 文字叠加层
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end, // 文字靠底对齐
            children: [
              Text(
                imageInfo.title,
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                imageInfo.subtitle,
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
