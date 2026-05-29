import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/views/MusicDetail/widgets/cover_tab_content.dart';
import 'package:myapp/views/MusicDetail/widgets/lyrics_section.dart';
import 'package:myapp/views/MusicDetail/widgets/playback_queue_drawer.dart';

class NarrowLayout extends StatefulWidget {
  final Music music;
  final bool isLiked;

  const NarrowLayout({super.key, required this.music, required this.isLiked});

  @override
  State<NarrowLayout> createState() => _NarrowLayoutState();
}

class _NarrowLayoutState extends State<NarrowLayout> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "正在播放",
          style: tt.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              AdaptiveMenu.show(
                title: "更多选项",
                context,
                items: [AdaptiveMenuItem(title: "设置进度条样式", onTap: () {})],
                details: details,
              );
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
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(
                      value: 0,
                      icon: Icon(Icons.album_rounded),
                      label: Text('播放'),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      icon: Icon(Icons.lyrics_rounded),
                      label: Text('歌词'),
                    ),
                  ],
                  selected: {_selectedSegment},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedSegment = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: KeyedSubtree(
                    key: ValueKey(_selectedSegment),
                    child: _selectedSegment == 0
                        ? CoverTabContent(music: widget.music)
                        : const LyricsSection(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: PlaybackQueueDrawer(),
    );
  }
}
