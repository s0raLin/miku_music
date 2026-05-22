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

  final double _cardWidth = 280.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final screenWidth = MediaQuery.of(context).size.width;
    final fraction = (_cardWidth / screenWidth).clamp(0.22, 0.75);

    _pageController = PageController(viewportFraction: fraction);
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    setState(() {
      _currentPage = _pageController.page ?? 0.0;
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
    final mp = context.read<MusicProvider>();
    final queue = mp.queue;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text("Now Playing"),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: queue.isEmpty
          ? _buildEmptyState(context)
          : Center(
              child: SizedBox(
                height: _cardWidth + 120,
                child: PageView.builder(
                  controller: _pageController,
                  clipBehavior: Clip.none,
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final music = queue[index];
                    final relativePos = index - _currentPage;

                    return _buildMusicCard(
                      music: music,
                      relativePosition: relativePos,
                      onTap: () {
                        mp.playByIndex(index);
                        context.push('/music-detail', extra: music);
                      },
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Text(
        "队列为空",
        style: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMusicCard({
    required MusicInfo music,
    required double relativePosition,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // M3 风格的轻微 3D 效果
    final scale = (1 - (relativePosition.abs() * 0.18)).clamp(0.75, 1.0);
    final rotation = (relativePosition * 0.15).clamp(-0.8, 0.8);

    return Center(
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // 轻微透视
          ..scale(scale)
          ..rotateY(rotation),
        alignment: Alignment.center,
        child: SizedBox(
          width: _cardWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                elevation: 1,
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child:
                        music.coverBytes != null && music.coverBytes!.isNotEmpty
                        ? Image.memory(
                            music.coverBytes!,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
                          )
                        : Container(
                            color: colorScheme.surfaceContainer,
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                music.title,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                music.artist,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
