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

    // 2. 局部计算与状态解耦：将分组结果的推导限制在作用域内，确保引用的一致性
    final albumsMap = <String, List<Music>>{};
    for (final song in library) {
      final albumName = song.album ?? "未知专辑";
      albumsMap.putIfAbsent(albumName, () => []).add(song);
    }
    final albums = albumsMap.entries.toList();

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          // 2. 顶部专辑板块：横向展现
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
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: albums.length,
                  itemBuilder: (context, index) {
                    final entry = albums[index];
                    final albumName = entry.key;
                    final songs = entry.value;

                    //* 3. 封面决策机制：优先选取已经洗出封面的歌曲作为专辑代表
                    final coverSong = songs.firstWhere(
                      (s) => s.coverBytes != null && s.coverBytes!.isNotEmpty,
                      orElse: () => songs.first,
                    );

                    //* 4. 主动触发懒加载核心：如果整个专辑代表歌曲还没封面，立马静默调度后台解析
                    if (coverSong.coverBytes == null ||
                        coverSong.coverBytes!.isEmpty) {
                      musicProvider.loadCoverLazy(coverSong.id);
                    }

                    //* 5. 高级响应式优化：利用局部的 Consumer 或 context.select，
                    // 确保当这首特定代表歌曲的“正在加载状态”或“封面改变”时，卡片能以毫秒级刷新
                    return Consumer<MusicProvider>(
                      builder: (context, provider, _) {
                        final isCurrentCoverLoading = provider.isCoverLoading(
                          coverSong.id,
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: SizedBox(
                            width: 140,
                            child: AlbumCard(
                              albumName: albumName,
                              songCount: songs.length,
                              coverBytes: coverSong.coverBytes,
                              isLoading: isCurrentCoverLoading, // 支持加载状态转菊花
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

          // 3. 所有单曲列表板块
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
                // 6. 使用显式 ValueKey 提升 Flutter Diff 算法的效率，配合无状态的专属 ListItem
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
}
