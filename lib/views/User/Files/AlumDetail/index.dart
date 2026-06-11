import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

enum AlbumDetailSortType {
  defaultOrder,
  title,
  artist,
}

class AlbumDetailPage extends StatefulWidget {
  final String albumName;
  const AlbumDetailPage({
    super.key,
    required this.albumName,
  });

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

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final hours = d.inHours;
    return hours > 0 ? "$hours小时 $minutes分钟" : "$minutes分钟";
  }

  /// Filter songs that belong to this album/artist/folder
  List<Music> _getAlbumSongs(MusicProvider mp) {
    return mp.library.where((song) {
      final currentAlbum = (song.album ?? '未知专辑').trim();
      final currentArtist = song.artist.trim();
      final folderPath = p.dirname(song.id);

      return currentAlbum == widget.albumName.trim() ||
          currentArtist == widget.albumName.trim() ||
          folderPath == widget.albumName.trim();
    }).toList();
  }

  /// Apply search + sort on top of album songs
  List<Music> _filterAndSort(List<Music> songs) {
    final query = _searchQuery.toLowerCase();
    var filtered = songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();

    if (_sortType == AlbumDetailSortType.title) {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortType == AlbumDetailSortType.artist) {
      filtered.sort((a, b) => a.artist.compareTo(b.artist));
    }
    return filtered;
  }

  SliverM3SongList _buildSongList(
    List<Music> songs,
    MusicProvider musicProvider,
    PlaylistProvider playlistProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = songs.map((song) {
      final isCurrent = musicProvider.currentMusic?.id == song.id;
      final isFav = playlistProvider
          .getPlaylistSongs(PlaylistProvider.favoritesPlaylistId,
              musicProvider.library, musicProvider: musicProvider)
          .any((m) => m.id == song.id);

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
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 20),
              color: isFav ? colorScheme.primary : null,
              onPressed: () => playlistProvider.toggleMusicFavorite(song, musicProvider: musicProvider),
            ),
            AdaptiveMenu.buildAnchor(
              context,
              icon: Icons.more_vert_rounded,
              items: [
                AdaptiveMenuItem(
                    title: "添加到歌单",
                    icon: Icons.playlist_add_rounded,
                    onTap: () => _showAddToPlaylistSheet(context, song)),
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
      padding: const EdgeInsets.all(8),
      coverLoader: musicProvider,
    );
  }

  Future<void> _showAddToPlaylistSheet(BuildContext context, Music song) async {
    final playlistProvider = context.read<PlaylistProvider>();
    if (playlistProvider.userPlaylists.isEmpty) return;
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
                  ? Icon(Icons.check_circle,
                      color: Theme.of(ctx).colorScheme.secondary)
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

    final rawSongs = _getAlbumSongs(musicProvider);
    final filteredSongs = _filterAndSort(rawSongs);
    final totalDuration =
        filteredSongs.fold(Duration.zero, (prev, s) => prev + s.duration);

    // Use the first song's cover as the album cover
    final firstSong = rawSongs.isNotEmpty ? rawSongs.first : null;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              scrolledUnderElevation: 2,
              leading: const BackButton(),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(
                    left: 56.0, bottom: 16.0, right: 56.0),
                title: Text(
                  widget.albumName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primaryContainer
                                .withValues(alpha: 0.6),
                            colorScheme.surface,
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            // ---- 专辑封面 ----
                            _buildAlbumCover(
                                firstSong, colorScheme),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "专辑 · ${widget.albumName}",
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${filteredSongs.length} 首歌曲",
                                    style: textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    _formatDuration(totalDuration),
                                    style: textTheme.labelLarge?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: filteredSongs.isNotEmpty
                                        ? () {
                                            musicProvider.replaceQueue(
                                                filteredSongs,
                                                startIndex: 0);
                                            context.push("/music-detail",
                                                extra: filteredSongs.first);
                                          }
                                        : null,
                                    icon: const Icon(
                                        Icons.play_arrow_rounded,
                                        size: 24),
                                    label: const Text("播放全部"),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
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
            ),

            // ---- 搜索 & 排序栏 ----
            if (rawSongs.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchHeaderDelegate(
                  child: Container(
                    color: colorScheme.surface,
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchBar(
                            controller: _searchController,
                            hintText: "搜索专辑内歌曲...",
                            leading: const Icon(Icons.search_rounded),
                            trailing: _searchQuery.isNotEmpty
                                ? [
                                    IconButton(
                                      icon: const Icon(
                                          Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() =>
                                            _searchQuery = "");
                                      },
                                    )
                                  ]
                                : null,
                            elevation:
                                WidgetStateProperty.all(0),
                            backgroundColor:
                                WidgetStateProperty.all(
                                    colorScheme
                                        .surfaceContainerLow),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) =>
                                setState(() => _searchQuery = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<AlbumDetailSortType>(
                          icon: const Icon(Icons.sort_rounded),
                          tooltip: "歌曲排序",
                          initialValue: _sortType,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12),
                          ),
                          onSelected: (type) =>
                              setState(() => _sortType = type),
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value:
                                  AlbumDetailSortType.defaultOrder,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.queue_music_rounded,
                                    color: _sortType ==
                                            AlbumDetailSortType
                                                .defaultOrder
                                        ? colorScheme.primary
                                        : null,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text("默认顺序"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: AlbumDetailSortType.title,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.sort_by_alpha_rounded,
                                    color: _sortType ==
                                            AlbumDetailSortType
                                                .title
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
                                    color: _sortType ==
                                            AlbumDetailSortType
                                                .artist
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
                  ),
                ),
              ),

            // ---- 歌曲列表 ----
            SliverPadding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              sliver: filteredSongs.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_rounded
                                  : Icons.library_music_outlined,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? "未找到相关歌曲"
                                  : "专辑内无歌曲",
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildSongList(
                      filteredSongs,
                      musicProvider,
                      playlistProvider,
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCover(Music? firstSong, ColorScheme colorScheme) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: firstSong?.coverBytes != null &&
              firstSong!.coverBytes!.isNotEmpty
          ? Image.memory(firstSong.coverBytes!, fit: BoxFit.cover)
          : Icon(
              Icons.album_rounded,
              size: 60,
              color: colorScheme.primary,
            ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SearchHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset,
          bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 72.0;

  @override
  double get minExtent => 72.0;

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) => true;
}
