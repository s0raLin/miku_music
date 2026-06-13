import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/M3SongList.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class DownloadManagementPage extends StatefulWidget {
  const DownloadManagementPage({super.key});

  @override
  State<DownloadManagementPage> createState() => _DownloadManagementPageState();
}

class _DownloadManagementPageState extends State<DownloadManagementPage> {
  bool _isScanning = false;
  List<Music> _songs = [];
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _scanDownloads();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  Future<void> _scanDownloads() async {
    _scanSubscription?.cancel();

    final m3MusicDir = await FileService.getM3MusicDir();
    if (!await m3MusicDir.exists()) {
      setState(() => _isScanning = false);
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
        // Load cover images eagerly from cover.jpg in each song's folder
        await _loadCovers();
        if (!mounted) return;
        setState(() => _isScanning = false);
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _isScanning = false);
      },
    );
  }

  /// Load cover.jpg from each song's parent folder and attach to song.coverBytes
  Future<void> _loadCovers() async {
    for (int i = 0; i < _songs.length; i++) {
      final song = _songs[i];
      // Only load if no cover bytes yet
      if (song.coverBytes != null && song.coverBytes!.isNotEmpty) continue;

      try {
        final parentDir = p.dirname(song.id);
        final coverFile = File(p.join(parentDir, 'cover.jpg'));
        if (await coverFile.exists()) {
          final bytes = await coverFile.readAsBytes();
          if (bytes.isNotEmpty) {
            _songs[i] = song.copyWith(coverBytes: bytes);
          }
        }
      } catch (_) {
        // ignore per-file errors
      }
    }
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
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            tooltip: '刷新',
            onPressed: _isScanning ? null : _scanDownloads,
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
            Icon(Icons.download_for_offline_rounded,
                size: 64, color: colorScheme.outlineVariant),
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

    final entries = _songs.map((song) {
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
                color: colorScheme.primary,
              ),
              tooltip: isCurrent && isPlaying ? '暂停' : '播放',
              onPressed: () {
                if (!isCurrent) {
                  musicProvider.playFromLibrary(song);
                } else {
                  musicProvider.togglePlay();
                }
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (v) {
                switch (v) {
                  case 'delete':
                    _deleteSong(song);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    title: Text('删除文件'),
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
            child: Row(
              children: [
                Icon(Icons.download_done_rounded,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "已下载 ${_songs.length} 首歌曲",
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: M3SongList(
              songs: entries,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              isScrollable: true,
            ),
          ),
        ],
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
      // Delete the song file (song.id is the full path for local files)
      final file = File(song.id);
      if (await file.exists()) {
        await file.delete();
      }

      // Also try to delete the parent folder if it was a M3Music download folder
      final parentDir = file.parent;
      final dirName = p.basename(parentDir.path);
      // Only delete the M3Music subfolder if it matches the download pattern
      if (parentDir.path.contains('M3Music') &&
          dirName.contains(' - ') &&
          await parentDir.exists()) {
        await parentDir.delete(recursive: true);
      }

      // Remove from list and re-scan
      setState(() {
        _songs.removeWhere((s) => s.id == song.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("已删除「${song.title}」")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("删除失败: $e")),
        );
      }
    }
  }
}
