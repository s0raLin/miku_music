import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/views/Music/widgets/album_card.dart';
import 'package:provider/provider.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    // final musicProvider = context.watch<MusicProvider>();
    final library = context.select<MusicProvider, List<MusicInfo>>(
      (p) => p.library,
    );
    // final currentMusic = musicProvider.currentMusic;

    if (library.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {},
        child: AppEmptyState(
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
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final music = library[index];
                return RepaintBoundary(
                  child: ObservableMusicListItem(
                    music: music,
                  ),
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

class ObservableMusicListItem extends StatefulWidget {
  final MusicInfo music;

  const ObservableMusicListItem({super.key, required this.music});

  @override
  State<ObservableMusicListItem> createState() =>
      _ObservableMusicListItemState();
}

class _ObservableMusicListItemState extends State<ObservableMusicListItem> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('initState: ${widget.music.title}');
    _loadCover();
  }

  // 加这个方法
  Future<Uint8List?> _resizeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 144,
      targetHeight: 144,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    frame.image.dispose();
    return byteData?.buffer.asUint8List();
  }

  void _loadCover() async {
    if (widget.music.coverBytes != null &&
        widget.music.coverBytes!.isNotEmpty) {
      // 已有封面也压缩后再用
      final small = await _resizeImage(widget.music.coverBytes!);
      if (!mounted) return;
      setState(() {
        widget.music.coverBytes = small; // 回写小图，下次直接用
      });
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final updatedMusic = await MusicService.parse(widget.music.id);
      final small = await _resizeImage(updatedMusic.coverBytes!);
      if (mounted) {
        setState(() {
          widget.music.coverBytes = small; // 回写小图
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();
    final isCurrent = context.select<MusicProvider, bool>(
      (p) => p.currentMusic?.id == widget.music.id,
    );

    return SongTile(
      music: widget.music,
      onTap: () {
        musicProvider.playFromLibrary(widget.music);
        context.push("/music-detail");
      },
      onPressed: () {
        final currentMusic = musicProvider.currentMusic;
        if (currentMusic == null || currentMusic.id != widget.music.id) {
          musicProvider.playFromLibrary(widget.music);
        } else {
          musicProvider.togglePlay();
        }
      },
      isCurrent: isCurrent,
    );
  }
}
