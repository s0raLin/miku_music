import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';

enum PlaylistSongSortType {
  defaultOrder('默认顺序', Icons.queue_music_rounded),
  title('歌曲标题 (A-Z)', Icons.sort_by_alpha_rounded),
  artist('歌手名称 (A-Z)', Icons.person_outline_rounded);

  final String label;
  final IconData icon;
  const PlaylistSongSortType(this.label, this.icon);
}

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  late final TextEditingController _searchController;
  String _searchQuery = "";
  PlaylistSongSortType _sortType = PlaylistSongSortType.defaultOrder;

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
      case PlaylistSongSortType.title:
        songs.sort((a, b) => a.title.compareTo(b.title));
        break;
      case PlaylistSongSortType.artist:
        songs.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case PlaylistSongSortType.defaultOrder:
        break;
    }
    return songs;
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();

    final playlist = playlistProvider.getPlaylistById(widget.playlistId);
    if (playlist == null) {
      return const Scaffold(body: Center(child: Text("歌单不存在")));
    }

    final rawSongs = playlistProvider.getPlaylistSongs(
      widget.playlistId,
      musicProvider.library,
      musicProvider: musicProvider,
    );
    final filteredSongs = _getProcessedSongs(rawSongs);

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            // 顶栏 AppBar 与 歌单信息 Header
            _PlaylistAppBar(
              playlist: playlist,
              playlistId: widget.playlistId,
              songCount: filteredSongs.length,
              songsToPlay: filteredSongs,
            ),

            // 搜索与排序粘性 Header
            if (rawSongs.isNotEmpty)
              SliverPersistentHeader(
                pinned: true,
                delegate: _PlaylistSearchHeaderDelegate(
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

            // 歌曲列表区域
            if (filteredSongs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyStateView(
                  isSearching: _searchQuery.isNotEmpty,
                  isFavorites:
                      widget.playlistId == PlaylistProvider.favoritesPlaylistId,
                ),
              )
            else
              _SongListSection(
                playlistId: widget.playlistId,
                songs: filteredSongs,
                isSystem: playlist.isSystem,
              ),

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

/// 顶部 SliverAppBar 区域
class _PlaylistAppBar extends StatelessWidget {
  final Playlist playlist;
  final String playlistId;
  final int songCount;
  final List<Music> songsToPlay;

  const _PlaylistAppBar({
    required this.playlist,
    required this.playlistId,
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
    final isFavorites = playlistId == PlaylistProvider.favoritesPlaylistId;
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
          tooltip: "上传歌单",
          onPressed: () => _showConfirmSyncDialog(context),
          icon: const Icon(Icons.upload_rounded),
        ),
        if (!playlist.isSystem)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              AdaptiveMenu.show(
                context,
                details: details,
                title: playlist.name,
                items: [
                  AdaptiveMenuItem(
                    icon: Icons.add_rounded,
                    title: "添加歌曲",
                    onTap: () => _showAddSongsSideSheet(
                      context,
                      musicProvider.library,
                      playlistId,
                    ),
                  ),
                  AdaptiveMenuItem(
                    icon: Icons.edit_note_rounded,
                    title: "编辑歌单信息",
                    onTap: () => context.push("/playlist-edit/$playlistId"),
                  ),
                  AdaptiveMenuItem(
                    icon: Icons.delete_sweep_rounded,
                    title: "删除歌单",
                    isDestructive: true,
                    onTap: () => _showDeleteConfirmDialog(context, playlist),
                  ),
                ],
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.more_vert_rounded),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(
          left: 56.0,
          bottom: 16.0,
          right: 56.0,
        ),
        title: Text(
          playlist.name,
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
                colorScheme.primaryContainer.withOpacity(0.5),
                colorScheme.surface,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
              child: Row(
                children: [
                  _PlaylistCover(
                    coverPath: playlist.coverPath,
                    isFavorites: isFavorites,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.description?.isNotEmpty == true
                              ? playlist.description!
                              : "暂无描述信息",
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
                                    queueName: playlist.name,
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

/// 歌单封面组件
class _PlaylistCover extends StatelessWidget {
  final String? coverPath;
  final bool isFavorites;

  const _PlaylistCover({this.coverPath, required this.isFavorites});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: coverPath?.isNotEmpty == true
          ? Image.file(File(coverPath!), fit: BoxFit.cover)
          : Icon(
              isFavorites
                  ? Icons.favorite_rounded
                  : Icons.playlist_play_rounded,
              size: 52,
              color: colorScheme.primary,
            ),
    );
  }
}

/// 搜索与排序 Header UI
class _SearchAndSortHeader extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final PlaylistSongSortType sortType;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<PlaylistSongSortType> onSortChanged;

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
              hintText: "搜索歌单内歌曲...",
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
          PopupMenuButton<PlaylistSongSortType>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: "歌曲排序",
            initialValue: sortType,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: onSortChanged,
            itemBuilder: (context) => PlaylistSongSortType.values.map((type) {
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
  final String playlistId;
  final List<Music> songs;
  final bool isSystem;

  const _SongListSection({
    required this.playlistId,
    required this.songs,
    required this.isSystem,
  });

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
                if (!isSystem)
                  AdaptiveMenuItem(
                    title: "从歌单移除",
                    onTap: () =>
                        _confirmRemoveSong(context, playlistId, song.id),
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
  final bool isFavorites;

  const _EmptyStateView({required this.isSearching, required this.isFavorites});

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
                : Icons.library_music_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? "未找到相关歌曲" : (isFavorites ? "还没有收藏" : "空空如也"),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
//  辅助 Helper & 弹窗逻辑
// =============================================================================

class _PlaylistSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PlaylistSearchHeaderDelegate({required this.child});

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
  bool shouldRebuild(covariant _PlaylistSearchHeaderDelegate oldDelegate) =>
      true;
}

void _showAddSongsSideSheet(
  BuildContext context,
  List<Music> library,
  String playlistId,
) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "Dismiss Side Sheet",
    pageBuilder: (dialogContext, _, _) => Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Theme.of(dialogContext).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
        child: SizedBox(
          width: 320,
          height: double.infinity,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "选择要添加的歌曲",
                        style: Theme.of(dialogContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: library.length,
                      itemBuilder: (ctx, index) {
                        final music = library[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                ctx,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.music_note_rounded,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            music.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            music.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            color: Theme.of(ctx).colorScheme.primary,
                            onPressed: () async {
                              await ctx.read<PlaylistProvider>().addToPlaylist(
                                playlistId,
                                music,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, anim, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic)),
      child: child,
    ),
  );
}

Future<void> _showDeleteConfirmDialog(
  BuildContext context,
  Playlist playlist,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("删除歌单"),
      content: Text("确定要删除「${playlist.name}」吗？"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("取消"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          child: const Text("删除"),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await context.read<PlaylistProvider>().deletePlaylist(playlist.id);
  if (context.mounted) {
    AppToast.neutral(context, message: '歌单「${playlist.name}」已删除');
    Navigator.of(context).pop();
  }
}

Future<void> _confirmRemoveSong(
  BuildContext context,
  String playlistId,
  String musicId,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("移除歌曲"),
      content: const Text("确定要从歌单中移除这首歌吗？"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("取消"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("移除"),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await context.read<PlaylistProvider>().removeFromPlaylist(
    playlistId,
    musicId,
  );
  if (context.mounted) {
    AppToast.neutral(context, message: '已从歌单移除');
  }
}

void _showConfirmSyncDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("上传确认"),
      content: const Text("是否上传到云端?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("取消"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text("确认"),
        ),
      ],
    ),
  );
}
