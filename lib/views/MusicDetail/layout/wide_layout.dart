
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/views/MusicDetail/widgets/cover_content.dart';
import 'package:myapp/views/MusicDetail/widgets/lyrics_section.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';
import 'package:myapp/views/MusicDetail/widgets/playback_queue_drawer.dart';

class WideLayout extends StatelessWidget {
  final Music music;


  const WideLayout({super.key, required this.music});

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
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: CoverContent(music: music)),
                  const SizedBox(width: 24),
                  const Expanded(flex: 4, child: LyricsSection()),
                ],
              ),
            ),
          ),
        ),
      ),
      endDrawer: PlaybackQueueDrawer(),
    );
  }
}
