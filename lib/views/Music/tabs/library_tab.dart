import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/Music/index.dart';
import 'package:myapp/views/Music/widgets/album_card.dart';
import 'package:provider/provider.dart';

class LibraryTab extends StatelessWidget {
  final ValueNotifier<MusicSortType> sortNotifier;

  const LibraryTab({super.key, required this.sortNotifier});

  @override
  Widget build(BuildContext context) {
    final library = context.select<MusicProvider, List<Music>>(
      (p) => p.library,
    );

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

    // ✨ 监听外层标题栏的排序改变
    return ValueListenableBuilder<MusicSortType>(
      valueListenable: sortNotifier,
      builder: (context, currentSort, _) {
        // ================== 排序数据处理 ==================
        List<Music> sortedList = List.from(library);
        if (currentSort == MusicSortType.name) {
          sortedList.sort((a, b) => (a.title).compareTo(b.title));
        }

        final albumsMap = <String, List<Music>>{};
        for (final song in sortedList) {
          final albumName = song.album ?? "未知专辑";
          albumsMap.putIfAbsent(albumName, () => []).add(song);
        }
        final albums = albumsMap.entries.toList();
        // ================================================

        return RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            // 💡 重要：因为外层是 NestedScrollView，内层最好加上这两个属性，滑动更丝滑
            key: const PageStorageKey<String>('library_tab'),
            slivers: [
              // 🛠️ 删除了原本属于这里的 SliverAppBar，彻底告别双标题！

              // 1. 顶部专辑板块
              if (albums.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      "按专辑浏览",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 140,
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
                                  s.coverBytes != null &&
                                  s.coverBytes!.isNotEmpty,
                              orElse: () => songs.first,
                            )
                            .coverBytes;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: SizedBox(
                            width: 140,
                            child: AlbumCard(
                              albumName: albumName,
                              songCount: songs.length,
                              coverBytes: cover,
                              onTap: () {
                                context.push(
                                  "/user/files/album-detail",
                                  extra: {
                                    'albumName': albumName,
                                    'songs': songs,
                                  },
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

              // 2. 歌曲列表板块
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                sliver: SliverList.separated(
                  itemCount: sortedList.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final music = sortedList[index];
                    return RepaintBoundary(
                      child: ObservableMusicListItem(music: music),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
    );
  }
}

// ================== 弹出式搜索专属 Delegate (保持不变) ==================
class MusicSearchDelegate extends SearchDelegate {
  final List<Music> library;
  MusicSearchDelegate({required this.library})
    : super(searchFieldLabel: '搜索歌曲、歌手或专辑...');

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear_rounded),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _buildSearchResult();
  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResult();

  Widget _buildSearchResult() {
    final filtered = library.where((music) {
      final search = query.toLowerCase();
      return music.title.toLowerCase().contains(search) ||
          music.artist.toLowerCase().contains(search) ||
          (music.album?.toLowerCase().contains(search) ?? false);
    }).toList();

    if (filtered.isEmpty)
      return const Center(
        child: Text("没有找到相关单曲", style: TextStyle(color: Colors.grey)),
      );

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) =>
          ObservableMusicListItem(music: filtered[index]),
    );
  }
}
