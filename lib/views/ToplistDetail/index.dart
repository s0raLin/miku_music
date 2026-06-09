import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/model/Toplist/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class ToplistDetailPage extends StatefulWidget {
  const ToplistDetailPage({super.key});

  @override
  State<ToplistDetailPage> createState() => _ToplistDetailPageState();
}

class _ToplistDetailPageState extends State<ToplistDetailPage> {
  ToplistInfo? _info;
  bool _loading = true;
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final info = await MusicApi.fetchToplist();
    if (mounted) {
      setState(() {
        _info = info;
        _loading = false;
      });
    }
  }

  Future<void> _play(ToplistItem song) async {
    setState(() => _playingId = 'net_${song.id}');
    try {
      final mp = context.read<MusicProvider>();
      final url = await NeteaseApi.getRealUrl(song.id, source: song.source);
      if (url == null || url.isEmpty) {
        if (mounted) {
          setState(() => _playingId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取播放链接')),
          );
        }
        return;
      }

      await mp.playNetworkSong(
        url: url,
        id: song.id,
        title: song.title,
        artist: song.author,
        coverUrl: song.pic,
      );

      // 异步加载歌词
      final lyricMap = await NeteaseApi.getLyric(song.id, source: song.source);
      if (lyricMap['lyric'] != null && lyricMap['lyric']!.isNotEmpty && mounted) {
        await mp.setLyricsDirectly(lyricMap['lyric']!);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _playingId = null);
      }
      debugPrint('播放失败: $e');
    }
  }

  void _openDetail(ToplistItem song) {
    _play(song);
    context.push('/music-detail');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(_info?.title ?? '排行榜'),
        scrolledUnderElevation: 0,
      ),
      body: _buildBody(colorScheme, textTheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, TextTheme textTheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_info == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              '加载失败',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                setState(() => _loading = true);
                _loadData();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    final info = _info!;

    final entries = info.items.map((item) {
      return M3SongEntry(
        id: 'net_${item.id}',
        title: item.title,
        subtitle: '${item.author}  ·  ${item.source.toUpperCase()}',
        coverUrl: item.pic,
        coverHeaders: const {'Referer': 'https://music.163.com/'},
        fallbackIcon: Icons.music_note_rounded,
        isHighlighted: _playingId == 'net_${item.id}',
        onTap: () => _openDetail(item),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          onSelected: (v) {
            switch (v) {
              case 'play':
                _play(item);
              case 'detail':
                _openDetail(item);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'play',
              child: ListTile(
                leading: Icon(Icons.play_arrow_rounded),
                title: Text('在线收听'),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            PopupMenuItem(
              value: 'detail',
              child: ListTile(
                leading: Icon(Icons.album_rounded),
                title: Text('查看详情'),
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      );
    }).toList();

    return CustomScrollView(
      slivers: [
        // 头部信息卡片
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primaryContainer.withValues(alpha: 0.3),
                  colorScheme.surface,
                ],
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    info.cover,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    headers: const {'Referer': 'https://music.163.com/'},
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 100,
                      height: 100,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        info.title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        info.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${info.count} 首',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
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

        // 分隔标题
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
            child: Row(
              children: [
                Text(
                  '歌曲列表',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${entries.length} 首',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 歌曲列表
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index.isOdd) return const Divider(height: 1);
                final songIndex = index ~/ 2;
                return M3SongList(
                  songs: [entries[songIndex]],
                  isScrollable: false,
                );
              },
              childCount: entries.length * 2 - 1,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
