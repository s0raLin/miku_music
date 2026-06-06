import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/api/Model/NeteaseSong/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class NetworkSongPage extends StatefulWidget {
  const NetworkSongPage({super.key});

  @override
  State<NetworkSongPage> createState() => _NetworkSongPageState();
}

class _NetworkSongPageState extends State<NetworkSongPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<NeteaseSong> _results = [];
  bool _isSearching = false;
  bool _isFiltering = false;
  bool _hasSearched = false;
  String? _statusMsg;
  String? _playingId;

  final List<String> _suggestedTags = [
    '初音ミク',
    'DECO*27',
    'ピノキオピー',
    'MARETU',
    'きくお',
    'ナユタン星人',
    'sasakure.UK',
    '黒うさP',
    'VOCALOID',
    'J-POP',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── Search ───

  Future<void> _search() async {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _statusMsg = '正在搜索...';
      _results = [];
    });

    try {
      final raw = await NeteaseApi.search(q);
      if (!mounted) return;
      setState(() {
        _results = raw;
        _isSearching = false;
        _statusMsg = '搜索到 ${raw.length} 首，正在过滤可播放链接...';
      });
      await _filter();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _statusMsg = '搜索失败: $e';
      });
    }
  }

  Future<void> _filter() async {
    if (_results.isEmpty) {
      setState(() {
        _isFiltering = false;
        _statusMsg = '未找到可播放的歌曲';
      });
      return;
    }
    setState(() => _isFiltering = true);
    final ok = await NeteaseApi.filterAccessible(_results);
    if (!mounted) return;
    setState(() {
      _results = ok;
      _isFiltering = false;
      _statusMsg = ok.isEmpty ? '所有链接均无法访问' : '已找到 ${ok.length} 首可播放歌曲';
    });
  }

  // ─── Play / Detail ───

  Future<void> _play(NeteaseSong song) async {
    setState(() => _playingId = song.id);
    try {
      final mp = context.read<MusicProvider>();
      final lyricF = NeteaseApi.getLyric(song.id);

      await mp.playNetworkSong(
        url: song.url,
        id: song.id,
        title: song.title,
        artist: song.author,
        coverUrl: song.pic,
      );

      final lr = await lyricF;
      if (lr['lyric'] != null && lr['lyric']!.isNotEmpty && mounted) {
        await mp.setLyricsDirectly(lr['lyric']!);
      }

      if (!mounted) return;
      AppToast.success(
        context,
        message: '${song.title} - ${song.author}',
        title: '正在播放',
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _playingId = null);
      AppToast.error(context, message: '播放失败: $e', title: '错误');
    }
  }

  void _openDetail(NeteaseSong song) {
    _play(song);
    context.push('/music-detail');
  }

  Future<void> _download(NeteaseSong song) async {
    try {
      AppToast.neutral(context, message: '正在下载: ${song.title}', title: '下载中');
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/downloads');
      if (!await musicDir.exists()) await musicDir.create(recursive: true);
      final safeName = song.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final path = '${musicDir.path}/$safeName - ${song.author}.mp3';
      final ok = await NeteaseApi.downloadSong(song.url, path);
      if (!mounted) return;
      if (ok != null) {
        AppToast.success(context, message: '已保存到: $path', title: '下载完成');
      } else {
        AppToast.error(context, message: '下载失败', title: '错误');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, message: '下载失败: $e', title: '错误');
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final entries = _results.map((s) => M3SongEntry(
      id: 'net_${s.id}',
      title: s.title,
      subtitle: '${s.author}  ·  ${s.source.toUpperCase()}',
      coverUrl: s.pic,
      coverHeaders: const {'Referer': 'https://music.163.com/'},
      fallbackIcon: Icons.music_note_rounded,
      isHighlighted: _playingId == s.id,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, size: 20),
        onSelected: (v) {
          switch (v) {
            case 'play': _play(s);
            case 'detail': _openDetail(s);
            case 'download': _download(s);
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'play', child: ListTile(leading: Icon(Icons.play_arrow_rounded), title: Text('在线收听'), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
          PopupMenuItem(value: 'detail', child: ListTile(leading: Icon(Icons.album_rounded), title: Text('查看详情'), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
          PopupMenuItem(value: 'download', child: ListTile(leading: Icon(Icons.download_rounded), title: Text('下载到本地'), contentPadding: EdgeInsets.zero, visualDensity: VisualDensity.compact)),
        ],
      ),
      onTap: () => _openDetail(s),
    )).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBar(
                      controller: _searchController,
                      focusNode: _focusNode,
                      hintText: '搜索网易云音乐...',
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        if (_searchController.text.trim().isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() { _results = []; _hasSearched = false; _statusMsg = null; });
                            },
                          ),
                      ],
                      onSubmitted: (_) => _search(),
                      elevation: WidgetStateProperty.all(0.0),
                      backgroundColor: WidgetStateProperty.all(cs.surfaceContainerHigh),
                      shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSearching || _isFiltering ? null : _search,
                    icon: (_isSearching || _isFiltering)
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(child: _buildContent(cs, tt, entries)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, TextTheme tt, List<M3SongEntry> entries) {
    if (!_hasSearched) return _buildSuggestions(cs, tt);

    if (_isSearching || _isFiltering) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_statusMsg ?? '', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            if (_isFiltering) ...[
              const SizedBox(height: 8),
              Text('检测歌曲链接可用性...', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7))),
            ],
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(_statusMsg ?? '未找到可播放的歌曲', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: _search, icon: const Icon(Icons.refresh_rounded), label: const Text('重新搜索')),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Icon(Icons.cloud_done_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              Text(_statusMsg ?? '', style: tt.labelSmall?.copyWith(color: cs.primary)),
              const Spacer(),
              TextButton.icon(onPressed: _search, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('重新搜索'), style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: M3SongList(songs: entries, isScrollable: true),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(ColorScheme cs, TextTheme tt) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: Column(
            children: [
              Icon(Icons.cloud_queue_rounded, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text('在线音乐搜索', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('搜索网易云音乐，在线收听或下载', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('搜索推荐', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 4,
          children: _suggestedTags.map((t) => FilterChip(
            label: Text(t),
            labelStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            backgroundColor: cs.surfaceContainerLow,
            side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (_) { _searchController.text = t; _search(); },
          )).toList(),
        ),
      ],
    );
  }
}
