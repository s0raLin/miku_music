import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/Music/widgets/album_card.dart';
import 'package:myapp/views/Music/widgets/empty_state.dart';
import 'package:provider/provider.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final library = musicProvider.library;
    final currentMusic = musicProvider.currentMusic;

    if (library.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {},
        child: EmptyState(
          icon: Icons.music_note_rounded,
          title: "还没有歌曲",
          subtitle: "点击下方按钮上传歌曲开始使用",
          action: FilledButton.icon(
            onPressed: () async {
              try {
                await MusicApi.pickAndUploadMusic();
                if (context.mounted) {
                  AppToast.success(context, message: '歌曲上传成功', title: '上传完成');
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.error(
                    context,
                    message: e.toString().replaceAll('Exception: ', ''),
                    title: '上传失败',
                  );
                }
              }
            },
            icon: const Icon(Icons.upload_rounded),
            label: const Text("上传歌曲"),
          ),
        ),
      );
    }

    // 1. 核心整合：在乐库内部直接计算专辑分类
    final albumsMap = <String, List<MusicInfo>>{};
    for (final song in library) {
      final albumName = song.album ?? "未知专辑";
      albumsMap.putIfAbsent(albumName, () => []).add(song);
    }
    final albums = albumsMap.entries.toList();

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          // 2. 顶部专辑板块：如果存在专辑，则横向展现
          if (albums.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  "按专辑浏览",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 160, // 控制横向专辑卡片的高度
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final entry = albums[index];
                    final albumName = entry.key;
                    final songs = entry.value;
                    final cover = songs
                        .firstWhere(
                          (s) =>
                              s.coverBytes != null && s.coverBytes!.isNotEmpty,
                          orElse: () => songs.first,
                        )
                        .coverBytes;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        width: 140, // 限定单张专辑卡片的宽度
                        child: AlbumCard(
                          albumName: albumName,
                          songCount: songs.length,
                          coverBytes: cover,
                          onTap: () {
                            context.push(
                              "/user/files/album-detail",
                              extra: {'albumName': albumName, 'songs': songs},
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // 3. 歌曲列表板块
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                "所有单曲",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            sliver: SliverList.separated(
              itemCount: library.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final music = library[index];
                return SongTile(
                  music: music,
                  isCurrent: music.id == currentMusic?.id,
                  onTap: () {
                    musicProvider.playFromLibrary(music);
                    context.push("/music-detail");
                  },
                  onPressed: () {
                    if (currentMusic == null || currentMusic.id != music.id) {
                      musicProvider.playFromLibrary(music);
                    } else {
                      musicProvider.togglePlay();
                    }
                  },
                );
              },
            ),
          ),
          // 底部留白，防止被可能存在的底栏挡住
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class SongTile extends StatelessWidget {
  final MusicInfo music;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onPressed;

  const SongTile({
    super.key,
    required this.music,
    required this.isCurrent,
    required this.onTap,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );
    return SongListCardTile(
      title: music.title,
      subtitle: music.artist,
      coverBytes: music.coverBytes,
      fallbackIcon: Icons.music_note_rounded,
      onTap: onTap,
      highlighted: isCurrent,
      trailing: FilledButton(
        onPressed: onPressed,
        child: Icon(
          isCurrent && isPlaying
              ? Icons.pause_rounded
              : Icons.play_arrow_rounded,
        ),
      ),
    );
  }
}
