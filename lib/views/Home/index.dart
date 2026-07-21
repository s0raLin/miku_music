import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/app_empty_state.dart';
import 'package:myapp/components/Shared/app_panel.dart';
import 'package:myapp/components/Shared/app_section_header.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/service/UpdateCheck/index.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/Shared/observable_music_grid_card.dart';
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
      extendBodyBehindAppBar: true,
      backgroundColor: colorScheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.15),
              colorScheme.surface,
              colorScheme.surface,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Header
            Header(
              pinned: true,
              leading: IconButton(
                onPressed: () =>
                    (context.findAncestorStateOfType<ScaffoldState>())
                        ?.openDrawer(),
                icon: const Icon(Icons.menu),
              ),
              // ✨ 修改 1：给标题添加左侧 Padding，让“发现”往右缩进一点
              title: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: Text(
                  '发现',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              centerTitle: false,
              flexibleSpace: Container(
                decoration: const BoxDecoration(color: Colors.transparent),
              ),
            ),

            // 2. 页面主体内容
            SliverPadding(
              padding: const EdgeInsets.only(top: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 2.1 欢迎头部
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: colorScheme.tertiaryContainer,
                          child: Icon(
                            Icons.headphones_rounded,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '音乐新征程，从这里开始',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '00: 欢迎您',
                              style: textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 2.2 横向播放历史列表
                  // ✨ 修改 2：给 AppSectionHeader 加上左侧 Padding，确保它与下面的卡片一致
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: AppSectionHeader(
                      title: '播放历史',
                      action: history.isNotEmpty
                          ? TextButton.icon(
                              onPressed: () {
                                context.push('/user/recent');
                              },
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: const Text('查看更多'),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  history.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: history.take(6).length,
                            itemBuilder: (context, index) {
                              final song = history[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 170,
                                  child: ObservableMusicGridCard(
                                    index: index,
                                    music: song,
                                    onTap: () async {
                                      await musicProvider.replaceQueue(
                                        history,
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

                  const SizedBox(height: 32),

                  // 2.3 横向收藏列表
                  // ✨ 修改 3：同样给 AppSectionHeader 加上左侧 Padding
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                    child: AppSectionHeader(
                      title: '收藏的音乐',
                      action: favorites.isNotEmpty
                          ? TextButton.icon(
                              onPressed: () {
                                context.push('/user/playlist/favorites');
                              },
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                              ),
                              label: const Text('查看更多'),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),

                  favorites.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                          child: AppPanel(
                            child: AppEmptyState(
                              icon: Icons.favorite_border_rounded,
                              title: '还没有收藏歌曲',
                              subtitle: '播放歌曲时点击爱心即可收藏',
                              compact: true,
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 180,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: favorites.take(6).length,
                            itemBuilder: (context, index) {
                              final song = favorites[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: SizedBox(
                                  width: 170,
                                  child: ObservableMusicGridCard(
                                    index: index,
                                    music: song,
                                    onTap: () async {
                                      await musicProvider.replaceQueue(
                                        favorites,
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
                  const SizedBox(height: 60),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
