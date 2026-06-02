import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:provider/provider.dart';

enum SongSortType { recent, title, artist }

class RecentlyPlayedPage extends StatefulWidget {
  const RecentlyPlayedPage({super.key});

  @override
  State<RecentlyPlayedPage> createState() => _RecentlyPlayedPageState();
}

class _RecentlyPlayedPageState extends State<RecentlyPlayedPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  SongSortType _sortType = SongSortType.recent;

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

  Future<void> _showAddToPlaylistSheet(BuildContext context, Music song) async {
    final playlistProvider = context.read<PlaylistProvider>();
    if (playlistProvider.userPlaylists.isEmpty) {
      AppToast.neutral(context, message: '暂无自建歌单，请先创建');
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
            final p = playlistProvider.userPlaylists[index];
            final alreadyIn = p.songIds.contains(song.id);
            return ListTile(
              enabled: !alreadyIn,
              leading: const Icon(Icons.playlist_add_rounded),
              title: Text(p.name),
              trailing: alreadyIn ? Icon(Icons.check_circle, color: Theme.of(ctx).colorScheme.secondary) : null,
              onTap: () async {
                await playlistProvider.addToPlaylist(p.id, song);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  AppToast.success(ctx, message: '已添加到「${p.name}」');
                }
              },
            );
          },
        ),
      ),
    );
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
          .getPlaylistSongs(PlaylistProvider.favoritesPlaylistId, musicProvider.library)
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
              icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20),
              color: isFav ? colorScheme.primary : null,
              onPressed: () => playlistProvider.toggleMusicFavorite(song),
            ),
            AdaptiveMenu.buildAnchor(
              context,
              icon: Icons.more_vert_rounded,
              items: [
                AdaptiveMenuItem(title: "添加到歌单", onTap: () => _showAddToPlaylistSheet(context, song)),
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

    return SliverM3SongList(songs: entries, padding: const EdgeInsets.all(8), coverLoader: musicProvider);
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();

    final rawSongs = playlistProvider.getHistorySongs(musicProvider.library);

    List<Music> filteredSongs = rawSongs.where((song) {
      final query = _searchQuery.toLowerCase();
      return song.title.toLowerCase().contains(query) || song.artist.toLowerCase().contains(query);
    }).toList();

    if (_sortType == SongSortType.title) {
      filteredSongs.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortType == SongSortType.artist) {
      filteredSongs.sort((a, b) => a.artist.compareTo(b.artist));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalDuration = filteredSongs.fold(Duration.zero, (prev, s) => prev + s.duration);

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
                titlePadding: const EdgeInsets.only(left: 56.0, bottom: 16.0, right: 56.0),
                title: Text("最近播放", maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colorScheme.primaryContainer.withValues(alpha: 0.4), colorScheme.surface],
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              width: 140, height: 140,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [BoxShadow(color: colorScheme.shadow.withValues(alpha: 0.08), blurRadius: 15, offset: const Offset(0, 8))],
                              ),
                              child: Icon(Icons.history_rounded, size: 60, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("本地播放历史",
                                    style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, height: 1.4),
                                    maxLines: 2, overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text("${filteredSongs.length} 首歌曲", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  Text(_formatDuration(totalDuration), style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 16),
                                  FilledButton.icon(
                                    onPressed: filteredSongs.isNotEmpty
                                        ? () {
                                            musicProvider.replaceQueue(filteredSongs, startIndex: 0);
                                            context.push("/music-detail", extra: filteredSongs.first);
                                          }
                                        : null,
                                    icon: const Icon(Icons.play_arrow_rounded, size: 24),
                                    label: const Text("播放全部"),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              actions: [
                IconButton(onPressed: () async => await playlistProvider.clearHistory(), icon: const Icon(Icons.auto_delete_rounded)),
                const Padding(padding: EdgeInsets.only(right: 8)),
              ],
            ),

            if (rawSongs.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverSearchHeaderDelegate(
                  child: Container(
                    color: colorScheme.surface,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SearchBar(
                            controller: _searchController,
                            hintText: "搜索最近播放...",
                            leading: const Icon(Icons.search_rounded),
                            trailing: _searchQuery.isNotEmpty
                                ? [IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ""); })]
                                : null,
                            elevation: WidgetStateProperty.all(0),
                            backgroundColor: WidgetStateProperty.all(colorScheme.surfaceContainerLow),
                            shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onChanged: (value) => setState(() => _searchQuery = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<SongSortType>(
                          icon: const Icon(Icons.sort_rounded),
                          tooltip: "排序方式",
                          initialValue: _sortType,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (type) => setState(() => _sortType = type),
                          itemBuilder: (context) => [
                            PopupMenuItem(value: SongSortType.recent, child: Row(children: [
                              Icon(Icons.access_time_rounded, color: _sortType == SongSortType.recent ? colorScheme.primary : null),
                              const SizedBox(width: 8), const Text("最近播放"),
                            ])),
                            PopupMenuItem(value: SongSortType.title, child: Row(children: [
                              Icon(Icons.sort_by_alpha_rounded, color: _sortType == SongSortType.title ? colorScheme.primary : null),
                              const SizedBox(width: 8), const Text("歌曲标题 (A-Z)"),
                            ])),
                            PopupMenuItem(value: SongSortType.artist, child: Row(children: [
                              Icon(Icons.person_outline_rounded, color: _sortType == SongSortType.artist ? colorScheme.primary : null),
                              const SizedBox(width: 8), const Text("歌手名称 (A-Z)"),
                            ])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              sliver: filteredSongs.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(_searchQuery.isNotEmpty ? Icons.search_off_rounded : Icons.history_toggle_off_rounded, size: 64, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(_searchQuery.isNotEmpty ? "未找到相关歌曲" : "暂无播放记录",
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                        ]),
                      ),
                    )
                  : _buildSongList(filteredSongs, musicProvider, playlistProvider),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _SliverSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverSearchHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => 72.0;

  @override
  double get minExtent => 72.0;

  @override
  bool shouldRebuild(covariant _SliverSearchHeaderDelegate oldDelegate) => true;
}
