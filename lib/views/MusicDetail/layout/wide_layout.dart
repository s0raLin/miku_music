import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/views/MusicDetail/widgets/cover_tab_content.dart';
import 'package:myapp/views/MusicDetail/widgets/lyrics_section.dart';

class WideLayout extends StatelessWidget {
  final MusicInfo music;
  final bool isLiked;

  const WideLayout({super.key, required this.music, required this.isLiked});

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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('正在播放', style: tt.labelMedium),
            Text(
              music.title,
              style: tt.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
                  Expanded(
                    flex: 5,
                    child: CoverTabContent(music: music, isLiked: isLiked),
                  ),
                  const SizedBox(width: 24),
                  const Expanded(flex: 4, child: LyricsSection()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
