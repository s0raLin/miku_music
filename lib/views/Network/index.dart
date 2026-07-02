import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/api/Model/NeteasePlaylist/index.dart';
import 'package:myapp/api/Model/NeteaseSong/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════
//  NetworkSongPage  —  SegmentedButton + 搜索栏 + 内容区
// ═══════════════════════════════════════════════════════════════

class NetworkSongPage extends StatefulWidget {
  const NetworkSongPage({super.key});

  @override
  State<NetworkSongPage> createState() => _NetworkSongPageState();
}

class _NetworkSongPageState extends State<NetworkSongPage> {
  int _currentIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  // 标志：当前激活的 tab 是否已执行过一次搜索
  final Map<int, bool> _hasSearched = {0: false, 1: false};

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    _searchFocus.unfocus();
    _hasSearched[_currentIndex] = true;
    setState(() {});
  }

  void _onClear() {
    setState(() {
      _searchCtrl.clear();
      _hasSearched[_currentIndex] = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasText = _searchCtrl.text.trim().isNotEmpty;
    final isFirstTab = _currentIndex == 0;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          const SizedBox(height: 8),
          // ── ToggleButtons 切换 ──────────────────────────────────────
          Center(
            child: ToggleButtons(
              isSelected: [_currentIndex == 0, _currentIndex == 1],
              onPressed: (i) => setState(() => _currentIndex = i),
              borderRadius: BorderRadius.circular(12),
              selectedColor: cs.onPrimary,
              fillColor: cs.primary,
              color: cs.onSurfaceVariant,
              constraints: const BoxConstraints(
                minWidth: 72,
                minHeight: 36,
              ),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.music_note_rounded, size: 18),
                      SizedBox(width: 4),
                      Text('歌曲'),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.queue_music_rounded, size: 18),
                      SizedBox(width: 4),
                      Text('歌单'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── 搜索栏 (图标左 / 叉号右 / 排序按钮右外侧) ──────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _searchFocus,
                      onSubmitted: (_) => _onSearch(),
                      style: tt.bodyLarge,
                      decoration: InputDecoration(
                        hintText: isFirstTab ? '搜索歌曲、歌手...' : '搜索歌单名称...',
                        hintStyle: tt.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: cs.onSurfaceVariant,
                          size: 20,
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        suffixIcon: hasText
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                                onPressed: _onClear,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              )
                            : const SizedBox(width: 40),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        filled: true,
                        fillColor: cs.surfaceContainerHigh,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: cs.primary, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // 排序按钮（移到搜索框外面）
                IconButton(
                  icon: Icon(
                    Icons.sort_rounded,
                    size: 22,
                    color: cs.onSurfaceVariant,
                  ),
                  onPressed: () => _showSortSheet(context),
                  tooltip: '排序',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── 内容区 ─────────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _SongSearchTab(
                  searchCtrl: _searchCtrl,
                  hasSearched: _hasSearched[0] ?? false,
                ),
                _PlaylistSearchTab(
                  searchCtrl: _searchCtrl,
                  hasSearched: _hasSearched[1] ?? false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortSheet(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '搜索结果排序',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.sort_by_alpha_rounded,
                  color: cs.primary,
                  size: 22,
                ),
                title: const Text('按名称排序'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: Icon(
                  Icons.person_outline_rounded,
                  color: cs.secondary,
                  size: 22,
                ),
                title: const Text('按歌手排序'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: Icon(
                  Icons.auto_awesome_rounded,
                  color: cs.tertiary,
                  size: 22,
                ),
                title: const Text('默认排序'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  推荐标签 Chip
// ═══════════════════════════════════════════════════════════════

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  空态页
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '推荐搜索',
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: Divider(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
  final TextEditingController searchCtrl;
  final bool hasSearched;

  const _SongSearchTab({required this.searchCtrl, required this.hasSearched});

  @override
  State<_SongSearchTab> createState() => _SongSearchTabState();
}

class _SongSearchTabState extends State<_SongSearchTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<NeteaseSong> _results = [];
  bool _isSearching = false;
  bool _isFiltering = false;
  String? _statusMsg;
  String _lastQueried = '';

  static const _tags = [
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
  void didUpdateWidget(covariant _SongSearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 父级清除搜索时，重置子状态
    if (oldWidget.hasSearched && !widget.hasSearched) {
      setState(() {
        _lastQueried = '';
        _results = [];
        _isSearching = false;
        _isFiltering = false;
        _statusMsg = null;
      });
      return;
    }
    // 仅在 hasSearched 从 false → true 时触发搜索（回车键场景）
    if (!oldWidget.hasSearched && widget.hasSearched) {
      final q = widget.searchCtrl.text.trim();
      if (q.isNotEmpty && !_isSearching) {
        _lastQueried = q;
        _doSearch(q);
      }
    }
  }

  Future<void> _doSearch(String q) async {
    setState(() {
      _isSearching = true;
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

  Future<void> _play(NeteaseSong song) async {
    try {
      final mp = context.read<MusicProvider>();
      final idx = _results.indexOf(song);
      if (idx < 0) return;
      final songMaps = _results
          .map(
            (s) => <String, String?>{
              'id': s.id,
              'title': s.title,
              'artist': s.author,
              'url': s.url,
              'coverUrl': s.pic,
              'lyrics': mp.getCachedLyrics('net_${s.id}'),
            },
          )
          .toList();
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
      final safeTitle = song.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final safeArtist = song.author
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final songDir = Directory(
        p.join(m3MusicDir.path, '$safeTitle - $safeArtist'),
      );
      if (!await songDir.exists()) await songDir.create(recursive: true);
      String ext = p.url.extension(song.url);
      if (ext.contains('?')) ext = ext.split('?').first;
      if (ext.isEmpty || ext.length > 5) ext = '.mp3';
      final audioPath = p.join(songDir.path, '$safeTitle - $safeArtist$ext');
      final audioResult = await NeteaseApi.downloadSong(song.url, audioPath);
      String? lrcPath;
      try {
        final lyricMap = await NeteaseApi.getLyric(song.id);
        final lc = lyricMap['lyric'];
        if (lc != null && lc.isNotEmpty) {
          lrcPath = p.join(songDir.path, '$safeTitle - $safeArtist.lrc');
          await File(lrcPath).writeAsString(lc);
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
          'id': song.id,
          'title': song.title,
          'author': song.author,
          'source': song.source,
          if (audioResult != null) 'audio_path': audioResult,
          if (lrcPath != null) 'lyric_path': lrcPath,
          if (coverPath != null) 'cover_path': coverPath,
        };
        await File(
          p.join(songDir.path, 'metadata.json'),
        ).writeAsString(const JsonEncoder.withIndent('  ').convert(meta));
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
        ? currentMusic!.id.substring(4)
        : null;
    final isLoading = _isSearching || _isFiltering;

    final showEmpty =
        _lastQueried.isEmpty && _results.isEmpty && !_isSearching;

    if (showEmpty) {
      return _EmptyState(
        icon: Icons.cloud_queue_rounded,
        title: '在线歌曲搜索',
        subtitle: '搜索网易云音乐，在线收听或下载',
        tags: _tags,
        onTagTap: (t) {
          widget.searchCtrl.text = t;
          _lastQueried = t;
          _doSearch(t);
        },
      );
    }

    if (isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: cs.primary),
            const SizedBox(height: 16),
            Text(
              _statusMsg ?? '',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (_isFiltering) ...[
              const SizedBox(height: 6),
              Text(
                '正在验证可播放链接...',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.errorContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cloud_off_rounded, size: 36, color: cs.error),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMsg ?? '未找到可播放的歌曲',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _doSearch(widget.searchCtrl.text.trim()),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('重新搜索'),
            ),
          ],
        ),
      );
    }

    final entries = _results
        .map(
          (s) => M3SongEntry(
            id: 'net_${s.id}',
            title: s.title,
            subtitle: '${s.author}  ·  ${s.source.toUpperCase()}',
            coverUrl: s.pic,
            coverHeaders: const {'Referer': 'https://music.163.com/'},
            fallbackIcon: Icons.music_note_rounded,
            isHighlighted: currentNetId == s.id,
            trailing: PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              onSelected: (v) {
                if (v == 'play') {
                  _play(s);
                } else if (v == 'detail')
                  // ignore: curly_braces_in_flow_control_structures
                  _openDetail(s);
                else if (v == 'download')
                  // ignore: curly_braces_in_flow_control_structures
                  _download(s);
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
          ),
        )
        .toList();

    return Column(
      children: [
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.4)),
        Expanded(child: M3SongList(songs: entries, isScrollable: true)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Tab 2 — 歌单搜索
// ═══════════════════════════════════════════════════════════════

class _PlaylistSearchTab extends StatefulWidget {
  final TextEditingController searchCtrl;
  final bool hasSearched;

  const _PlaylistSearchTab({
    required this.searchCtrl,
    required this.hasSearched,
  });

  @override
  State<_PlaylistSearchTab> createState() => _PlaylistSearchTabState();
}

class _PlaylistSearchTabState extends State<_PlaylistSearchTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<NeteasePlaylistItem> _playlists = [];
  bool _isSearching = false;
  String? _statusMsg;
  String _lastQueried = '';

  NeteasePlaylistItem? _openedPlaylist;
  NeteasePlaylistDetail? _detail;
  bool _isLoadingDetail = false;
  String? _detailError;

  static const _tags = [
    '初音ミク',
    'VOCALOID',
    'J-POP',
    '电波曲',
    '术力口',
    'lo-fi',
    '纯音乐',
    '学习',
    '治愈',
  ];

  @override
  void didUpdateWidget(covariant _PlaylistSearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 父级清除搜索时，重置子状态
    if (oldWidget.hasSearched && !widget.hasSearched) {
      setState(() {
        _lastQueried = '';
        _playlists = [];
        _isSearching = false;
        _statusMsg = null;
      });
      return;
    }
    // 仅在 hasSearched 从 false → true 时触发搜索（回车键场景）
    if (!oldWidget.hasSearched && widget.hasSearched) {
      final q = widget.searchCtrl.text.trim();
      if (q.isNotEmpty && !_isSearching) {
        _lastQueried = q;
        _doSearch(q);
      }
    }
  }

  Future<void> _doSearch(String q) async {
    setState(() {
      _isSearching = true;
      _statusMsg = '正在搜索歌单...';
      _playlists = [];
      _openedPlaylist = null;
      _detail = null;
    });
    try {
      final list = await NeteaseApi.searchPlaylists(q);
      if (!mounted) return;
      setState(() {
        _playlists = list;
        _isSearching = false;
        _statusMsg = list.isEmpty ? '未找到相关歌单' : '找到 ${list.length} 个歌单';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _statusMsg = '搜索失败: $e';
      });
    }
  }

  Future<void> _openPlaylist(NeteasePlaylistItem item) async {
    if (_openedPlaylist?.id == item.id && _detail != null) {
      setState(() {
        _openedPlaylist = null;
        _detail = null;
      });
      return;
    }
    setState(() {
      _openedPlaylist = item;
      _detail = null;
      _isLoadingDetail = true;
      _detailError = null;
    });
    try {
      final d = await NeteaseApi.getPlaylistDetail(item.id);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _isLoadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDetail = false;
        _detailError = '加载失败: $e';
      });
    }
  }

  Future<void> _playPlaylistFrom(int startIndex) async {
    final songs = _detail?.songs;
    if (songs == null || songs.isEmpty) return;
    try {
      final mp = context.read<MusicProvider>();
      final songMaps = songs
          .map(
            (s) => <String, String?>{
              'id': s.id,
              'title': s.title,
              'artist': s.author,
              'url': '',
              'coverUrl': s.pic,
              'lyrics': mp.getCachedLyrics('net_${s.id}'),
            },
          )
          .toList();
      await mp.playNetworkSearchResults(
        songs: songMaps,
        startIndex: startIndex,
      );
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

  Future<void> _downloadPlaylistSong(NeteasePlaylistSong song) async {
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
      if (!mounted) return;
      if (audioResult != null) {
        AppToast.success(context, message: '已保存到: $audioPath', title: '下载完成');
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

    final showEmpty =
        _lastQueried.isEmpty && _playlists.isEmpty && !_isSearching;

    if (showEmpty) {
      return _EmptyState(
        icon: Icons.queue_music_rounded,
        iconColor: cs.secondary,
        title: '在线歌单搜索',
        subtitle: '搜索网易云歌单，一键播放整个歌单',
        tags: _tags,
        onTagTap: (t) {
          widget.searchCtrl.text = t;
          _lastQueried = t;
          _doSearch(t);
        },
      );
    }

    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: cs.secondary),
            const SizedBox(height: 16),
            Text(
              _statusMsg ?? '',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (_playlists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.playlist_remove_rounded,
                size: 36,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _statusMsg ?? '未找到相关歌单',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: () => _doSearch(widget.searchCtrl.text.trim()),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('重新搜索'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
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
                  onPlaySong: (song) =>
                      _playPlaylistFrom(_detail!.songs.indexOf(song)),
                  onOpenDetail: _openDetailPage,
                  onDownload: _downloadPlaylistSong,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  歌单卡片（可展开）
// ═══════════════════════════════════════════════════════════════

class _PlaylistCard extends StatelessWidget {
  final NeteasePlaylistItem item;
  final bool isOpen;
  final bool isLoadingDetail;
  final NeteasePlaylistDetail? detail;
  final String? detailError;
  final dynamic currentMusic;
  final VoidCallback onTap;
  final void Function(NeteasePlaylistSong) onPlaySong;
  final void Function(NeteasePlaylistSong) onOpenDetail;
  final void Function(NeteasePlaylistSong)? onDownload;

  const _PlaylistCard({
    required this.item,
    required this.isOpen,
    required this.isLoadingDetail,
    required this.detail,
    required this.detailError,
    required this.currentMusic,
    required this.onTap,
    required this.onPlaySong,
    required this.onOpenDetail,
    this.onDownload,
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
      color: isOpen
          ? cs.primaryContainer.withValues(alpha: 0.08)
          : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _PlaylistCover(pic: item.pic, size: 60),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                item.creator,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
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
                          ],
                        ),
                      ],
                    ),
                  ),
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
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: isOpen
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Divider(
                        height: 1,
                        color: cs.outlineVariant.withValues(alpha: 0.3),
                      ),
                      if (isLoadingDetail)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '加载歌单中...',
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (detailError != null)
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: cs.error,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  detailError!,
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (detail != null)
                        _PlaylistDetailPanel(
                          detail: detail!,
                          currentMusic: currentMusic,
                          onPlaySong: onPlaySong,
                          onOpenDetail: onOpenDetail,
                          onDownload: onDownload,
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
        width: size,
        height: size,
        child: pic.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: pic,
                fit: BoxFit.cover,
                httpHeaders: const {
                  'Referer': 'https://music.163.com/',
                  'User-Agent': 'Mozilla/5.0',
                },
                placeholder: (_, __) =>
                    Container(color: cs.surfaceContainerHighest),
                errorWidget: (_, __, ___) => Icon(
                  Icons.queue_music_rounded,
                  size: size * 0.4,
                  color: cs.onSurfaceVariant,
                ),
              )
            : Container(
                color: cs.surfaceContainerHighest,
                child: Icon(
                  Icons.queue_music_rounded,
                  size: size * 0.4,
                  color: cs.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistDetailPanel extends StatefulWidget {
  final NeteasePlaylistDetail detail;
  final dynamic currentMusic;
  final void Function(NeteasePlaylistSong) onPlaySong;
  final void Function(NeteasePlaylistSong) onOpenDetail;
  final void Function(NeteasePlaylistSong)? onDownload;

  const _PlaylistDetailPanel({
    required this.detail,
    required this.currentMusic,
    required this.onPlaySong,
    required this.onOpenDetail,
    this.onDownload,
  });

  @override
  State<_PlaylistDetailPanel> createState() => _PlaylistDetailPanelState();
}

class _PlaylistDetailPanelState extends State<_PlaylistDetailPanel> {
  int _visibleCount = 50;

  @override
  void didUpdateWidget(covariant _PlaylistDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _visibleCount = 50;
    }
  }

  String? _currentNetId(Music? currentMusic) {
    if (currentMusic == null) return null;
    return currentMusic.id.startsWith('net_')
        ? currentMusic.id.substring(4)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final songs = widget.detail.songs;
    final currentNetId = _currentNetId(
      widget.currentMusic is Music ? widget.currentMusic : null,
    );

    final visibleSongs = songs.take(_visibleCount).toList();
    final hasMore = _visibleCount < songs.length;
    final nextBatch = (_visibleCount + 50).clamp(0, songs.length);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            Text(
              '${songs.length} 首歌曲',
              style: tt.labelLarge?.copyWith(color: cs.primary),
            ),
            const Spacer(),
            FilledButton.tonalIcon(
              onPressed: () => widget.onPlaySong(songs.first),
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('播放全部'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ]),
        ),
        ...visibleSongs.map((song) {
          final isCurrent = currentNetId == song.id.toString();
          final entries = M3SongEntry(
            id: 'net_${song.id}',
            title: song.title,
            subtitle: '${song.author}  ·  ${song.source.toUpperCase()}',
            coverUrl: song.pic,
            coverHeaders: const {'Referer': 'https://music.163.com/'},
            fallbackIcon: Icons.music_note_rounded,
            isHighlighted: isCurrent,
            trailing: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  size: 18, color: cs.onSurfaceVariant),
              onSelected: (v) {
                if (v == 'play') {
                  widget.onPlaySong(song);
                } else if (v == 'detail') {
                  widget.onOpenDetail(song);
                }
                else if (v == 'download' && widget.onDownload != null) {
                  widget.onDownload!(song);
                }

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
            onTap: () => widget.onOpenDetail(song),
          );
          return M3SongList(songs: [entries], isScrollable: false);
        }),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextButton.icon(
              onPressed: () => setState(() => _visibleCount = nextBatch),
              icon: Icon(Icons.expand_more_rounded,
                  size: 18, color: cs.primary),
              label: Text(
                '加载更多 ($_visibleCount/$nextBatch)',
                style: tt.labelMedium?.copyWith(color: cs.primary),
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}
