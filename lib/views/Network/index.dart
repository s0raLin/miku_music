import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Netease/index.dart';
import 'package:myapp/api/Model/NeteaseSong/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;

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
  void initState() {
    super.initState();
    // 监听输入框变化，以便实时刷新清除按钮的显示状态
    _searchController.addListener(() => setState(() {}));
  }

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

    _focusNode.unfocus(); // 搜索时自动收起键盘

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

      // Get M3Music directory under Downloads
      final m3MusicDir = await FileService.getM3MusicDir();
      if (!await m3MusicDir.exists()) {
        await m3MusicDir.create(recursive: true);
      }

      // Create song-specific folder: M3Music/歌曲名 - 歌手名/
      final safeTitle = song.title
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final safeArtist = song.author
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();
      final songFolderName = '$safeTitle - $safeArtist';
      final songDir = Directory(p.join(m3MusicDir.path, songFolderName));
      if (!await songDir.exists()) {
        await songDir.create(recursive: true);
      }

      String ext = p.url.extension(song.url);

      // 如果 URL 里没有带后缀（比如某些流媒体链接），或者带了超长参数，做个清洗和兜底
      if (ext.contains('?')) {
        ext = ext.split('?').first;
      }
      if (ext.isEmpty || ext.length > 5) {
        ext = '.mp3'; // 兜底格式
      }

      // Download audio file
      final audioPath = p.join(songDir.path, '$safeTitle - $safeArtist$ext');
      final audioResult = await NeteaseApi.downloadSong(song.url, audioPath);

      // Download lyrics
      String? lrcPath;
      try {
        final lyricMap = await NeteaseApi.getLyric(song.id);
        final lyricContent = lyricMap['lyric'];
        if (lyricContent != null && lyricContent.isNotEmpty) {
          lrcPath = p.join(songDir.path, '$safeTitle - $safeArtist.lrc');
          final lrcFile = File(lrcPath);
          await lrcFile.writeAsString(lyricContent);
        }
      } catch (e) {
        debugPrint('下载歌词失败: $e');
      }

      // Download cover image
      String? coverPath;
      try {
        if (song.pic.isNotEmpty) {
          coverPath = p.join(songDir.path, 'cover.jpg');
          await NeteaseApi.downloadCover(song.pic, coverPath);
        }
      } catch (e) {
        debugPrint('下载封面失败: $e');
      }

      if (!mounted) return;
      if (audioResult != null) {
        final msgBuf = StringBuffer('已保存到: $audioPath');
        if (lrcPath != null) msgBuf.write('\n歌词: $lrcPath');
        if (coverPath != null) msgBuf.write('\n封面: $coverPath');
        AppToast.success(context, message: msgBuf.toString(), title: '下载完成');
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

    final entries = _results
        .map(
          (s) => M3SongEntry(
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
                  case 'play':
                    _play(s);
                  case 'detail':
                    _openDetail(s);
                  case 'download':
                    _download(s);
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
                PopupMenuItem(
                  value: 'download',
                  child: ListTile(
                    leading: Icon(Icons.download_rounded),
                    title: Text('下载到本地'),
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

    final isLoading = _isSearching || _isFiltering;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 优化 1：精简现代的顶部搜索栏区域
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: SearchBar(
                controller: _searchController,
                focusNode: _focusNode,
                hintText: '搜索网易云音乐...',
                leading: Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                trailing: [
                  // 清除按钮
                  if (_searchController.text.trim().isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _results = [];
                          _hasSearched = false;
                          _statusMsg = null;
                        });
                      },
                    ),
                  // 将发送/加载按钮内嵌到 SearchBar 内部，视觉更一体化
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: IconButton(
                      onPressed: isLoading ? null : _search,
                      icon: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.primary,
                              ),
                            )
                          : Icon(Icons.send_rounded, color: cs.primary),
                    ),
                  ),
                ],
                onSubmitted: (_) => _search(),
                elevation: WidgetStateProperty.all(0.0),
                backgroundColor: WidgetStateProperty.all(
                  cs.surfaceContainerHigh,
                ),
                // 采用完美的胶囊形状
                shape: WidgetStateProperty.all(const StadiumBorder()),
                constraints: const BoxConstraints(minHeight: 56.0),
              ),
            ),

            // Content
            Expanded(child: _buildContent(cs, tt, entries)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    ColorScheme cs,
    TextTheme tt,
    List<M3SongEntry> entries,
  ) {
    if (!_hasSearched) return _buildSuggestions(cs, tt);

    if (_isSearching || _isFiltering) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _statusMsg ?? '',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (_isFiltering) ...[
              const SizedBox(height: 8),
              Text(
                '检测歌曲链接可用性...',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: cs.outlineVariant),
            const SizedBox(height: 16),
            Text(
              _statusMsg ?? '未找到可播放的歌曲',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: _search,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重新搜索'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 优化 2：优化状态栏指示器的外间距与高度
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
          child: Row(
            children: [
              Icon(Icons.cloud_done_rounded, size: 14, color: cs.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _statusMsg ?? '',
                  style: tt.labelMedium?.copyWith(color: cs.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _search,
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text('重新搜索'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: tt.labelMedium,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 优化 3：移除外层多余 Padding，将边距留给可滚动的组件内部或微调横向间距
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            // 提示：如果 M3SongList 内部支持传入 padding，建议将横向 padding (如 12) 传给其内部的 ListView。
            // 这里我们仅保留极小的外边距，防止内容贴边，同时保证了滚动的整体性。
            child: M3SongList(songs: entries, isScrollable: true),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestions(ColorScheme cs, TextTheme tt) {
    return ListView(
      // 优化 4：微调主页推荐页面的 padding，使其上下呼吸感更强
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        Center(
          child: Column(
            children: [
              // 使用次级容器颜色作为背景，做成圆角图标显得更精致
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_queue_rounded,
                  size: 48,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '在线音乐搜索',
                style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '搜索网易云音乐，在线收听或下载',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Text(
          '搜索推荐',
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: cs.primary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        // 优化 5：精致的 FilterChip 推荐标签样式
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: _suggestedTags
              .map(
                (t) => ChoiceChip(
                  selected: false, // 纯作点击推荐使用
                  label: Text(t),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                  backgroundColor: cs.surfaceContainerLow,
                  side: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                  // 更现代的 M3 圆角控制 (全圆角或高圆角)
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  // 移除 Chip 默认过大的内部补白
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) {
                    _searchController.text = t;
                    _search();
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
