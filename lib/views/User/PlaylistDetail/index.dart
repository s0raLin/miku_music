import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
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
  // 专门用来存储桌面端鼠标点按位置的变量
  Offset _actionMenuTapPosition = Offset.zero;

  // --- 逻辑方法区域 ---

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final hours = d.inHours;
    return hours > 0 ? "$hours小时 $minutes分钟" : "$minutes分钟";
  }

  // 统一响应式自适应菜单：手机端 BottomSheet，桌面端 PopupMenu
  void _showResponsiveActionMenu(BuildContext context, Playlist playlist) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    // 定义统一的菜单项数据结构，方便复用
    final menuItems = [
      _AdaptiveActionItem(
        icon: Icons.add_rounded,
        title: "添加歌曲",
        onTap: () => _showModalSideSheet(
          context: context,
          child: Builder(
            builder: (context) {
              return SafeArea(
                child: Padding(
                  // 减小底部边距，让列表可以一直滑到底部
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 固定的头部区域：标题 + 关闭按钮
                      Row(
                        children: [
                          Text(
                            "选择要添加的歌曲",
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            // 点击关闭侧边栏
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // 留点间距
                      // 2. 核心：必须用 Expanded 包裹 ListView，否则会报错崩溃！
                      Expanded(
                        child: ListView.builder(
                          // 假设你有一个歌曲数据列表，这里换成你自己的 List 长度即可
                          itemCount: 50,
                          // 开启预加载，提升鼠标滚动或手指滑动时的流畅度
                          cacheExtent: 100,
                          itemBuilder: (context, index) {
                            // 每一个歌单行组件（支持懒加载，滑到屏幕内才会渲染）
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.music_note_rounded),
                              ),
                              title: Text("测试歌曲名称 #$index"),
                              subtitle: Text("歌手名字 - 专辑 $index"),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                color: Theme.of(context).colorScheme.primary,
                                onPressed: () {
                                  // TODO: 执行添加歌曲的逻辑
                                  print("点击了添加第 $index 首歌曲");
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      _AdaptiveActionItem(
        icon: Icons.edit_note_rounded,
        title: "编辑歌单信息",
        onTap: () => {},
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
      // 1. 桌面端逻辑：在点击坐标处弹出
      final RenderBox overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox;
      showMenu(
        context: context,
        position: RelativeRect.fromRect(
          Rect.fromLTWH(
            _actionMenuTapPosition.dx,
            _actionMenuTapPosition.dy,
            40,
            40,
          ),
          Offset.zero & overlay.size,
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
      // 2. 手机端逻辑：底部弹出菜单
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
              ...menuItems.map((item) {
                return ListTile(
                  leading: Icon(item.icon, color: item.iconColor),
                  title: Text(
                    item.title,
                    style: TextStyle(color: item.textColor),
                  ),
                  onTap: () {
                    Navigator.pop(context); // 先关闭底栏
                    if (item.onTap != null) item.onTap!(); // 再触发事件
                  },
                );
              }),
            ],
          ),
        ),
      );
    }
  }

  void _showModalSideSheet({
    required BuildContext context,
    required Widget child,
    double width = 300,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true, //允许点击背景关闭
      barrierLabel: "Dismiss Side Sheet",
      // pageBuilder 只负责返回组件结构
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 2,
            color: Theme.of(context).colorScheme.surfaceContainer,
            // 顺手加个符合 Material 3 规范的左侧大圆角，更好看！
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(24),
            ),
            child: SizedBox(
              width: width,
              height: double.infinity,
              child: child,
            ),
          ),
        );
      },

      // 把动画移到 transitionBuilder 里，确保进出都有丝滑的动画
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1, 0), // 从屏幕右侧外开始
                end: Offset.zero, // 移动到原点
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ),
              ),
          child: child,
        );
      },
    );
  }

  Future<void> _showDeleteConfirmDialog(
    BuildContext context,
    Playlist playlist,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialogWrapper(
        child: AlertDialog(
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
      ),
    );
    if (confirmed != true || !context.mounted) return;

    context.read<MusicProvider>().deletePlaylist(playlist.id);
    AppToast.neutral(context, message: '歌单「${playlist.name}」已删除');
    Navigator.of(context).pop();
  }

  Future<void> _confirmRemoveSong(
    BuildContext context,
    String playlistId,
    String musicId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => CustomDialogWrapper(
        child: AlertDialog(
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
      ),
    );
    if (confirmed != true || !context.mounted) return;
    context.read<MusicProvider>().removeFromPlaylist(playlistId, musicId);
    AppToast.neutral(context, message: '已从歌单移除');
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
                  final cs = Theme.of(context).colorScheme;
                  return ListTile(
                    enabled: !alreadyIn,
                    leading: const Icon(Icons.playlist_add_rounded),
                    title: Text(p.name),
                    trailing: alreadyIn
                        ? Icon(Icons.check_circle, color: cs.secondary)
                        : null,
                    onTap: () {
                      musicProvider.addToPlaylist(p.id, song);
                      Navigator.pop(context);
                      AppToast.success(context, message: '已添加到「${p.name}」');
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

  Future<void> _showConfirmSyncDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog(
      context: context,
      builder: (context) {
        return CustomDialogWrapper(
          child: AlertDialog(
            title: const Text("上传确认"),
            content: const Text("是否上传到云端?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("取消", style: TextStyle(color: colorScheme.outline)),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("确认"),
              ),
            ],
          ),
        );
      },
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
          // 1. 沉浸式融合头部 (左对齐且支持标题收缩版本)
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            elevation: 0,
            scrolledUnderElevation: 2,
            leading: const BackButton(),
            actions: [
              if (!isSystem)
                Listener(
                  onPointerDown: (event) {
                    _actionMenuTapPosition = event.position;
                  },
                  child: IconButton(
                    onPressed: () =>
                        _showResponsiveActionMenu(context, playlist),
                    icon: const Icon(Icons.more_vert_rounded),
                  ),
                ),
            ],
            // ✨ 关键改动：利用 FlexibleSpaceBar 自身的机制来实现标题的丝滑收缩
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              // 控制标题在展开和折叠状态下的内边距
              titlePadding: EdgeInsets.only(
                left: 56.0, // 折叠后，刚好避开左侧的返回按钮（BackButton 默认宽约 48-56）
                bottom: 16.0, // 展开时，距离底部的间距
                right: 56.0, // 避开右侧的 Action 按钮
              ),
              // 1. 这里的 title 会在滚动时自动放大/缩小、移动位置
              title: Text(
                playlist.name,
                maxLines: 1, // 顶部栏通常只留一行
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              // 2. 这里的 background 负责承载封面、副标题和播放按钮
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 背景渐变色
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
                  // 内容区域
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
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 💡 注意：原有的 playlist.name 标题组件已经移到了外层的 title 属性中
                                // 这里留出相对应的空间，或者放置其他不需要固定在顶部的副标题信息
                                const SizedBox(height: 28),
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
                                const SizedBox(height: 16),
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
      floatingActionButton: SpeedDial(
        icon: Icons.menu,
        activeIcon: Icons.close,
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        overlayColor: colorScheme.scrim,
        overlayOpacity: 0.5,
        spacing: 12,
        children: [
          SpeedDialChild(
            backgroundColor: colorScheme.secondaryContainer,
            labelWidget: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28.0),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '上传',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => _showConfirmSyncDialog(context),
          ),
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

// 辅助类：用于响应式菜单的数据承载
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

// 辅助组件：包裹普通 Dialog，防止 context 分离时的 mounted 警告隐患
class CustomDialogWrapper extends StatelessWidget {
  final Widget child;
  const CustomDialogWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}
