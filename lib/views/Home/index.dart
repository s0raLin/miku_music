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
import 'package:myapp/components/Shared/media_overlay_card.dart';
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

                const SizedBox(height: 24),

                // ▲ 横向无框数据流（播放历史 + 队列历史）
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 播放历史
                      _SongHistoryCard(
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        songs: history,
                        musicProvider: musicProvider,
                        maxItems: 4,
                        onViewAll: () => context.push('/user/recent'),
                        onSongTap: (songs, index) async {
                          await musicProvider.replaceQueue(
                            songs,
                            startIndex: index,
                          );
                          if (mounted && musicProvider.currentMusic != null) {
                            context.push('/music-detail');
                          }
                        },
                      ),

                      const SizedBox(width: 20),

                      // 2. 队列历史
                      _QueueHistoryCards(
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        snapshots: musicProvider.history,
                        musicProvider: musicProvider,
                        maxSnapshots: 4,
                        maxSongsPerSnapshot: 4,
                        onRestore: (snapshot) async {
                          await musicProvider.restoreQueueFromHistory(snapshot);
                          if (mounted && musicProvider.currentMusic != null) {
                            context.push('/music-detail');
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ▲ 收藏的音乐
                _MusicSection(
                  title: '收藏的音乐',
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
                    fontWeight: FontWeight.w600,
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
// Music Section — 纯文本标题区域
// ═══════════════════════════════════════════════════════════
class _MusicSection extends StatelessWidget {
  final String title;
  final List<Music> songs;
  final MusicProvider musicProvider;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final String viewAllRoute;
  final String emptyTitle;
  final String emptySubtitle;

  const _MusicSection({
    required this.title,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 16.0 * 2;
    final spacing = 14.0;
    final cardsPerRow = 3.2;
    final cardSize = ((screenWidth - padding - spacing * 2) / cardsPerRow)
        .clamp(80.0, 160.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
          child: Row(
            children: [
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
        songs.isEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: AppPanel(
                  child: AppEmptyState(
                    icon: Icons.favorite_rounded,
                    title: emptyTitle,
                    subtitle: emptySubtitle,
                    compact: true,
                  ),
                ),
              )
            : SizedBox(
                height: cardSize,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemCount: songs.take(6).length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isNetwork = song.source == MusicSource.network;
                    final coverUrl = isNetwork
                        ? musicProvider.getCoverUrl(song.id)
                        : null;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: SizedBox(
                        width: cardSize,
                        height: cardSize,
                        child: MediaOverlayCard(
                          key: ValueKey('song_card_${song.id}'),
                          title: song.title,
                          subtitle: song.artist,
                          source: song.source,
                          coverBytes: song.coverBytes,
                          coverUrl: coverUrl,
                          coverHeaders: isNetwork
                              ? const {'Referer': 'https://music.163.com/'}
                              : null,
                          fallbackIcon: Icons.music_note_rounded,
                          isLoading: isNetwork
                              ? (coverUrl == null &&
                                    musicProvider.isCoverLoading(song.id))
                              : (song.coverBytes == null &&
                                    musicProvider.isCoverLoading(song.id)),
                          borderRadius: BorderRadius.circular(20),
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
                          badge: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh
                                  .withValues(
                                    alpha:
                                        colorScheme.brightness ==
                                            Brightness.dark
                                        ? 0.88
                                        : 0.82,
                                  ),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '#${index + 1}',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
// Vertical Song List Item
// ═══════════════════════════════════════════════════════════
class _SongListTile extends StatelessWidget {
  final Music song;
  final MusicProvider musicProvider;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback? onTap;

  const _SongListTile({
    required this.song,
    required this.musicProvider,
    required this.colorScheme,
    required this.textTheme,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNetwork = song.source == MusicSource.network;
    final coverUrl = isNetwork ? musicProvider.getCoverUrl(song.id) : null;
    final hasCover =
        (song.coverBytes != null && song.coverBytes!.isNotEmpty) ||
        (coverUrl != null && coverUrl.isNotEmpty);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: hasCover
                      ? (song.coverBytes != null && song.coverBytes!.isNotEmpty
                            ? Image.memory(
                                song.coverBytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _fallbackCover(),
                              )
                            : Image.network(
                                coverUrl!,
                                fit: BoxFit.cover,
                                headers: const {
                                  'Referer': 'https://music.163.com/',
                                },
                                errorBuilder: (_, _, _) => _fallbackCover(),
                              ))
                      : _fallbackCover(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist.isEmpty ? '未知歌手' : song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackCover() {
    return Container(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_rounded,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 播放历史 — 无框无图标纯净版
// ═══════════════════════════════════════════════════════════
class _SongHistoryCard extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final List<Music> songs;
  final MusicProvider musicProvider;
  final int maxItems;
  final VoidCallback onViewAll;
  final void Function(List<Music> songs, int index) onSongTap;

  const _SongHistoryCard({
    required this.colorScheme,
    required this.textTheme,
    required this.songs,
    required this.musicProvider,
    required this.maxItems,
    required this.onViewAll,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context) {
    final displaySongs = songs.take(maxItems).toList();

    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部 Header
          SizedBox(
            height: 36,
            child: InkWell(
              onTap: onViewAll,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '播放历史',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            songs.isEmpty ? '暂无历史记录' : '最近播放 ${songs.length} 首',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 列表内容区域
          if (songs.isEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 180),
              child: Center(
                child: AppEmptyState(
                  icon: Icons.history_rounded,
                  title: '暂无播放历史',
                  subtitle: '这里会显示你听过的歌曲',
                  compact: true,
                ),
              ),
            )
          else
            Column(
              children: List.generate(displaySongs.length, (i) {
                return _SongListTile(
                  song: displaySongs[i],
                  musicProvider: musicProvider,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  onTap: () => onSongTap(songs, i),
                );
              }),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 队列历史 — 无框无图标纯净版
// ═══════════════════════════════════════════════════════════
class _QueueHistoryCards extends StatelessWidget {
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final List<QueueSnapshot> snapshots;
  final MusicProvider musicProvider;
  final int maxSnapshots;
  final int maxSongsPerSnapshot;
  final void Function(QueueSnapshot snapshot) onRestore;

  const _QueueHistoryCards({
    required this.colorScheme,
    required this.textTheme,
    required this.snapshots,
    required this.musicProvider,
    required this.maxSnapshots,
    required this.maxSongsPerSnapshot,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final displaySnapshots = snapshots.take(maxSnapshots).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(displaySnapshots.length, (index) {
        final snapshot = displaySnapshots[index];
        final songs = snapshot.songs.take(maxSongsPerSnapshot).toList();

        return SizedBox(
          width: 280,
          child: Padding(
            padding: EdgeInsets.only(
              right: index == displaySnapshots.length - 1 ? 0 : 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 顶部 Header
                SizedBox(
                  height: 36,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${snapshot.songs.length} 首 · ${_formatTime(snapshot.createdAt)}',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton.filledTonal(
                            style: IconButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => onRestore(snapshot),
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 队列内的歌曲列表
                Column(
                  children: List.generate(songs.length, (i) {
                    return _SongListTile(
                      song: songs[i],
                      musicProvider: musicProvider,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      onTap: () => onRestore(snapshot),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    // 防护：如果计算差值为负数（例如系统时间被回调、或跨时区偏差）
    if (diff.isNegative) return '刚刚';

    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }
}
