import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/Music/widgets/album_card.dart';
import 'package:provider/provider.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();
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

    // ==================== 排序逻辑 ====================
    final sortTypeSongs = context.select<MusicProvider, SongSortType>(
      (p) => p.songSortType,
    );
    final sortTypeAlbums = context.select<MusicProvider, AlbumSortType>(
      (p) => p.albumSortType,
    );
    final sortedLibrary = context.select<MusicProvider, List<Music>>(
      (p) => p.getSortedLibrary(),
    );
    final sortedAlbums = context
        .select<MusicProvider, List<MapEntry<String, List<Music>>>>(
          (p) => p.getSortedAlbums(),
        );

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          // ====================== 1. 按专辑浏览 ======================
          if (sortedAlbums.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildSectionHeader(
                  title: "按专辑浏览",
                  currentSort: sortTypeAlbums,
                  onSortChanged: (value) {
                    musicProvider.setAlbumSortType(value);
                  },
                  sortOptions: AlbumSortType.values,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: sortedAlbums.length,
                  itemBuilder: (context, index) {
                    final entry = sortedAlbums[index];
                    final albumName = entry.key;
                    final songs = entry.value;

                    final coverSong = songs.firstWhere(
                      (s) => s.coverBytes != null && s.coverBytes!.isNotEmpty,
                      orElse: () => songs.first,
                    );

                    // 通过 addPostFrameCallback 安全避开 build 副作用
                    if (coverSong.coverBytes == null ||
                        coverSong.coverBytes!.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        // 确保组件依然挂载，且当前歌曲未在加载中，才发起请求
                        if (context.mounted &&
                            !musicProvider.isCoverLoading(coverSong.id)) {
                          musicProvider.loadCoverLazy(coverSong.id);
                        }
                      });
                    }

                    return Consumer<MusicProvider>(
                      builder: (context, provider, _) {
                        final isLoading = provider.isCoverLoading(coverSong.id);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: SizedBox(
                            width: 140,
                            child: AlbumCard(
                              albumName: albumName,
                              songCount: songs.length,
                              coverBytes: coverSong.coverBytes,
                              isLoading: isLoading,
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
                    );
                  },
                ),
              ),
            ),
          ],

          // ====================== 2. 所有单曲 ======================
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: _buildSectionHeader(
                title: "所有单曲",
                currentSort: sortTypeSongs,
                onSortChanged: (value) {
                  musicProvider.setSongSortType(value);
                },
                sortOptions: SongSortType.values,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            sliver: SliverList.separated(
              itemCount: sortedLibrary.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final music = sortedLibrary[index];
                return RepaintBoundary(
                  child: ObservableMusicListItem(
                    key: ValueKey(music.id),
                    music: music,
                  ),
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // ==================== 通用标题组件 ====================
  Widget _buildSectionHeader<T>({
    required String title,
    required T currentSort,
    required ValueChanged<T> onSortChanged,
    required List<T> sortOptions,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        PopupMenuButton<T>(
          icon: const Icon(Icons.sort_rounded, size: 20),
          tooltip: '排序',
          initialValue: currentSort,
          onSelected: onSortChanged,
          itemBuilder: (context) => sortOptions.map((type) {
            return PopupMenuItem<T>(
              value: type,
              child: Text(_getSortTypeLabel(type)),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getSortTypeLabel<T>(T type) {
    if (type is SongSortType) {
      switch (type) {
        case SongSortType.nameAsc:
          return '歌名 A-Z';
        case SongSortType.nameDesc:
          return '歌名 Z-A';
        case SongSortType.artistAsc:
          return '歌手 A-Z';
        case SongSortType.auto:
          return '默认';
      }
    } else if (type is AlbumSortType) {
      switch (type) {
        case AlbumSortType.nameAsc:
          return '专辑名 A-Z';
        case AlbumSortType.nameDesc:
          return '专辑名 Z-A';
        case AlbumSortType.songCountDesc:
          return '歌曲数量（多→少）';
      }
    }
    return type.toString();
  }
}
