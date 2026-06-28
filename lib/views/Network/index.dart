import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/api/Model/NeteasePlaylist/index.dart';
import 'package:myapp/api/Model/NeteaseSong/index.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════
//  NetworkSongPage  —  顶层页面，承载两个独立 Tab
// ═══════════════════════════════════════════════════════════════

class NetworkSongPage extends StatefulWidget {
  const NetworkSongPage({super.key});

  @override
  State<NetworkSongPage> createState() => _NetworkSongPageState();
}

class _NetworkSongPageState extends State<NetworkSongPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      // 顶部 Surface 色彩区域
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            // ── MD3 Secondary TabBar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  labelColor: cs.primary,
                  unselectedLabelColor: cs.onSurfaceVariant,
                  labelStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  unselectedLabelStyle: tt.labelLarge,
                  tabs: const [
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_note_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('歌曲'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 40,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.queue_music_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('歌单'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Tab Views ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [_SongSearchTab(), _PlaylistSearchTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  公共组件 — MD3 风格搜索栏
// ═══════════════════════════════════════════════════════════════

class _M3SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _M3SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.isLoading,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SearchBar(
      controller: controller,
      focusNode: focusNode,
      hintText: hintText,
      leading: Icon(Icons.search_rounded, color: cs.onSurfaceVariant, size: 20),
      trailing: [
        if (controller.text.trim().isNotEmpty)
          IconButton(
            icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
            onPressed: onClear,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                )
              : FilledButton.tonal(
                  onPressed: onSearch,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                    minimumSize: const Size(0, 34),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('搜索'),
                ),
        ),
      ],
      onSubmitted: (_) => onSearch(),
      elevation: WidgetStateProperty.all(0),
      backgroundColor: WidgetStateProperty.all(cs.surfaceContainerHigh),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      constraints: const BoxConstraints(minHeight: 52),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  公共组件 — 推荐标签 Chip
// ═══════════════════════════════════════════════════════════════

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  公共组件 — 空态页（未搜索 / 无结果）
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final List<String> tags;
  final void Function(String tag) onTagTap;

  const _EmptyState({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tags,
    required this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = iconColor ?? cs.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      children: [
        // 图标卡片
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 40, color: color),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),

        // 分隔线 + 标签
        Row(children: [
          Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '推荐搜索',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5))),
        ]),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map((t) => _SuggestionChip(label: t, onTap: () => onTagTap(t)))
              .toList(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 1 — 歌曲搜索
// ═══════════════════════════════════════════════════════════════

class _SongSearchTab extends StatefulWidget {
  const _SongSearchTab();
  @override
  State<_SongSearchTab> createState() => _SongSearchTabState();
}

class _SongSearchTabState extends State<_SongSearchTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<NeteaseSong> _results = [];
  bool _isSearching = false;
  bool _isFiltering = false;
  bool _hasSearched = false;
  String? _statusMsg;

  static const _tags = [
    '初音ミク', 'DECO*27', 'ピノキオピー', 'MARETU',
    'きくお', 'ナユタン星人', 'sasakure.UK', '黒うさP', 'VOCALOID', 'J-POP',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _focus.unfocus();
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
      setState(() { _isSearching = false; _statusMsg = '搜索失败: $e'; });
    }
  }

  Future<void> _filter() async {
    if (_results.isEmpty) {
      setState(() { _isFiltering = false; _statusMsg = '未找到可播放的歌曲'; });
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

  Future<void> _play(NeteaseSong song) async {
    try {
      final mp = context.read<MusicProvider>();
      final idx = _results.indexOf(song);
      if (idx < 0) return;
      final songMaps = _results.map((s) => {
        'id': s.id, 'title': s.title, 'artist': s.author,
        'url': s.url, 'coverUrl': s.pic,
        'lyrics': mp.getCachedLyrics('net_${s.id}'),
      }).toList();
      await mp.playNetworkSearchResults(songs: songMaps, startIndex: idx);
      final lr = await NeteaseApi.getLyric(song.id);
      if ((lr['lyric']?.isNotEmpty ?? false) && mounted) {
        await mp.setLyricsDirectly(lr['lyric']!);
      }
    } catch (e) {
      if (!mounted) return;
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
      final m3MusicDir = await FileService.getM3MusicDir();
      if (!await m3MusicDir.exists()) await m3MusicDir.create(recursive: true);
      final safeTitle = song.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
      final safeArtist = song.author.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
      final songDir = Directory(p.join(m3MusicDir.path, '$safeTitle - $safeArtist'));
      if (!await songDir.exists()) await songDir.create(recursive: true);
      String ext = p.url.extension(song.url);
      if (ext.contains('?')) ext = ext.split('?').first;
      if (ext.isEmpty || ext.length > 5) ext = '.mp3';
      final audioPath = p.join(songDir.path, '$safeTitle - $safeArtist$ext');
      final audioResult = await NeteaseApi.downloadSong(song.url, audioPath);
      String? lrcPath;
      try {
        final lyricMap = await NeteaseApi.getLyric(song.id);
        final lyricContent = lyricMap['lyric'];
        if (lyricContent != null && lyricContent.isNotEmpty) {
          lrcPath = p.join(songDir.path, '$safeTitle - $safeArtist.lrc');
          await File(lrcPath).writeAsString(lyricContent);
        }
      } catch (_) {}
      String? coverPath;
      try {
        if (song.pic.isNotEmpty) {
          coverPath = p.join(songDir.path, 'cover.jpg');
          await NeteaseApi.downloadCover(song.pic, coverPath);
        }
      } catch (_) {}
      try {
        final meta = {
          'id': song.id, 'title': song.title, 'author': song.author, 'source': song.source,
          if (audioResult != null) 'audio_path': audioResult,
          if (lrcPath != null) 'lyric_path': lrcPath,
          if (coverPath != null) 'cover_path': coverPath,
        };
        await File(p.join(songDir.path, 'metadata.json'))
            .writeAsString(const JsonEncoder.withIndent('  ').convert(meta));
      } catch (_) {}
      if (!mounted) return;
      if (audioResult != null) {
        final buf = StringBuffer('已保存到: $audioPath');
        if (lrcPath != null) buf.write('\n歌词: $lrcPath');
        if (coverPath != null) buf.write('\n封面: $coverPath');
        AppToast.success(context, message: buf.toString(), title: '下载完成');
      } else {
        AppToast.error(context, message: '下载失败', title: '错误');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, message: '下载失败: $e', title: '错误');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currentMusic = context.watch<MusicProvider>().currentMusic;
    final currentNetId = currentMusic?.id.startsWith('net_') == true
        ? currentMusic!.id.substring(4) : null;
    final isLoading = _isSearching || _isFiltering;

    final entries = _results.map((s) => M3SongEntry(
      id: 'net_${s.id}',
      title: s.title,
      subtitle: '${s.author}  ·  ${s.source.toUpperCase()}',
      coverUrl: s.pic,
      coverHeaders: const {'Referer': 'https://music.163.com/'},
      fallbackIcon: Icons.music_note_rounded,
      isHighlighted: currentNetId == s.id,
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert_rounded, size: 18, color: cs.onSurfaceVariant),
        onSelected: (v) {
          if (v == 'play') _play(s);
          else if (v == 'detail') _openDetail(s);
          else if (v == 'download') _download(s);
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'play',
            child: ListTile(
              leading: Icon(Icons.play_arrow_rounded, color: cs.primary),
              title: const Text('在线收听'),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          PopupMenuItem(
            value: 'detail',
            child: ListTile(
              leading: Icon(Icons.album_rounded, color: cs.secondary),
              title: const Text('查看详情'),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          PopupMenuItem(
            value: 'download',
            child: ListTile(
              leading: Icon(Icons.download_rounded, color: cs.tertiary),
              title: const Text('下载到本地'),
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
      onTap: () => _openDetail(s),
    )).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: _M3SearchBar(
          controller: _ctrl,
          focusNode: _focus,
          hintText: '搜索歌曲、歌手...',
          isLoading: isLoading,
          onSearch: _search,
          onClear: () => setState(() {
            _ctrl.clear(); _results = []; _hasSearched = false; _statusMsg = null;
          }),
        ),
      ),
      Expanded(child: _buildBody(cs, tt, entries)),
    ]);
  }

  Widget _buildBody(ColorScheme cs, TextTheme tt, List<M3SongEntry> entries) {
    if (!_hasSearched) {
      return _EmptyState(
        icon: Icons.cloud_queue_rounded,
        title: '在线歌曲搜索',
        subtitle: '搜索网易云音乐，在线收听或下载',
        tags: _tags,
        onTagTap: (t) { _ctrl.text = t; _search(); },
      );
    }

    if (_isSearching || _isFiltering) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: cs.primary),
        const SizedBox(height: 16),
        Text(_statusMsg ?? '', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        if (_isFiltering) ...[
          const SizedBox(height: 6),
          Text('正在验证可播放链接...',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.6))),
        ],
      ]));
    }

    if (_results.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.errorContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cloud_off_rounded, size: 36, color: cs.error),
        ),
        const SizedBox(height: 16),
        Text(_statusMsg ?? '未找到可播放的歌曲',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: _search,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('重新搜索'),
        ),
      ]));
    }

    return Column(children: [
      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
      Expanded(
        child: M3SongList(songs: entries, isScrollable: true),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 2 — 歌单搜索
// ═══════════════════════════════════════════════════════════════

class _PlaylistSearchTab extends StatefulWidget {
  const _PlaylistSearchTab();
  @override
  State<_PlaylistSearchTab> createState() => _PlaylistSearchTabState();
}

class _PlaylistSearchTabState extends State<_PlaylistSearchTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  List<NeteasePlaylistItem> _playlists = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _statusMsg;

  NeteasePlaylistItem? _openedPlaylist;
  NeteasePlaylistDetail? _detail;
  bool _isLoadingDetail = false;
  String? _detailError;

  static const _tags = [
    '初音ミク', 'VOCALOID', 'J-POP', '电波曲', '术力口', 'lo-fi', '纯音乐', '学习', '治愈',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    _focus.unfocus();
    setState(() {
      _isSearching = true; _hasSearched = true;
      _statusMsg = '正在搜索歌单...';
      _playlists = []; _openedPlaylist = null; _detail = null;
    });
    try {
      final list = await NeteaseApi.searchPlaylists(q);
      if (!mounted) return;
      setState(() {
        _playlists = list; _isSearching = false;
        _statusMsg = list.isEmpty ? '未找到相关歌单' : '找到 ${list.length} 个歌单';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isSearching = false; _statusMsg = '搜索失败: $e'; });
    }
  }

  Future<void> _openPlaylist(NeteasePlaylistItem item) async {
    if (_openedPlaylist?.id == item.id && _detail != null) {
      setState(() { _openedPlaylist = null; _detail = null; });
      return;
    }
    setState(() {
      _openedPlaylist = item; _detail = null;
      _isLoadingDetail = true; _detailError = null;
    });
    try {
      final d = await NeteaseApi.getPlaylistDetail(item.id);
      if (!mounted) return;
      setState(() { _detail = d; _isLoadingDetail = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoadingDetail = false; _detailError = '加载失败: $e'; });
    }
  }

  Future<void> _playPlaylistFrom(int startIndex) async {
    final songs = _detail?.songs;
    if (songs == null || songs.isEmpty) return;
    try {
      final mp = context.read<MusicProvider>();
      final songMaps = songs.map((s) => <String, String?>{
        'id': s.id, 'title': s.title, 'artist': s.author,
        'url': '', 'coverUrl': s.pic,
        'lyrics': mp.getCachedLyrics('net_${s.id}'),
      }).toList();
      await mp.playNetworkSearchResults(songs: songMaps, startIndex: startIndex);
      final lr = await NeteaseApi.getLyric(songs[startIndex].id);
      if ((lr['lyric']?.isNotEmpty ?? false) && mounted) {
        await mp.setLyricsDirectly(lr['lyric']!);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, message: '播放失败: $e', title: '错误');
    }
  }

  void _openDetailPage(NeteasePlaylistSong song) {
    final idx = _detail!.songs.indexOf(song);
    _playPlaylistFrom(idx);
    context.push('/music-detail');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: _M3SearchBar(
          controller: _ctrl,
          focusNode: _focus,
          hintText: '搜索歌单名称...',
          isLoading: _isSearching,
          onSearch: _search,
          onClear: () => setState(() {
            _ctrl.clear(); _playlists = []; _hasSearched = false;
            _statusMsg = null; _openedPlaylist = null; _detail = null;
          }),
        ),
      ),
      Expanded(child: _buildBody(cs, tt)),
    ]);
  }

  Widget _buildBody(ColorScheme cs, TextTheme tt) {
    if (!_hasSearched) {
      return _EmptyState(
        icon: Icons.queue_music_rounded,
        iconColor: cs.secondary,
        title: '在线歌单搜索',
        subtitle: '搜索网易云歌单，一键播放整个歌单',
        tags: _tags,
        onTagTap: (t) { _ctrl.text = t; _search(); },
      );
    }

    if (_isSearching) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(color: cs.secondary),
        const SizedBox(height: 16),
        Text(_statusMsg ?? '', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ]));
    }

    if (_playlists.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.playlist_remove_rounded, size: 36, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Text(_statusMsg ?? '未找到相关歌单',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: _search,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('重新搜索'),
        ),
      ]));
    }

    return Column(children: [
      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
          itemCount: _playlists.length,
          itemBuilder: (ctx, i) {
            final item = _playlists[i];
            final isOpen = _openedPlaylist?.id == item.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _PlaylistCard(
                item: item,
                isOpen: isOpen,
                isLoadingDetail: isOpen && _isLoadingDetail,
                detail: isOpen ? _detail : null,
                detailError: isOpen ? _detailError : null,
                currentMusic: context.watch<MusicProvider>().currentMusic,
                onTap: () => _openPlaylist(item),
                onPlayAll: () => _playPlaylistFrom(0),
                onPlaySong: (song) => _playPlaylistFrom(_detail!.songs.indexOf(song)),
                onOpenDetail: _openDetailPage,
              ),
            );
          },
        ),
      ),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
//  歌单卡片（可展开）— MD3 风格
// ═══════════════════════════════════════════════════════════════

class _PlaylistCard extends StatelessWidget {
  final NeteasePlaylistItem item;
  final bool isOpen;
  final bool isLoadingDetail;
  final NeteasePlaylistDetail? detail;
  final String? detailError;
  final dynamic currentMusic;
  final VoidCallback onTap;
  final VoidCallback onPlayAll;
  final void Function(NeteasePlaylistSong) onPlaySong;
  final void Function(NeteasePlaylistSong) onOpenDetail;

  const _PlaylistCard({
    required this.item,
    required this.isOpen,
    required this.isLoadingDetail,
    required this.detail,
    required this.detailError,
    required this.currentMusic,
    required this.onTap,
    required this.onPlayAll,
    required this.onPlaySong,
    required this.onOpenDetail,
  });

  String _fmt(int n) {
    if (n >= 100000000) return '${(n / 100000000).toStringAsFixed(1)}亿';
    if (n >= 10000) return '${(n / 10000).toStringAsFixed(1)}w';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: isOpen ? cs.primaryContainer.withValues(alpha: 0.08) : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 歌单头部 ──
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                // 封面
                _PlaylistCover(pic: item.pic, size: 60),
                const SizedBox(width: 12),
                // 信息
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.person_outline_rounded, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          item.creator,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    // 播放量 + 曲目数 Chip 风格
                    Row(children: [
                      _StatChip(
                        icon: Icons.headphones_rounded,
                        label: _fmt(item.playCount),
                        color: cs.primary,
                      ),
                      const SizedBox(width: 6),
                      _StatChip(
                        icon: Icons.music_note_rounded,
                        label: '${item.trackCount} 首',
                        color: cs.secondary,
                      ),
                    ]),
                  ],
                )),
                // 展开/收起按钮
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isOpen
                        ? cs.primary.withValues(alpha: 0.12)
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: isOpen ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ]),
            ),
          ),

          // ── 展开区域 ──
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isOpen
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.3)),
                      if (isLoadingDetail)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
                            ),
                            const SizedBox(height: 10),
                            Text('加载歌单中...',
                                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                          ]),
                        )
                      else if (detailError != null)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(children: [
                            Icon(Icons.error_outline_rounded, size: 16, color: cs.error),
                            const SizedBox(width: 8),
                            Expanded(child: Text(detailError!,
                                style: tt.bodySmall?.copyWith(color: cs.error))),
                          ]),
                        )
                      else if (detail != null)
                        _PlaylistDetailPanel(
                          detail: detail!,
                          currentMusic: currentMusic,
                          onPlayAll: onPlayAll,
                          onPlaySong: onPlaySong,
                          onOpenDetail: onOpenDetail,
                        ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── 封面小组件 ──
class _PlaylistCover extends StatelessWidget {
  final String pic;
  final double size;
  const _PlaylistCover({required this.pic, required this.size});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: size, height: size,
        child: pic.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: pic, fit: BoxFit.cover,
                httpHeaders: const {
                  'Referer': 'https://music.163.com/', 'User-Agent': 'Mozilla/5.0',
                },
                placeholder: (_, __) => Container(color: cs.surfaceContainerHighest),
                errorWidget: (_, __, ___) => _FallbackCover(size: size),
              )
            : _FallbackCover(size: size),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  final double size;
  const _FallbackCover({required this.size});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(Icons.queue_music_rounded,
          size: size * 0.4, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
    );
  }
}

// ── 统计数据 Chip ──
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 3),
        Text(label, style: tt.labelSmall?.copyWith(color: color, fontSize: 10)),
      ]),
    );
  }
}

// ── 歌单详情面板（分页懒加载）──
class _PlaylistDetailPanel extends StatefulWidget {
  final NeteasePlaylistDetail detail;
  final dynamic currentMusic;
  final VoidCallback onPlayAll;
  final void Function(NeteasePlaylistSong) onPlaySong;
  final void Function(NeteasePlaylistSong) onOpenDetail;

  const _PlaylistDetailPanel({
    required this.detail,
    required this.currentMusic,
    required this.onPlayAll,
    required this.onPlaySong,
    required this.onOpenDetail,
  });

  @override
  State<_PlaylistDetailPanel> createState() => _PlaylistDetailPanelState();
}

class _PlaylistDetailPanelState extends State<_PlaylistDetailPanel> {
  static const _pageSize = 30;
  int _visibleCount = _pageSize;

  @override
  void didUpdateWidget(_PlaylistDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 歌单切换时重置
    if (oldWidget.detail.playlistName != widget.detail.playlistName) {
      _visibleCount = _pageSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final songs = widget.detail.songs;
    final shown = songs.take(_visibleCount).toList();
    final hasMore = _visibleCount < songs.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 操作栏
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(children: [
            Expanded(
              child: Text(
                widget.detail.playlistName,
                style: tt.labelMedium?.copyWith(
                    color: cs.onSurfaceVariant, fontWeight: FontWeight.w500),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: widget.onPlayAll,
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('播放全部'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ]),
        ),
        Divider(height: 1, indent: 14, endIndent: 14,
            color: cs.outlineVariant.withValues(alpha: 0.3)),
        // 已显示的歌曲行
        ...shown.asMap().entries.map((e) {
          final i = e.key;
          final song = e.value;
          final isPlaying = widget.currentMusic?.id == 'net_${song.id}';
          return _PlaylistSongRow(
            index: i,
            song: song,
            isPlaying: isPlaying,
            onTap: () => widget.onOpenDetail(song),
            onPlay: () => widget.onPlaySong(song),
          );
        }),
        // 加载更多 / 已显示全部
        if (hasMore)
          TextButton.icon(
            onPressed: () => setState(() {
              _visibleCount = (_visibleCount + _pageSize).clamp(0, songs.length);
            }),
            icon: const Icon(Icons.expand_more_rounded, size: 16),
            label: Text('加载更多  ${shown.length} / ${songs.length}'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              minimumSize: const Size(double.infinity, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: tt.labelSmall,
            ),
          )
        else if (songs.length > _pageSize)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '已显示全部 ${songs.length} 首',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── 歌单内歌曲行 ──
class _PlaylistSongRow extends StatelessWidget {
  final int index;
  final NeteasePlaylistSong song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _PlaylistSongRow({
    required this.index,
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(children: [
          // 序号 / 播放动效
          SizedBox(
            width: 26,
            child: isPlaying
                ? Icon(Icons.equalizer_rounded, size: 14, color: cs.primary)
                : Text(
                    '${index + 1}',
                    textAlign: TextAlign.center,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          // 封面
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 38, height: 38,
              child: song.pic.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: song.pic, fit: BoxFit.cover,
                      httpHeaders: const {
                        'Referer': 'https://music.163.com/', 'User-Agent': 'Mozilla/5.0',
                      },
                      placeholder: (_, __) =>
                          Container(color: cs.surfaceContainerHighest),
                      errorWidget: (_, __, ___) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Icon(Icons.music_note_rounded, size: 16,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                      ),
                    )
                  : Container(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.music_note_rounded, size: 16,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                    ),
            ),
          ),
          const SizedBox(width: 10),
          // 标题 + 歌手
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.title,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(
                  fontWeight: isPlaying ? FontWeight.w600 : FontWeight.w500,
                  color: isPlaying ? cs.primary : cs.onSurface,
                ),
              ),
              Text(
                song.author,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: tt.labelSmall?.copyWith(
                  color: isPlaying
                      ? cs.primary.withValues(alpha: 0.7)
                      : cs.onSurfaceVariant,
                ),
              ),
            ],
          )),
          // 播放按钮
          IconButton(
            onPressed: onPlay,
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 18,
              color: isPlaying ? cs.primary : cs.onSurfaceVariant,
            ),
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(4),
          ),
        ]),
      ),
    );
  }
}
