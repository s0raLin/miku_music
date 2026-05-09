import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class CoverFlowPage extends StatefulWidget {
  const CoverFlowPage({super.key});

  @override
  State<CoverFlowPage> createState() => _CoverFlowPageState();
}

class _CoverFlowPageState extends State<CoverFlowPage> {
  late PageController _pageController;
  double _currentPage = 0.0;

  // 设定一个你认为最舒服的卡片物理宽度
  final double _idealCardWidth = 300.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ 动态计算 viewportFraction：确保卡片间距紧凑
    // 如果屏幕宽 1200，卡片宽 300，比例就是 0.25
    double screenWidth = MediaQuery.of(context).size.width;
    double fraction = (_idealCardWidth / screenWidth).clamp(0.2, 0.8);

    _pageController = PageController(viewportFraction: fraction);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final mp = context.read<MusicProvider>();
    final queue = mp.queue;

    return Scaffold(
      // 使用 M3 标准的表面颜色
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Now Playing"),
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: queue.isEmpty
          ? _buildEmptyState(colorScheme, textTheme)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: _idealCardWidth + 80, // 预留文字空间
                    child: PageView.builder(
                      controller: _pageController,
                      clipBehavior: Clip.none, // 允许左右卡片超出边界显示，增加紧凑感
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        double relativePosition = index - _currentPage;
                        final music = queue[index];
                        return _buildM3Card(
                          music,
                          relativePosition,
                          context,
                          onTap: () {
                            context.push('/music-detail');
                            mp.playByIndex(index);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, TextTheme textTheme) {
    return Center(
      child: Text(
        "队列为空",
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildM3Card(
    MusicInfo music,
    double relativePosition,
    BuildContext context, {
    required VoidCallback onTap,
  }) {
    // 变换逻辑：侧边卡片稍微缩小并旋转
    final double scale = (1 - (relativePosition.abs() * 0.15)).clamp(0.0, 1.0);
    final double rotation = (relativePosition * 0.2).clamp(-1.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Container(
        width: _idealCardWidth,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..scale(scale)
          ..rotateY(rotation),
        transformAlignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 卡片主体
            Card(
              elevation: 0, // M3 风格倾向于使用色调变化而非深阴影
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28), // M3 典型的圆角
                side: BorderSide(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
              color: colorScheme.surfaceContainerHigh,
              child: InkWell(
                onTap: onTap,
                child: AspectRatio(
                  aspectRatio: 1,
                  child:
                      music.coverBytes != null && music.coverBytes!.isNotEmpty
                      ? Image.memory(
                          music.coverBytes!,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium, // 兼顾性能与清晰度
                        )
                      : Icon(Icons.music_note_rounded),
                ),
              ),
            ),

            const SizedBox(height: 16),
            // 文字部分：使用 FittedBox 解决越界，使用 M3 字体样式
            SizedBox(
              width: _idealCardWidth * 0.8,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  music.title,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
