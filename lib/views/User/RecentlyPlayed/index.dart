import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:provider/provider.dart';

class RecentlyPlayedPage extends StatelessWidget {
  const RecentlyPlayedPage({super.key});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60);
    final hours = d.inHours;
    return hours > 0 ? "$hours小时 $minutes分钟" : "$minutes分钟";
  }

  // 弹窗选择要加入的普通用户歌单
  Future<void> _showAddToPlaylistSheet(BuildContext context, Music song) async {
    final playlistProvider = context.read<PlaylistProvider>();
    if (playlistProvider.userPlaylists.isEmpty) {
      AppToast.neutral(context, message: '暂无自建歌单，请先创建');
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    // 🌟 核心：直接监听 PlaylistProvider 的 history 列表与乐库
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();

    final songs = playlistProvider.history; // 👈 独立数据源，不走 ID 转换

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              // 历史记录不需要上传云端，故不放上传按钮
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
                "最近播放",
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
                          colorScheme.tertiaryContainer.withValues(
                            alpha: 0.6,
                          ), // 换个颜色和普通歌单区分
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
                          // 专属的“最近播放”时间历史图标
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.shadow.withValues(
                                    alpha: 0.12,
                                  ),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.history_rounded,
                              size: 60,
                              color: colorScheme.tertiary,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "系统自动记录的本地播放历史",
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
                                    backgroundColor: colorScheme.tertiary,
                                    foregroundColor: colorScheme.onTertiary,
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
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 64,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "暂无播放记录",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverList.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isCurrent =
                          musicProvider.currentMusic?.id == song.id;

                      // 检查该历史歌曲是否存在于“我喜欢”系统歌单中
                      final isFav = playlistProvider
                          .getPlaylistSongs(
                            PlaylistProvider.favoritesPlaylistId,
                            musicProvider.library,
                          )
                          .any((m) => m.id == song.id);

                      return ListTile(
                        onTap: () {
                          musicProvider.playFromLibrary(song);
                          context.push("/music-detail", extra: song);
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: colorScheme.surfaceContainerHighest,
                            child: song.coverBytes?.isNotEmpty == true
                                ? Image.memory(
                                    song.coverBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.music_note_rounded,
                                    color: colorScheme.primary,
                                  ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrent ? colorScheme.primary : null,
                          ),
                        ),
                        subtitle: Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 20,
                              ),
                              color: isFav ? colorScheme.primary : null,
                              onPressed: () =>
                                  playlistProvider.toggleMusicFavorite(song),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert_rounded),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              onSelected: (val) {
                                if (val == "add") {
                                  _showAddToPlaylistSheet(context, song);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: "add",
                                  child: Text("添加到歌单"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
