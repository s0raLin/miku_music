import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/app_empty_state.dart';
import 'package:myapp/components/Shared/app_panel.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/service/UpdateCheck/index.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/Shared/observable_music_grid_card.dart';
import 'package:myapp/views/User/Music/widgets/playlist_list_card.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _updateCheckStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_updateCheckStarted) {
        _updateCheckStarted = true;
        _checkForUpdate();
      }
    });
  }

  Future<void> _checkForUpdate() async {
    if (!UpdateCheckService.isSupportedPlatform) return;
    try {
      final result = await UpdateCheckService.instance.checkForUpdate();
      if (!mounted) return;
      if (result.hasUpdate && result.latestRelease != null) {
        _showUpdateDialog(result.latestRelease!);
      }
    } catch (e) {
      debugPrint('检查更新失败: $e');
    }
  }

  void _showUpdateDialog(ReleaseInfo releaseInfo) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('发现新版本'),
        content: Text('新版本 ${releaseInfo.tagName} 已发布，是否前往下载？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/update-download', extra: releaseInfo);
            },
            child: const Text('前往下载'),
          ),
        ],
      ),
    );
  }

  void _shufflePlayAll(MusicProvider musicProvider) async {
    final lib = List<Music>.from(musicProvider.library);
    if (lib.isEmpty) return;
    lib.shuffle(Random());
    await musicProvider.replaceQueue(lib, startIndex: 0);
    if (mounted && musicProvider.currentMusic != null) {
      context.push('/music-detail');
    }
  }

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final library = musicProvider.library;

    final history = playlistProvider.getHistorySongs(
      library,
      musicProvider: musicProvider,
    );

    final favorites = playlistProvider.getPlaylistSongs(
      PlaylistProvider.favoritesPlaylistId,
      library,
      musicProvider: musicProvider,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Header ──
          Header(
            pinned: true,
            leading: IconButton(
              onPressed: () =>
                  (context.findAncestorStateOfType<ScaffoldState>())
                      ?.openDrawer(),
              icon: const Icon(Icons.menu),
            ),
            title: Text(
              '发现',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            centerTitle: false,
            flexibleSpace: Container(
              decoration: const BoxDecoration(color: Colors.transparent),
            ),
          ),

          // ── Body ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ▲ Quick Actions
                _QuickActions(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  hasLibrary: library.isNotEmpty,
                  onShufflePlay: () => _shufflePlayAll(musicProvider),
                ),

                const SizedBox(height: 32),

                // ▲ 播放历史（按歌单展示）
                _PlaylistHistorySection(
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  historySongs: history,
                  onViewAll: () => context.push('/user/recent'),
                ),

                const SizedBox(height: 28),

                // ▲ 收藏的音乐
                _MusicSection(
                  title: '收藏的音乐',
                  icon: Icons.favorite_rounded,
                  songs: favorites,
                  musicProvider: musicProvider,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  viewAllRoute: '/user/playlist/favorites',
                  emptyTitle: '还没有收藏歌曲',
                  emptySubtitle: '播放歌曲时点击爱心即可收藏',
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Quick Actions — MD3 快捷操作入口
// ═══════════════════════════════════════════════════════════
class _QuickActions extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool hasLibrary;
  final VoidCallback onShufflePlay;

  const _QuickActions({
    required this.colorScheme,
    required this.textTheme,
    required this.hasLibrary,
    required this.onShufflePlay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ActionChip(
          icon: Icons.shuffle_rounded,
          label: '随机播放',
          colorScheme: colorScheme,
          textTheme: textTheme,
          onTap: hasLibrary ? onShufflePlay : null,
        ),
        const SizedBox(width: 12),
        _ActionChip(
          icon: Icons.search_rounded,
          label: '搜索歌曲',
          colorScheme: colorScheme,
          textTheme: textTheme,
          onTap: () => context.push('/search'),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Expanded(
      child: Material(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: enabled
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Music Section — 横向滚动歌曲卡片区域
// ═══════════════════════════════════════════════════════════
class _MusicSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Music> songs;
  final MusicProvider musicProvider;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String viewAllRoute;
  final String emptyTitle;
  final String emptySubtitle;

  const _MusicSection({
    required this.title,
    required this.icon,
    required this.songs,
    required this.musicProvider,
    required this.colorScheme,
    required this.textTheme,
    required this.viewAllRoute,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (songs.isNotEmpty)
                TextButton(
                  onPressed: () => context.push(viewAllRoute),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '查看全部',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Content
        songs.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AppPanel(
                  child: AppEmptyState(
                    icon: icon,
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                    compact: true,
                  ),
                ),
              )
            : SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemCount: songs.take(6).length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: SizedBox(
                        width: 140,
                        child: ObservableMusicGridCard(
                          index: index,
                          music: song,
                          onTap: () async {
                            await musicProvider.replaceQueue(
                              songs,
                              startIndex: index,
                            );
                            if (context.mounted &&
                                musicProvider.currentMusic != null) {
                              context.push('/music-detail');
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
               ),
       ],
     );
   }
 }

// ═══════════════════════════════════════════════════════════
// Playlist History Section — 按歌单展示播放历史的横向懒加载列表
// ═══════════════════════════════════════════════════════════
class _PlaylistHistorySection extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final List<Music> historySongs;
  final VoidCallback onViewAll;

  const _PlaylistHistorySection({
    required this.colorScheme,
    required this.textTheme,
    required this.historySongs,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.history_rounded,
                  size: 20,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '播放历史',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (historySongs.isNotEmpty)
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    '查看全部',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Content
        historySongs.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AppPanel(
                  child: AppEmptyState(
                    icon: Icons.history_rounded,
                    title: '暂无播放历史',
                    subtitle: '快去听歌吧，这里会显示你听过的歌曲',
                    compact: true,
                  ),
                ),
              )
            : SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemCount: 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: PlaylistListCard(
                          playlistName: '最近播放',
                          songCount: historySongs.length,
                          coverBytes: null,
                          coverPath: null,
                          recentSongs: historySongs.take(4).toList(),
                          showSongList: true,
                          onTap: onViewAll,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
      ],
    );
  }
}
