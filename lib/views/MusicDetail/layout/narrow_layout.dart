import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/MusicDetail/widgets/cover_tab_content.dart';
import 'package:myapp/views/MusicDetail/widgets/lyrics_section.dart';
import 'package:provider/provider.dart';

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

    final cs = Theme.of(context).colorScheme;

    final songs = context.select<MusicProvider, List<Music>>(
      (p) => [...p.queue],
    );
    final currentMusic = context.select<MusicProvider, Music?>(
      (p) => p.currentMusic,
    );

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
              widget.music.title,
              style: tt.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
                        ? CoverTabContent(
                            music: widget.music,
                          )
                        : const LyricsSection(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      endDrawer: NavigationDrawer(
        children: [
          // 1. 抽屉头部标题
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "当前播放",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "共 ${songs.length} 首歌曲",
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                // 清空列表按钮（可选）
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  onPressed: () {
                    // mp.clearLibrary();
                  },
                ),
              ],
            ),
          ),
          const Divider(indent: 16, endIndent: 16),

          // 2. 歌曲列表区域
          if (songs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(
                child: Text("播放队列为空", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...songs.mapIndexed((index, song) {
              final isPlaying = currentMusic?.id == song.id;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                child: ListTile(
                  dense: true,
                  selected: isPlaying,
                  // 正在播放的歌曲背景高亮
                  selectedTileColor: cs.primaryContainer.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // 正在播放显示小喇叭/波纹，否则显示普通音乐图标
                  leading: Icon(
                    isPlaying
                        ? Icons.volume_up_rounded
                        : Icons.music_note_rounded,
                    color: isPlaying ? cs.primary : cs.onSurfaceVariant,
                    size: 20,
                  ),
                  title: Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: isPlaying
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isPlaying ? cs.primary : cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isPlaying
                          ? cs.primary.withValues(alpha: 0.8)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  // 右侧删除单曲按钮
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () {
                      // mp.removeTrack(song);
                      context.read<MusicProvider>().removeFromQueue(index);
                    },
                  ),
                  onTap: () {
                    // 点击切歌逻辑
                    // mp.playSong(song);
                    // mp.replaceQueue(songs);
                    context.read<MusicProvider>().playByIndex(index);
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}
