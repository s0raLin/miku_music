import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/model/Playlist/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailPage({super.key, required this.playlistId});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  // --- 逻辑方法区域 ---

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final hours = d.inHours;
    return hours > 0 ? "$hours小时 $minutes分钟" : "$minutes分钟";
  }

  Future<void> _showRenameDialog(
    BuildContext context,
    Playlist playlist,
  ) async {
    final controller = TextEditingController(text: playlist.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("重命名歌单"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "歌单名称"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("确定"),
          ),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      context.read<MusicProvider>().renamePlaylist(playlist.id, newName);
    }
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
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text("删除"),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      context.read<MusicProvider>().deletePlaylist(playlist.id);
      if (mounted) context.pop();
    }
  }

  Future<void> _confirmRemoveSong(
    BuildContext context,
    String playlistId,
    String musicId,
  ) async {
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
    if (confirmed == true) {
      context.read<MusicProvider>().removeFromPlaylist(playlistId, musicId);
    }
  }

  Future<void> _showAddToPlaylistSheet(
    BuildContext context,
    MusicInfo song,
  ) async {
    final musicProvider = context.read<MusicProvider>();
    final userPlaylists = musicProvider.userPlaylists;
    if (userPlaylists.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "添加到歌单",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: userPlaylists.length,
                itemBuilder: (context, index) {
                  final p = userPlaylists[index];
                  final alreadyIn = p.songIds.contains(song.id);
                  return ListTile(
                    enabled: !alreadyIn,
                    leading: const Icon(Icons.playlist_add_rounded),
                    title: Text(p.name),
                    trailing: alreadyIn
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () {
                      musicProvider.addToPlaylist(p.id, song);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI 构建区域 ---

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final playlist = musicProvider.getPlaylistById(widget.playlistId);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (playlist == null) {
      return const Scaffold(body: Center(child: Text("歌单不存在")));
    }

    final songs = musicProvider.getPlaylistSongs(widget.playlistId);
    final isSystem = playlist.isSystem;
    final isFavorites = widget.playlistId == musicProvider.favoritesPlaylistId;
    final totalDuration = songs.fold(
      Duration.zero,
      (prev, s) => prev + s.duration,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // 1. 沉浸式融合头部 (左对齐版本)
          SliverAppBar(
            expandedHeight: 280, // 可根据需要微调
            pinned: true,
            stretch: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            leading: const BackButton(),
            actions: [
              if (!isSystem)
                IconButton(
                  onPressed: () => _showRenameDialog(context, playlist),
                  icon: const Icon(Icons.edit_note_rounded),
                ),
              if (!isSystem)
                IconButton(
                  onPressed: () => _showDeleteConfirmDialog(context, playlist),
                  icon: const Icon(Icons.delete_sweep_rounded),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsets.zero, // 不使用默认 title
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景渐变
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.6),
                          colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                  // 主要内容：左侧封面 + 右侧文字（标题在上）
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildM3Cover(playlist, isFavorites, colorScheme),

                          const SizedBox(width: 20),

                          // 右侧文字区域
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // === 标题放在最上方 ===
                                Text(
                                  playlist.name,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSurface,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  "${songs.length} 首歌曲",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),

                                Text(
                                  _formatDuration(totalDuration),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // 播放按钮
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
                                    size: 24,
                                  ),
                                  label: const Text("播放全部"),
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
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

          // 2. 歌曲列表
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            sliver: songs.isEmpty
                ? _buildEmptyState(isFavorites, colorScheme, theme)
                : SliverList.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      return _M3SongTile(
                        song: songs[index],
                        musicProvider: musicProvider,
                        onTap: () {
                          musicProvider.playFromLibrary(songs[index]);
                          context.push("/music-detail", extra: songs[index]);
                        },
                        onRemove: isSystem
                            ? null
                            : () => _confirmRemoveSong(
                                context,
                                widget.playlistId,
                                songs[index].id,
                              ),
                        onAddToPlaylist: () =>
                            _showAddToPlaylistSheet(context, songs[index]),
                      );
                    },
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
      width: 140, // 侧边布局时封面稍小一点更精致
      height: 140,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: playlist.coverBytes != null && playlist.coverBytes!.isNotEmpty
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
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              isFavorites ? "还没有收藏" : "空空如也",
              style: theme.textTheme.bodyLarge,
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

    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          color: colorScheme.surfaceContainerHighest,
          child: song.coverBytes != null && song.coverBytes!.isNotEmpty
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
              musicProvider.favList.any((m) => m.id == song.id)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              size: 20,
            ),
            color: musicProvider.favList.any((m) => m.id == song.id)
                ? colorScheme.primary
                : null,
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
