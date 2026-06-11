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

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
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

  List<ToplistItem> get _filteredItems {
    if (_info == null) return [];
    if (_query.isEmpty) return _info!.items;
    return _info!.items.where((item) {
      return item.title.toLowerCase().contains(_query) ||
          item.author.toLowerCase().contains(_query) ||
          item.source.toLowerCase().contains(_query) ||
          item.id.contains(_query);
    }).toList();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (_showSearch) {
        // 延迟 focus 等 TextField 构建完成
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _searchFocus.requestFocus();
        });
      } else {
        _searchCtrl.clear();
        _searchFocus.unfocus();
      }
    });
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
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        actionsPadding: EdgeInsets.zero,
        // 搜索模式下标题替换为搜索框
        title: _showSearch
            ? TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                autofocus: true,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '搜索歌曲、歌手...',
                  hintStyle: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(
                    left: 12,
                    top: 12,
                    bottom: 12,
                  ),
                ),
                onChanged: (_) {},
              )
            : null,
        actions: [
          // 搜索模式下：关闭按钮；普通模式：搜索按钮
          if (_showSearch)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              icon: const Icon(Icons.close_rounded),
              tooltip: '关闭搜索',
              onPressed: _toggleSearch,
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: '搜索',
              onPressed: _toggleSearch,
            ),
        ],
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
    final filtered = _filteredItems;

    final entries = filtered.map((item) {
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
          icon: const Icon(Icons.more_vert_rounded, size: 18),
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
        // ── 紧凑头部信息卡片 ──
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    info.cover,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    headers: const {'Referer': 'https://music.163.com/'},
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 64,
                      height: 64,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        info.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.description,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${info.count} 首',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── 搜索结果提示 ──
        if (_query.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
              child: Text(
                '找到 ${filtered.length} 首',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

        // ── 歌曲列表 ──
        if (filtered.isEmpty && _query.isNotEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '未找到匹配歌曲',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            sliver: SliverM3SongList(
              songs: entries,
              padding: EdgeInsets.zero,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}
