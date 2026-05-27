import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:provider/provider.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  Offset _actionMenuTapPosition = Offset.zero;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final hours = d.inHours;
    return hours > 0 ? "$hours小时 $minutes分钟" : "$minutes分钟";
  }

  // --- 自适应 M3 响应式菜单重构 ---
  void _showResponsiveActionMenu(BuildContext context, Playlist playlist) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    // 依赖各自各司其职的 Provider
    final playlistProvider = context.read<PlaylistProvider>();
    final musicProvider = context.read<MusicProvider>();

    final menuItems = [
      _AdaptiveActionItem(
        icon: Icons.add_rounded,
        title: "添加歌曲",
        // 传入核心乐库源数据进行筛选
        onTap: () => _showModalSideSheet(
          context: context,
          library: musicProvider.library,
        ),
      ),
      _AdaptiveActionItem(
        icon: Icons.edit_note_rounded,
        title: "编辑歌单信息",
        onTap: () {},
      ),
      _AdaptiveActionItem(
        icon: Icons.delete_sweep_rounded,
        title: "删除歌单",
        textColor: colorScheme.error,
        iconColor: colorScheme.error,
        onTap: () => _showDeleteConfirmDialog(context, playlist),
      ),
    ];

    if (isDesktop) {
      showMenu(
        context: context,
        position: RelativeRect.fromLTRB(
          _actionMenuTapPosition.dx,
          _actionMenuTapPosition.dy,
          _actionMenuTapPosition.dx + 1,
          _actionMenuTapPosition.dy + 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        items: menuItems.map((item) {
          return PopupMenuItem(
            onTap: item.onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 20, color: item.iconColor),
                const SizedBox(width: 12),
                Text(item.title, style: TextStyle(color: item.textColor)),
              ],
            ),
          );
        }).toList(),
      );
    } else {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Text(
                  playlist.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ...menuItems.map(
                (item) => ListTile(
                  leading: Icon(item.icon, color: item.iconColor),
                  title: Text(
                    item.title,
                    style: TextStyle(color: item.textColor),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    item.onTap?.call();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // 侧边栏添加歌曲逻辑重构
  void _showModalSideSheet({
    required BuildContext context,
    required List<MusicInfo> library,
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
                                // 改为调用 PlaylistProvider 的方法
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

  // --- 弹窗与移除逻辑改道至 PlaylistProvider ---
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

  Future<void> _showAddToPlaylistSheet(
    BuildContext context,
    MusicInfo song,
  ) async {
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

  // --- UI 构建 ---
  @override
  Widget build(BuildContext context) {
    // 监听两个不同的 Provider
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();

    final playlist = playlistProvider.getPlaylistById(widget.playlistId);
    if (playlist == null) {
      return const Scaffold(body: Center(child: Text("歌单不存在")));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 利用 PlaylistProvider 内部维护的歌曲信息映射转换逻辑
    final songs = playlistProvider.getPlaylistSongs(
      widget.playlistId,
      musicProvider.library,
    );

    final isSystem = playlist.isSystem;
    final isFavorites =
        widget.playlistId == PlaylistProvider.favoritesPlaylistId;
    final totalDuration = songs.fold(
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
                  onTapDown: (d) => _actionMenuTapPosition = d.globalPosition,
                  child: IconButton(
                    onPressed: () =>
                        _showResponsiveActionMenu(context, playlist),
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ),
              const Padding(padding: const EdgeInsets.only(right: 8)),
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
                                  "${songs.length} 首歌曲",
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
                                  onPressed: songs.isNotEmpty
                                      ? () {
                                          // 属于播放操作：依旧交回给 MusicProvider
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
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: songs.isEmpty
                ? _buildEmptyState(isFavorites, colorScheme, theme)
                : SliverList.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) => _M3SongTile(
                      song: songs[index],
                      musicProvider: musicProvider,
                      onTap: () {
                        musicProvider.playFromLibrary(songs[index]);
                        context.push("/music-detail", extra: songs[index]);
                      },
                      onRemove: isSystem
                          ? null
                          : () => _confirmRemoveSong(context, songs[index].id),
                      onAddToPlaylist: () =>
                          _showAddToPlaylistSheet(context, songs[index]),
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
      child: playlist.coverBytes?.isNotEmpty == true
          ? Image.memory(playlist.coverBytes!, fit: BoxFit.cover)
          : Icon(
              isFavorites
                  ? Icons.favorite_rounded
                  : Icons.playlist_play_rounded,
              size: 60,
              color: colorScheme.primary,
            ),
    );
  }

  Widget _buildEmptyState(
    bool isFavorites,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isFavorites ? "还没有收藏" : "空空如也",
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
  final MusicInfo song;
  final MusicProvider musicProvider;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final VoidCallback onAddToPlaylist;

  const _M3SongTile({
    required this.song,
    required this.musicProvider,
    required this.onTap,
    this.onRemove,
    required this.onAddToPlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = musicProvider.currentMusic?.id == song.id;
    final colorScheme = Theme.of(context).colorScheme;
    final isFav = musicProvider.favList.any((m) => m.id == song.id);

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
            onPressed: () => musicProvider.toggleFav(song),
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

class _AdaptiveActionItem {
  final IconData icon;
  final String title;
  final Color? textColor;
  final Color? iconColor;
  final VoidCallback? onTap;

  _AdaptiveActionItem({
    required this.icon,
    required this.title,
    this.textColor,
    this.iconColor,
    this.onTap,
  });
}
