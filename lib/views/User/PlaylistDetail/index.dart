import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:provider/provider.dart';

// 排序枚举定义
enum PlaylistSongSortType {
  defaultOrder, // 默认顺序（歌单原始添加顺序）
  title, // 歌曲标题 A-Z
  artist, // 歌手名称 A-Z
}

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  PlaylistSongSortType _sortType = PlaylistSongSortType.defaultOrder;

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

  // 侧边栏添加歌曲逻辑
  void _showModalSideSheet({
    required BuildContext context,
    required List<Music> library,
    double width = 320,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Dismiss Side Sheet",
      pageBuilder: (dialogContext, _, _) => Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: Theme.of(dialogContext).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(24),
          ),
          child: SizedBox(
            width: width,
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
                        scrollCacheExtent: const ScrollCacheExtent.pixels(100),
                        itemCount: library.length,
                        itemBuilder: (context, index) {
                          final music = library[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
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
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                              ),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () async {
                                await context
                                    .read<PlaylistProvider>()
                                    .addToPlaylist(widget.playlistId, music);
                                if (context.mounted) {
                                  AppToast.success(
                                    context,
                                    message: '已添加「${music.title}」',
                                  );
                                }
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
      builder: (context) => AlertDialog(
        title: const Text("删除歌单"),
        content: Text("确定要删除「${playlist.name}」吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
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

  Future<void> _confirmRemoveSong(BuildContext context, String musicId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("移除歌曲"),
        content: const Text("确定要从歌单中移除这首歌吗？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("移除"),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<PlaylistProvider>().removeFromPlaylist(
      widget.playlistId,
      musicId,
    );
    if (context.mounted) {
      AppToast.neutral(context, message: '已从歌单移除');
    }
  }

  Future<void> _showAddToPlaylistSheet(BuildContext context, Music song) async {
    final playlistProvider = context.read<PlaylistProvider>();
    if (playlistProvider.userPlaylists.isEmpty) return;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: playlistProvider.userPlaylists.length,
          itemBuilder: (context, index) {
            final p = playlistProvider.userPlaylists[index];
            final alreadyIn = p.songIds.contains(song.id);
            return ListTile(
              enabled: !alreadyIn,
              leading: const Icon(Icons.playlist_add_rounded),
              title: Text(p.name),
              trailing: alreadyIn
                  ? Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.secondary,
                    )
                  : null,
              onTap: () async {
                await playlistProvider.addToPlaylist(p.id, song);
                if (context.mounted) {
                  Navigator.pop(context);
                  AppToast.success(context, message: '已添加到「${p.name}」');
                }
              },
            );
          },
        ),
      ),
    );
  }

  void _showConfirmSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("上传确认"),
        content: const Text("是否上传到云端?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("确认"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();

    final playlist = playlistProvider.getPlaylistById(widget.playlistId);
    if (playlist == null) {
      return const Scaffold(body: Center(child: Text("歌单不存在")));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. 从库中检索出该歌单的原始歌曲映射
    final rawSongs = playlistProvider.getPlaylistSongs(
      widget.playlistId,
      musicProvider.library,
    );

    // 2. 执行核心实时搜索过滤
    List<Music> filteredSongs = rawSongs.where((song) {
      final query = _searchQuery.toLowerCase();
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();

    // 3. 执行多维数据排序
    if (_sortType == PlaylistSongSortType.title) {
      filteredSongs.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortType == PlaylistSongSortType.artist) {
      filteredSongs.sort((a, b) => a.artist.compareTo(b.artist));
    }

    final isSystem = playlist.isSystem;
    final isFavorites =
        widget.playlistId == PlaylistProvider.favoritesPlaylistId;

    // 联动计算过滤/排序后的总时长与总数
    final totalDuration = filteredSongs.fold(
      Duration.zero,
      (prev, s) => prev + s.duration,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
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
              if (!isSystem)
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
                          onTap: () {
                            _showModalSideSheet(
                              context: context,
                              library: musicProvider.library,
                            );
                          },
                        ),
                        AdaptiveMenuItem(
                          icon: Icons.edit_note_rounded,
                          title: "编辑歌单信息",
                          onTap: () {
                            context.push("/playlist-edit/${widget.playlistId}");
                          },
                        ),
                        AdaptiveMenuItem(
                          icon: Icons.delete_sweep_rounded,
                          title: "删除歌单",
                          isDestructive: true,
                          onTap: () {
                            _showDeleteConfirmDialog(context, playlist);
                          },
                        ),
                      ],
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.more_vert_rounded),
                  ),
                ),
              const Padding(padding: EdgeInsets.only(right: 8)),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(
                left: 56.0,
                bottom: 16.0,
                right: 56.0,
              ),
              title: Text(
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
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
                          colorScheme.primaryContainer.withValues(alpha: 0.6),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          _buildM3Cover(playlist, isFavorites, colorScheme),
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
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "${filteredSongs.length} 首歌曲",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _formatDuration(totalDuration),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: filteredSongs.isNotEmpty
                                      ? () {
                                          musicProvider.replaceQueue(
                                            filteredSongs,
                                            startIndex: 0,
                                          );
                                          context.push(
                                            "/music-detail",
                                            extra: filteredSongs.first,
                                          );
                                        }
                                      : null,
                                  icon: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 24,
                                  ),
                                  label: const Text("播放全部"),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
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
          ),

          // ================= ✨ 核心添加：SliverPersistentHeader 吸顶工具栏 =================
          if (rawSongs.isNotEmpty)
            SliverPersistentHeader(
              pinned: true, // 🔒 开启固定吸顶
              delegate: _PlaylistSearchHeaderDelegate(
                child: Container(
                  color: colorScheme.surface, // 隔离底层列表内容，防止重叠污染
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SearchBar(
                          controller: _searchController,
                          hintText: "搜索歌单内歌曲...",
                          leading: const Icon(Icons.search_rounded),
                          trailing: _searchQuery.isNotEmpty
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = "");
                                    },
                                  ),
                                ]
                              : null,
                          elevation: WidgetStateProperty.all(0),
                          backgroundColor: WidgetStateProperty.all(
                            colorScheme.surfaceContainerLow,
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            // 在切换排序类型时，强行让当前所有焦点组件失焦，收起软键盘
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => _searchQuery = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<PlaylistSongSortType>(
                        icon: const Icon(Icons.sort_rounded),
                        tooltip: "歌曲排序",
                        initialValue: _sortType,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (type) {
                          setState(() => _sortType = type);
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: PlaylistSongSortType.defaultOrder,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.queue_music_rounded,
                                  color:
                                      _sortType ==
                                          PlaylistSongSortType.defaultOrder
                                      ? colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                const Text("默认顺序"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: PlaylistSongSortType.title,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.sort_by_alpha_rounded,
                                  color: _sortType == PlaylistSongSortType.title
                                      ? colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                const Text("歌曲标题 (A-Z)"),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: PlaylistSongSortType.artist,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_outline_rounded,
                                  color:
                                      _sortType == PlaylistSongSortType.artist
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

          // ================= 歌单内歌曲渲染列表 =================
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            sliver: filteredSongs.isEmpty
                ? _buildEmptyState(
                    isFavorites,
                    colorScheme,
                    theme,
                    isSearching: _searchQuery.isNotEmpty,
                  )
                : SliverList.builder(
                    itemCount: filteredSongs.length,
                    itemBuilder: (context, index) => _M3SongTile(
                      song: filteredSongs[index],
                      musicProvider: musicProvider,
                      playlistProvider: playlistProvider,
                      onTap: () {
                        musicProvider.playFromLibrary(filteredSongs[index]);
                        context.push(
                          "/music-detail",
                          extra: filteredSongs[index],
                        );
                      },
                      onRemove: isSystem
                          ? null
                          : () => _confirmRemoveSong(
                              context,
                              filteredSongs[index].id,
                            ),
                      onAddToPlaylist: () => _showAddToPlaylistSheet(
                        context,
                        filteredSongs[index],
                      ),
                    ),
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildM3Cover(
    Playlist playlist,
    bool isFavorites,
    ColorScheme colorScheme,
  ) {
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
      child: playlist.coverPath?.isNotEmpty == true
          ? Image.file(File(playlist.coverPath!), fit: BoxFit.cover)
          : Icon(
              isFavorites
                  ? Icons.favorite_rounded
                  : Icons.playlist_play_rounded,
              size: 60,
              color: colorScheme.primary,
            ),
    );
  }

  // 扩展空状态：区分“纯空歌单”和“搜索不到结果”
  Widget _buildEmptyState(
    bool isFavorites,
    ColorScheme colorScheme,
    ThemeData theme, {
    bool isSearching = false,
  }) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
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
      ),
    );
  }
}

class _M3SongTile extends StatelessWidget {
  final Music song;
  final PlaylistProvider playlistProvider;
  final MusicProvider musicProvider;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final VoidCallback onAddToPlaylist;

  const _M3SongTile({
    required this.song,
    required this.musicProvider,
    required this.playlistProvider,
    required this.onTap,
    this.onRemove,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = musicProvider.currentMusic?.id == song.id;
    final colorScheme = Theme.of(context).colorScheme;
    final isFav = playlistProvider
        .getPlaylistSongs(
          PlaylistProvider.favoritesPlaylistId,
          musicProvider.library,
        )
        .any((m) => m.id == song.id);

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          color: colorScheme.surfaceContainerHighest,
          child: song.coverBytes?.isNotEmpty == true
              ? Image.memory(song.coverBytes!, fit: BoxFit.cover)
              : Icon(Icons.music_note_rounded, color: colorScheme.primary),
        ),
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
          color: isCurrent ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
            ),
            color: isFav ? colorScheme.primary : null,
            onPressed: () => playlistProvider.toggleMusicFavorite(song),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (val) {
              if (val == "remove") onRemove?.call();
              if (val == "add") onAddToPlaylist();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: "add", child: Text("添加到歌单")),
              if (onRemove != null)
                const PopupMenuItem(value: "remove", child: Text("从歌单移除")),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= 必须配套实现的吸顶高度渲染代理 =================
class _PlaylistSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _PlaylistSearchHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 72.0;

  @override
  double get minExtent => 72.0;

  @override
  bool shouldRebuild(covariant _PlaylistSearchHeaderDelegate oldDelegate) {
    return true; // 确保外层调用 setState 更改搜索词或排序时，吸顶栏内部能同步重绘
  }
}
