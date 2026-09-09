import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

enum SortOption { title, artist, dateAdded }

class DownloadManagementPage extends StatefulWidget {
  const DownloadManagementPage({super.key});

  @override
  State<DownloadManagementPage> createState() => _DownloadManagementPageState();
}

class _DownloadManagementPageState extends State<DownloadManagementPage> {
  bool _isScanning = false;
  List<Music> _songs = [];
  StreamSubscription? _scanSubscription;

  // 搜索与排序控制状态
  bool _showSearch = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateAdded;
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanDownloads();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _scanDownloads() async {
    _scanSubscription?.cancel();

    final m3MusicDir = await FileService.getM3MusicDir();
    if (!await m3MusicDir.exists()) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _songs = [];
        });
        context.read<MusicProvider>().setDownloadedSongs([]);
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _songs = [];
    });

    _scanSubscription = MusicService.scanDirectories([m3MusicDir.path]).listen(
      (progress) {
        if (!mounted) return;
        if (progress.music != null) {
          _songs.add(progress.music!);
          setState(() {});
        }
      },
      onDone: () async {
        if (!mounted) return;
        await _loadCovers();
        if (!mounted) return;

        setState(() => _isScanning = false);
        context.read<MusicProvider>().setDownloadedSongs(_songs);
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _isScanning = false);
      },
    );
  }

  Future<void> _loadCovers() async {
    final updatedSongs = await Future.wait(
      _songs.map((song) async {
        if (song.coverBytes != null && song.coverBytes!.isNotEmpty) {
          return song;
        }
        try {
          final parentDir = p.dirname(song.id);
          final coverFile = File(p.join(parentDir, 'cover.jpg'));
          if (await coverFile.exists()) {
            final bytes = await coverFile.readAsBytes();
            if (bytes.isNotEmpty) {
              return song.copyWith(coverBytes: bytes);
            }
          }
        } catch (_) {}
        return song;
      }),
    );

    if (!mounted) return;
    setState(() {
      _songs = updatedSongs;
    });
  }

  /// 计算经过过滤与排序后的歌曲列表
  List<Music> get _processedSongs {
    List<Music> list = List.from(_songs);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        final title = s.title.toLowerCase();
        final artist = (s.artist).toLowerCase();
        return title.contains(q) || artist.contains(q);
      }).toList();
    }

    list.sort((a, b) {
      int cmp = 0;
      switch (_sortOption) {
        case SortOption.title:
          cmp = a.title.compareTo(b.title);
          break;
        case SortOption.artist:
          cmp = (a.artist).compareTo(b.artist);
          break;
        case SortOption.dateAdded:
          // id 为文件路径，使用文件修改时间排序
          final aTime = File(a.id).lastModifiedSync();
          final bTime = File(b.id).lastModifiedSync();
          cmp = aTime.compareTo(bTime);
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final musicProvider = context.watch<MusicProvider>();
    final currentMusic = musicProvider.currentMusic;

    return Scaffold(
      appBar: AppBar(
        title: const Text("下载管理"),
        actionsPadding: const EdgeInsets.only(right: 12),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                key: ValueKey(_showSearch),
                size: 22,
              ),
            ),
            tooltip: _showSearch ? '关闭搜索' : '搜索与排序',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: _buildBody(colorScheme, textTheme, musicProvider, currentMusic),
    );
  }

  Widget _buildBody(
    ColorScheme colorScheme,
    TextTheme textTheme,
    MusicProvider musicProvider,
    Music? currentMusic,
  ) {
    if (_isScanning && _songs.isEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (!_isScanning && _songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download_for_offline_rounded,
              size: 64,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              "还没有下载的歌曲",
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "在网络歌曲页面搜索并下载歌曲后，\n下载的歌曲会显示在这里",
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: _scanDownloads,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("重新扫描"),
            ),
          ],
        ),
      );
    }

    final displaySongs = _processedSongs;

    final entries = displaySongs.map((song) {
      final isCurrent = currentMusic?.id == song.id;
      final isPlaying = isCurrent && musicProvider.player.playing;

      return M3SongEntry(
        id: song.id,
        title: song.title,
        subtitle: song.artist,
        coverBytes: song.coverBytes,
        isHighlighted: isCurrent,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isCurrent && isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 22,
                color: colorScheme.primary,
              ),
              tooltip: isCurrent && isPlaying ? '暂停' : '播放',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              padding: EdgeInsets.zero,
              onPressed: () {
                if (!isCurrent) {
                  musicProvider.playFromLibrary(song);
                } else {
                  musicProvider.togglePlay();
                }
              },
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              onSelected: (v) {
                switch (v) {
                  case 'add_to_playlist':
                    MusicActionMenu.showAddToPlaylistSheet(context, song);
                    break;
                  case 'toggle_favorite':
                    _toggleFavorite(song);
                    break;
                  case 'delete':
                    _deleteSong(song);
                    break;
                }
              },
              itemBuilder: (ctx) {
                final isFav = _isFavorited(ctx, song);
                return [
                  const PopupMenuItem(
                    value: 'add_to_playlist',
                    child: ListTile(
                      leading: Icon(Icons.playlist_add_rounded),
                      title: Text('添加到歌单'),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_favorite',
                    child: ListTile(
                      leading: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav ? colorScheme.primary : null,
                      ),
                      title: Text(isFav ? '取消收藏' : '添加到收藏'),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                      ),
                      title: Text('删除文件'),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        onTap: () {
          musicProvider.playFromLibrary(song);
          Navigator.of(context).pushNamed('/music-detail');
        },
      );
    }).toList();

    return RefreshIndicator(
      onRefresh: _scanDownloads,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 可展开的搜索与排序控制栏 — 参照 NetworkSongPage 的 _SearchBar
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: _showSearch
                ? Container(
                    color: colorScheme.surface,
                    padding: const EdgeInsets.fromLTRB(16, 6, 12, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: TextField(
                              controller: _searchController,
                              style: textTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: "搜索已下载歌曲...",
                                hintStyle: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                prefixIconConstraints:
                                    const BoxConstraints(minWidth: 42),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.close_rounded,
                                          size: 18,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                        visualDensity: VisualDensity.compact,
                                      )
                                    : null,
                                filled: true,
                                fillColor: colorScheme.surfaceContainerHigh,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: colorScheme.primary,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              onChanged: (val) {
                                setState(() => _searchQuery = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        // 排序按钮：与 NetworkSongPage 一致，并与下方 more 按钮对齐
                        IconButton(
                          icon: const Icon(Icons.sort_rounded, size: 22),
                          tooltip: '排序',
                          onPressed: () => _showSortSheet(context),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // 数量与信息展示
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.download_done_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _searchQuery.isNotEmpty
                      ? "匹配到 ${displaySongs.length} / ${_songs.length} 首歌曲"
                      : "已下载 ${_songs.length} 首歌曲",
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: displaySongs.isEmpty
                ? Center(
                    child: Text(
                      "未匹配到相关歌曲",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : M3SongList(
                    songs: entries,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    isScrollable: true,
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
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '排序方式',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
              _SortOptionTile(
                icon: Icons.access_time_rounded,
                color: cs.primary,
                label: '下载时间',
                isSelected: _sortOption == SortOption.dateAdded,
                ascending: _sortAscending,
                onTap: () {
                  setState(() {
                    if (_sortOption == SortOption.dateAdded) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = SortOption.dateAdded;
                      _sortAscending = true;
                    }
                  });
                  Navigator.pop(ctx);
                },
              ),
              _SortOptionTile(
                icon: Icons.sort_by_alpha_rounded,
                color: cs.secondary,
                label: '歌曲名称',
                isSelected: _sortOption == SortOption.title,
                ascending: _sortAscending,
                onTap: () {
                  setState(() {
                    if (_sortOption == SortOption.title) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = SortOption.title;
                      _sortAscending = true;
                    }
                  });
                  Navigator.pop(ctx);
                },
              ),
              _SortOptionTile(
                icon: Icons.person_outline_rounded,
                color: cs.tertiary,
                label: '歌手',
                isSelected: _sortOption == SortOption.artist,
                ascending: _sortAscending,
                onTap: () {
                  setState(() {
                    if (_sortOption == SortOption.artist) {
                      _sortAscending = !_sortAscending;
                    } else {
                      _sortOption = SortOption.artist;
                      _sortAscending = true;
                    }
                  });
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isFavorited(BuildContext ctx, Music song) {
    final playlistProvider = ctx.read<PlaylistProvider>();
    final musicProvider = ctx.read<MusicProvider>();
    return playlistProvider
        .getPlaylistSongs(
          PlaylistProvider.favoritesPlaylistId,
          musicProvider.library,
          musicProvider: musicProvider,
        )
        .any((m) => m.id == song.id);
  }

  Future<void> _toggleFavorite(Music song) async {
    final musicProvider = context.read<MusicProvider>();
    final playlistProvider = context.read<PlaylistProvider>();

    final wasFav = playlistProvider
        .getPlaylistSongs(
          PlaylistProvider.favoritesPlaylistId,
          musicProvider.library,
          musicProvider: musicProvider,
        )
        .any((m) => m.id == song.id);

    await playlistProvider.toggleMusicFavorite(
      song,
      musicProvider: musicProvider,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasFav ? '已取消收藏「${song.title}」' : '已收藏「${song.title}」'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _deleteSong(Music song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("确认删除"),
        content: Text("确定要删除「${song.title}」吗？\n此操作将同时删除文件，不可撤销。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("取消"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("删除"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final musicProvider = context.read<MusicProvider>();

      if (musicProvider.currentMusic?.id == song.id) {
        await musicProvider.player.stop();
      }

      final file = File(song.id);
      final parentDir = file.parent;
      final dirName = p.basename(parentDir.path);

      if (parentDir.path.contains('M3Music') &&
          dirName.contains(' - ') &&
          await parentDir.exists()) {
        await parentDir.delete(recursive: true);
      } else if (await file.exists()) {
        await file.delete();
      }

      setState(() {
        _songs.removeWhere((s) => s.id == song.id);
      });

      musicProvider.removeFromDownloadedLibrary(song.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("已删除「${song.title}」")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("删除失败: $e")));
      }
    }
  }
}

// 排序选项（与 NetworkSongPage 的 _SortOption 风格一致）
class _SortOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final bool isSelected;
  final bool ascending;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.isSelected,
    required this.ascending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? cs.primary : null,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      trailing: isSelected
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  ascending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 16,
                  color: cs.primary,
                ),
                const SizedBox(width: 4),
                Icon(Icons.check_rounded, color: cs.primary, size: 20),
              ],
            )
          : null,
      onTap: onTap,
    );
  }
}
