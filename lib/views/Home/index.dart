// ─── HomePage ─────────────────────────────────────────────────────────────────
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentBanner = 0;

  // 模拟数据
  static const List<Map<String, String>> _banners = [
    {'title': '每日推荐', 'sub': '为你精选的好音乐'},
    {'title': '新歌首发', 'sub': '最新上线单曲'},
    {'title': '热门榜单', 'sub': '今日最火歌曲'},
    {'title': '独家专辑', 'sub': '艺人新专辑'},
    {'title': '电台精选', 'sub': '陪你度过每一天'},
  ];

  static const List<Map<String, dynamic>> _songs = [
    {'title': '夜曲', 'artist': '周杰伦', 'album': '十一月的萧邦'},
    {'title': '晴天', 'artist': '周杰伦', 'album': '叶惠美'},
    {'title': '稻香', 'artist': '周杰伦', 'album': '魔杰座'},
    {'title': '七里香', 'artist': '周杰伦', 'album': '七里香'},
    {'title': '告白气球', 'artist': '周杰伦', 'album': '周杰伦的床边故事'},
    {'title': '青花瓷', 'artist': '周杰伦', 'album': '我很忙'},
    {'title': '简单爱', 'artist': '周杰伦', 'album': '范特西'},
    {'title': '双截棍', 'artist': '周杰伦', 'album': '范特西'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ── Banner 轮播 ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Column(
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 300,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.15,
                    viewportFraction: 0.88,
                    autoPlayCurve: Curves.easeInOut,
                    onPageChanged: (index, _) =>
                        setState(() => _currentBanner = index),
                  ),
                  items: _banners.asMap().entries.map((entry) {
                    final i = entry.key;
                    final banner = entry.value;
                    // 用色相偏移模拟不同封面颜色
                    final colors = [
                      colorScheme.primaryContainer,
                      colorScheme.secondaryContainer,
                      colorScheme.tertiaryContainer,
                      colorScheme.surfaceContainerHighest,
                      colorScheme.inversePrimary,
                    ];
                    return Builder(
                      builder: (context) => Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: colors[i % colors.length],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                banner['title']!,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner['sub']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onPrimaryContainer
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                // 指示点
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _banners.asMap().entries.map((e) {
                    final active = e.key == _currentBanner;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: active
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // ── 歌曲推荐标题栏 ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
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
            sliver: SliverList.separated(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return _SongTile(
                  index: index,
                  title: song['title']!,
                  artist: song['artist']!,
                  album: song['album']!,
                  onTap: () => context.push('/music/$index'),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final int index;
  final String title;
  final String artist;
  final String album;
  final VoidCallback onTap;

  const _SongTile({
    required this.index,
    required this.title,
    required this.artist,
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // 序号 / 封面占位
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.primaryContainer,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 标题 + 艺术家
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$artist · $album',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.outlineVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
