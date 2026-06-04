import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/api/Model/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/components/Shared/M3SongList.dart';

class NetWorkPage extends StatefulWidget {
  const NetWorkPage({super.key});

  @override
  State<NetWorkPage> createState() => _NetWorkPageState();
}

class _NetWorkPageState extends State<NetWorkPage> {
  List<Music> musics = [];
  bool isLoading = false;
  bool hasAttempted = false;

  Future<void> _fetchMusics() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    List<Music> result;
    try {
      result = await MusicApi.listMusic();
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      if (!hasAttempted) setState(() => hasAttempted = true);
      AppToast.error(
        context,
        message: e.toString(),
        title: '同步失败',
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      musics = result;
      isLoading = false;
      hasAttempted = true;
    });
    AppToast.success(
      context,
      message: '已加载 ${musics.length} 首歌曲',
      title: '同步完成',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final entries = musics.map((music) {
      // Use a simple hash as a local id for network songs
      final localId = 'net_${music.title}_${music.artist}';
      return M3SongEntry(
        id: localId,
        title: music.title,
        subtitle: '${music.artist} - ${music.album}',
        coverUrl: music.coverUrl,
        fallbackIcon: Icons.cloud_outlined,
        onTap: () {
          context.push("/music-detail", extra: music);
        },
      );
    }).toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetchMusics,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              title: const Text("网络"),
              pinned: true,
              actions: [
                if (!isLoading && musics.isEmpty && hasAttempted)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: "重新获取",
                    onPressed: _fetchMusics,
                  ),
              ],
            ),

            // ---- 头部信息卡片 ----
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Card.filled(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_queue_rounded,
                            size: 48, color: colorScheme.primary),
                        const SizedBox(height: 12),
                        Text(
                          "云端曲库",
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "从服务器同步歌曲资源",
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (musics.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            "${musics.length} 首歌曲",
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (isLoading)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          FilledButton.icon(
                            onPressed: _fetchMusics,
                            icon: const Icon(Icons.cloud_download_rounded,
                                size: 20),
                            label: Text(musics.isEmpty ? "获取歌曲" : "重新同步"),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ---- 歌曲列表 ----
            if (musics.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                sliver: SliverM3SongList(
                  songs: entries,
                  padding: const EdgeInsets.all(8),
                  coverLoader: null, // Network songs don't use local cover loader
                ),
              ),

            if (musics.isEmpty &&
                !isLoading &&
                hasAttempted)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_off_rounded,
                          size: 64,
                          color: colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        "暂无云端歌曲",
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
