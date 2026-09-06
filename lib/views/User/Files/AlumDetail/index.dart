import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

enum AlbumDetailSortType { defaultOrder, title, artist }

class AlbumDetailPage extends StatefulWidget {
  final String albumName;
  final String? rawKey; // 对应的原始绝对路径或完整分组 Key

  const AlbumDetailPage({super.key, required this.albumName, this.rawKey});

  @override
  State<AlbumDetailPage> createState() => _AlbumDetailPageState();
}

class _AlbumDetailPageState extends State<AlbumDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  AlbumDetailSortType _sortType = AlbumDetailSortType.defaultOrder;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 移除路径前缀与文件扩展名，提取纯粹的名称
  static String _cleanMediaName(String raw) {
    if (raw.isEmpty) return '未知专辑';
    final normalized = p.normalize(raw.trim());
    final baseName = p.basenameWithoutExtension(normalized);
    if (baseName.isEmpty || baseName == '.' || baseName == '/') {
      return normalized;
    }
    return baseName;
  }

  /// 准确筛选属于该分组的音频文件
  List<Music> _getAlbumSongs(List<Music> library) {
    final rawTarget = (widget.rawKey ?? widget.albumName).trim();
    final cleanTarget = _cleanMediaName(widget.albumName);

    return library.where((song) {
      final rawAlbum = (song.album ?? '').trim();
      final cleanAlbum = _cleanMediaName(rawAlbum);
      final rawArtist = song.artist.trim();
      final cleanArtist = _cleanMediaName(rawArtist);
      final folderPath = p.dirname(song.id);
      final cleanFolder = _cleanMediaName(folderPath);

      // 1. 绝对路径 / 完整 Key 精确匹配
      if (folderPath == rawTarget ||
          rawAlbum == rawTarget ||
          rawArtist == rawTarget) {
        return true;
      }

      // 2. 净化后的纯文本匹配
      return cleanAlbum == cleanTarget ||
          cleanFolder == cleanTarget ||
          cleanArtist == cleanTarget;
    }).toList();
  }

  /// 对过滤后的歌曲进行搜索和动态排序
  List<Music> _filterAndSort(List<Music> songs) {
    final query = _searchQuery.toLowerCase().trim();
    final filtered = songs.where((song) {
      if (query.isEmpty) return true;
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();

    switch (_sortType) {
      case AlbumDetailSortType.title:
        filtered.sort((a, b) => a.title.compareTo(b.title));
        break;
      case AlbumDetailSortType.artist:
        filtered.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case AlbumDetailSortType.defaultOrder:
        break;
    }
    return filtered;
  }

  Future<void> _showAddToPlaylistSheet(BuildContext context, Music song) async {
    final playlistProvider = context.read<PlaylistProvider>();
    if (playlistProvider.userPlaylists.isEmpty) {
      AppToast.neutral(context, message: '暂无可用歌单，请先创建歌单');
      return;
    }
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: playlistProvider.userPlaylists.length,
          itemBuilder: (ctx, index) {
            final pl = playlistProvider.userPlaylists[index];
            final alreadyIn = pl.songIds.contains(song.id);
            return ListTile(
              enabled: !alreadyIn,
              leading: const Icon(Icons.playlist_add_rounded),
              title: Text(pl.name),
              trailing: alreadyIn
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(ctx).colorScheme.secondary,
                    )
                  : null,
              onTap: () async {
                await playlistProvider.addToPlaylist(pl.id, song);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppToast.success(ctx, message: '已添加到「${pl.name}」');
                }
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final playlistProvider = context.watch<PlaylistProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final rawSongs = _getAlbumSongs(musicProvider.library);
    final filteredSongs = _filterAndSort(rawSongs);
    final displayTitle = _cleanMediaName(widget.albumName);

    // 干净且高质的首选封面提取（无 try-catch）
    final coverSong =
        rawSongs.firstWhereOrNull(
          (s) => s.coverBytes != null && s.coverBytes!.isNotEmpty,
        ) ??
        rawSongs.firstOrNull;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // 顶部弹性 Header
            _AlbumDetailHeader(
              displayTitle: displayTitle,
              coverSong: coverSong,
              songs: filteredSongs,
            ),

            // Sticky 搜索与排序控制栏
            if (rawSongs.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: _AlbumSearchHeaderDelegate(
                  child: _AlbumSearchHeader(
                    searchController: _searchController,
                    searchQuery: _searchQuery,
                    sortType: _sortType,
                    onSearchChanged: (val) =>
                        setState(() => _searchQuery = val),
                    onSortChanged: (type) => setState(() => _sortType = type),
                  ),
                ),
              ),

            // 歌曲列表或空状态
            if (filteredSongs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.library_music_outlined,
                        size: 56,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty ? "未找到符合条件的歌曲" : "暂无音频文件",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildSongListSliver(
                filteredSongs,
                musicProvider,
                playlistProvider,
                colorScheme,
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSongListSliver(
    List<Music> songs,
    MusicProvider musicProvider,
    PlaylistProvider playlistProvider,
    ColorScheme colorScheme,
  ) {
    final favorites = playlistProvider.getPlaylistSongs(
      PlaylistProvider.favoritesPlaylistId,
      musicProvider.library,
      musicProvider: musicProvider,
    );

    final entries = songs.map((song) {
      final isCurrent = musicProvider.currentMusic?.id == song.id;
      final isFav = favorites.any((m) => m.id == song.id);

      return M3SongEntry(
        id: song.id,
        title: song.title,
        subtitle: song.artist,
        coverBytes: song.coverBytes,
        isHighlighted: isCurrent,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
              ),
              color: isFav ? colorScheme.primary : null,
              onPressed: () => playlistProvider.toggleMusicFavorite(
                song,
                musicProvider: musicProvider,
              ),
            ),
            AdaptiveMenu.buildAnchor(
              context,
              icon: Icons.more_vert_rounded,
              items: [
                AdaptiveMenuItem(
                  title: "添加到歌单",
                  icon: Icons.playlist_add_rounded,
                  onTap: () => _showAddToPlaylistSheet(context, song),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          musicProvider.playFromLibrary(song);
          context.push("/music-detail", extra: song);
        },
      );
    }).toList();

    return SliverM3SongList(
      songs: entries,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      coverLoader: musicProvider,
    );
  }
}

// =============================================================================
// 组件拆分区
// =============================================================================

/// 顶部弹性 Header Widget
/// 顶部弹性 Header Widget
class _AlbumDetailHeader extends StatelessWidget {
  final String displayTitle;
  final Music? coverSong;
  final List<Music> songs;

  const _AlbumDetailHeader({
    required this.displayTitle,
    required this.coverSong,
    required this.songs,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final hours = d.inHours;
    return hours > 0 ? "$hours小时 $minutes分钟" : "$minutes分钟";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final musicProvider = context.read<MusicProvider>();

    final totalDuration = songs.fold(
      Duration.zero,
      (prev, s) => prev + s.duration,
    );

    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      scrolledUnderElevation: 3,
      leading: const BackButton(),
      // 移除 title 属性，彻底去掉 AppBar 收起时的顶部标题
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.5),
                    colorScheme.surface,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _AlbumCoverCard(coverSong: coverSong),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 仅保留弹性空间中的标题
                          Text(
                            displayTitle,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${songs.length} 首歌曲 · ${_formatDuration(totalDuration)}",
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: songs.isNotEmpty
                                ? () {
                                    musicProvider.replaceQueue(
                                      songs,
                                      startIndex: 0,
                                    );
                                    context.push(
                                      "/music-detail",
                                      extra: songs.first,
                                    );
                                  }
                                : null,
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 20,
                            ),
                            label: const Text("播放全部"),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 专辑封面组件
class _AlbumCoverCard extends StatelessWidget {
  final Music? coverSong;

  const _AlbumCoverCard({required this.coverSong});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasCover =
        coverSong?.coverBytes != null && coverSong!.coverBytes!.isNotEmpty;

    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: hasCover
          ? Image.memory(coverSong!.coverBytes!, fit: BoxFit.cover)
          : Icon(Icons.album_rounded, size: 48, color: colorScheme.primary),
    );
  }
}

/// 搜索与排序 Bar
class _AlbumSearchHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final AlbumDetailSortType sortType;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<AlbumDetailSortType> onSortChanged;

  const _AlbumSearchHeader({
    required this.searchController,
    required this.searchQuery,
    required this.sortType,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              controller: searchController,
              hintText: "搜索歌曲或歌手...",
              leading: const Icon(Icons.search_rounded),
              trailing: searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged("");
                        },
                      ),
                    ]
                  : null,
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                colorScheme.surfaceContainerLow,
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<AlbumDetailSortType>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: "排序方式",
            initialValue: sortType,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: onSortChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: AlbumDetailSortType.defaultOrder,
                child: Row(
                  children: [
                    Icon(
                      Icons.queue_music_rounded,
                      color: sortType == AlbumDetailSortType.defaultOrder
                          ? colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text("默认排序"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AlbumDetailSortType.title,
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha_rounded,
                      color: sortType == AlbumDetailSortType.title
                          ? colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text("歌曲标题 (A-Z)"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: AlbumDetailSortType.artist,
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      color: sortType == AlbumDetailSortType.artist
                          ? colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    const Text("歌手名称 (A-Z)"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlbumSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _AlbumSearchHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  double get maxExtent => 64.0;

  @override
  double get minExtent => 64.0;

  @override
  bool shouldRebuild(covariant _AlbumSearchHeaderDelegate oldDelegate) => true;
}
