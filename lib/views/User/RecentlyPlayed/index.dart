import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';

enum SongSortType {
  recent('最近播放', Icons.access_time_rounded),
  title('歌曲标题 (A-Z)', Icons.sort_by_alpha_rounded),
  artist('歌手名称 (A-Z)', Icons.person_outline_rounded);

  final String label;
  final IconData icon;
  const SongSortType(this.label, this.icon);
}

class RecentlyPlayedPage extends StatefulWidget {
  const RecentlyPlayedPage({super.key});

  @override
  State<RecentlyPlayedPage> createState() => _RecentlyPlayedPageState();
}

class _RecentlyPlayedPageState extends State<RecentlyPlayedPage> {
  late final TextEditingController _searchController;
  String _searchQuery = "";
  SongSortType _sortType = SongSortType.recent;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Music> _getProcessedSongs(List<Music> rawSongs) {
    var songs = rawSongs.where((song) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();

    switch (_sortType) {
      case SongSortType.title:
        songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SongSortType.artist:
        songs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case SongSortType.recent:
        break;
    }
    return songs;
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();

    final rawSongs = playlistProvider.getHistorySongs(
      musicProvider.library,
      musicProvider: musicProvider,
    );
    final filteredSongs = _getProcessedSongs(rawSongs);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // 顶栏 AppBar 区域
            _RecentlyPlayedAppBar(
              songCount: filteredSongs.length,
              songsToPlay: filteredSongs,
            ),

            // 搜索与排序 ToolBar Header
            if (rawSongs.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverSearchHeaderDelegate(
                  child: _SearchAndSortHeader(
                    controller: _searchController,
                    searchQuery: _searchQuery,
                    sortType: _sortType,
                    onSearchChanged: (val) =>
                        setState(() => _searchQuery = val),
                    onClearSearch: () => setState(() {
                      _searchController.clear();
                      _searchQuery = "";
                    }),
                    onSortChanged: (type) => setState(() => _sortType = type),
                  ),
                ),
              ),

            // 列表区域 / 空状态
            if (filteredSongs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyStateView(isSearching: _searchQuery.isNotEmpty),
              )
            else
              _SongListSection(songs: filteredSongs),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
//  子组件拆分
// =============================================================================

/// 顶部 SliverAppBar
class _RecentlyPlayedAppBar extends StatelessWidget {
  final int songCount;
  final List<Music> songsToPlay;

  const _RecentlyPlayedAppBar({
    required this.songCount,
    required this.songsToPlay,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final hours = d.inHours;
    return hours > 0 ? "$hours小时 $minutes分钟" : "$minutes分钟";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final musicProvider = context.read<MusicProvider>();
    final playlistProvider = context.read<PlaylistProvider>();
    final totalDuration = songsToPlay.fold(
      Duration.zero,
      (prev, s) => prev + s.duration,
    );

    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      stretch: true,
      scrolledUnderElevation: 2,
      leading: const BackButton(),
      actions: [
        IconButton(
          tooltip: "清空历史记录",
          onPressed: () async =>
              await playlistProvider.clearHistory(musicProvider: musicProvider),
          icon: const Icon(Icons.auto_delete_rounded),
        ),
        const Padding(padding: EdgeInsets.only(right: 8)),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: 56.0,
          bottom: 16.0,
          right: 56.0,
        ),
        title: Text(
          "最近播放",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.4),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
              child: Row(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.history_rounded,
                      size: 52,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "本地播放历史记录",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "$songCount 首歌曲 · ${_formatDuration(totalDuration)}",
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: songsToPlay.isNotEmpty
                              ? () {
                                  musicProvider.replaceQueue(
                                    songsToPlay,
                                    startIndex: 0,
                                    queueName: '最近播放',
                                  );
                                  context.push(
                                    "/music-detail",
                                    extra: songsToPlay.first,
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: const Text("播放全部"),
                          style: FilledButton.styleFrom(
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
        ),
      ),
    );
  }
}

/// 搜索与排序 ToolBar Header
class _SearchAndSortHeader extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final SongSortType sortType;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<SongSortType> onSortChanged;

  const _SearchAndSortHeader({
    required this.controller,
    required this.searchQuery,
    required this.sortType,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              controller: controller,
              hintText: "搜索最近播放...",
              leading: const Icon(Icons.search_rounded),
              trailing: searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: onClearSearch,
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
          PopupMenuButton<SongSortType>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: "排序方式",
            initialValue: sortType,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: onSortChanged,
            itemBuilder: (context) => SongSortType.values.map((type) {
              final isSelected = type == sortType;
              return PopupMenuItem(
                value: type,
                child: Row(
                  children: [
                    Icon(
                      type.icon,
                      color: isSelected ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    Text(type.label),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 歌曲列表构建区域
class _SongListSection extends StatelessWidget {
  final List<Music> songs;

  const _SongListSection({required this.songs});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final playlistProvider = context.watch<PlaylistProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    final favoriteSongs = playlistProvider.getPlaylistSongs(
      PlaylistProvider.favoritesPlaylistId,
      musicProvider.library,
      musicProvider: musicProvider,
    );

    final entries = songs.map((song) {
      final isCurrent = musicProvider.currentMusic?.id == song.id;
      final isFav = favoriteSongs.any((m) => m.id == song.id);
      final isNetwork = song.source == MusicSource.network;
      final coverUrl = isNetwork ? musicProvider.getCoverUrl(song.id) : null;

      return M3SongEntry(
        id: song.id,
        title: song.title,
        subtitle: song.artist,
        coverBytes: song.coverBytes,
        coverUrl: coverUrl,
        coverHeaders:
            isNetwork && coverUrl != null && coverUrl.contains('music.126.net')
            ? const {'Referer': 'https://music.163.com/'}
            : null,
        isNetworkSource: isNetwork,
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
                  onTap: () =>
                      MusicActionMenu.showAddToPlaylistSheet(context, song),
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

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      sliver: SliverM3SongList(
        songs: entries,
        padding: const EdgeInsets.all(8),
        coverLoader: musicProvider,
      ),
    );
  }
}

/// 空状态视图
class _EmptyStateView extends StatelessWidget {
  final bool isSearching;

  const _EmptyStateView({required this.isSearching});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching
                ? Icons.search_off_rounded
                : Icons.history_toggle_off_rounded,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? "未找到相关歌曲" : "暂无播放记录",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SliverSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverSearchHeaderDelegate({required this.child});

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
  bool shouldRebuild(covariant _SliverSearchHeaderDelegate oldDelegate) => true;
}
