import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/views/MusicDetail/widgets/cover_tab_content.dart';
import 'package:myapp/views/MusicDetail/widgets/lyrics_section.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';
import 'package:myapp/views/MusicDetail/widgets/playback_queue_drawer.dart';

class NarrowLayout extends StatefulWidget {
  final Music music;

  const NarrowLayout({super.key, required this.music});

  @override
  State<NarrowLayout> createState() => _NarrowLayoutState();
}

class _NarrowLayoutState extends State<NarrowLayout> {
  int _selectedSegment = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedSegment);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => context.pop(),
        ),
        title: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DotIndicator(isSelected: _selectedSegment == 0, onTap: () {
                setState(() => _selectedSegment = 0);
                _pageController.animateToPage(0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic);
              }),
              const SizedBox(width: 16),
              _DotIndicator(isSelected: _selectedSegment == 1, onTap: () {
                setState(() => _selectedSegment = 1);
                _pageController.animateToPage(1,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic);
              }),
            ],
          ),
        ),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              MusicActionMenu.showMoreOptions(context, details);
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.more_vert_rounded),
            ),
          ),
          const Padding(padding: EdgeInsets.only(right: 8)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _selectedSegment = index);
            },
            children: [
              CoverTabContent(music: widget.music),
              const LyricsSection(),
            ],
          ),
        ),
      ),
      endDrawer: PlaybackQueueDrawer(),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _DotIndicator({
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isSelected ? cs.primary : cs.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}