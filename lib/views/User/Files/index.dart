import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  List<String> _paths = [];
  bool _isPathsLoading = true; // 解决首次进入页面闪烁空状态的问题
  bool _isScanning = false;
  List<Music> _scannedSongs = [];
  StreamSubscription? _scanSubscription;

  // 缓存分组数据，避免每次 build 都重新执行 for 循环
  Map<String, List<Music>> _folderGroups = {};
  Map<String, List<Music>> _albumGroups = {};
  Map<String, List<Music>> _artistGroups = {};

  @override
  void initState() {
    super.initState();
    _initPaths();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _initPaths() async {
    final loadedPaths = await FileService.loadPaths();
    if (mounted) {
      setState(() {
        _paths = loadedPaths;
        _isPathsLoading = false;
      });
    }
  }

  // ==========================================
  // 核心业务逻辑
  // ==========================================

  void _startScan(List<String> paths) {
    _scanSubscription?.cancel();
    setState(() {
      _isScanning = true;
      _scannedSongs = [];
    });

    final musicProvider = context.read<MusicProvider>();

    _scanSubscription = MusicService.scanDirectories(paths).listen(
      (progress) {
        if (!mounted) return;
        if (progress.music != null) {
          _scannedSongs.add(progress.music!);
          // 每积累15首增量刷新一次全局 Library
          if (_scannedSongs.length % 15 == 0) {
            musicProvider.updateLibrary(List.from(_scannedSongs));
          }
        }
      },
      onDone: () {
        if (!mounted) return;
        musicProvider.updateLibrary(List.from(_scannedSongs));
        setState(() => _isScanning = false);

        if (_scannedSongs.isNotEmpty) {
          AppToast.success(
            context,
            message: '扫描完成，共 ${_scannedSongs.length} 首歌曲',
          );
        } else {
          AppToast.neutral(context, message: '未发现音频文件');
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _isScanning = false);
        AppToast.error(context, message: '扫描出错: $err', title: '扫描失败');
      },
    );
  }

  Future<void> _showPickDialog() async {
    // 将 Dialog 逻辑内部化，避免外部 state 过于臃肿
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _FolderPickDialog(initialPaths: _paths),
    );

    if (result == null || !mounted) return;

    // 权限校验
    if (Platform.isAndroid &&
        !(await MusicService.ensureAndroidAudioPermission())) {
      if (mounted) {
        AppToast.error(context, message: '请授予存储和音频权限以扫描音乐', title: '权限不足');
      }
      return;
    }

    await FileService.savePaths(result);
    setState(() => _paths = result);
    _startScan(result);
  }

  // ==========================================
  // 数据分组算法（引入缓存机制）
  // ==========================================

  void _updateGroupsIfNeeded(List<Music> currentSongs) {

    final folders = <String, List<Music>>{};
    final albums = <String, List<Music>>{};
    final artists = <String, List<Music>>{};

    for (final song in currentSongs) {
      folders.putIfAbsent(p.dirname(song.id), () => []).add(song);

      final albumName = song.album?.trim();
      final albumKey = (albumName != null && albumName.isNotEmpty)
          ? albumName
          : '未知专辑';
      albums.putIfAbsent(albumKey, () => []).add(song);

      artists.putIfAbsent(song.artist, () => []).add(song);
    }

    _folderGroups = folders;
    _albumGroups = albums;
    _artistGroups = artists;
  }

  // ==========================================
  // UI 构建核心方法
  // ==========================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 粒度化监听库文件
    final songs = context.select<MusicProvider, List<Music>>((p) => p.library);

    // 在 build 触发时安全地按需更新分组（O(N) 一次性搞定，而不是三次）
    _updateGroupsIfNeeded(songs);

    if (_isPathsLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              title: const Text("文件"),
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: "文件夹"),
                  Tab(text: "专辑"),
                  Tab(text: "艺术家"),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    tooltip: "选择目录",
                    onPressed: _showPickDialog,
                    icon: const Icon(Icons.folder_open_rounded),
                  ),
                ),
              ],
            ),
          ],
          body: TabBarView(
            children: [
              _buildTabContent(
                groups: _folderGroups,
                emptyIcon: Icons.folder_open_rounded,
                emptySubtitle: "添加目录后，这里会展示扫描到的内容",
                titleBuilder: (entry) => p.basename(entry.key),
              ),
              _buildTabContent(
                groups: _albumGroups,
                emptyIcon: Icons.album_rounded,
                emptySubtitle: "添加目录后，这里会自动整理出专辑内容",
                titleBuilder: (entry) => entry.key,
              ),
              _buildTabContent(
                groups: _artistGroups,
                emptyIcon: Icons.person_rounded,
                emptySubtitle: "添加目录后，这里会自动整理出艺术家内容",
                titleBuilder: (entry) => entry.key,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent({
    required Map<String, List<Music>> groups,
    required IconData emptyIcon,
    required String emptySubtitle,
    required String Function(MapEntry<String, List<Music>> entry) titleBuilder,
  }) {
    if (_isScanning && _scannedSongs.isEmpty && _paths.isNotEmpty) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final entries = groups.entries.toList();
    final bool showNoPathsState = _paths.isEmpty && !Platform.isAndroid;
    final bool showNoSongsState = !_isScanning && groups.isEmpty;
    final bool useSliverEmpty = showNoPathsState || showNoSongsState;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 改用更具伸缩性的计算方式
        final double width = constraints.maxWidth;
        final double maxExtent = width > 1200
            ? 180.0
            : (width > 800 ? 190.0 : 210.0);

        return RefreshIndicator(
          onRefresh: () async => _startScan(_paths),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (useSliverEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: showNoPathsState
                        ? AppEmptyState(
                            icon: emptyIcon,
                            title: "还没有扫描目录",
                            subtitle: emptySubtitle,
                            compact: true,
                          )
                        : const AppEmptyState(
                            icon: Icons.audio_file_rounded,
                            title: "没有找到音频文件",
                            subtitle: "当前范围内没有可显示的音频文件",
                            compact: true,
                          ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: maxExtent,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final entry = entries[i];

                      // 1. 挑出一首带有封面的歌，如果都没有，就拿第一首歌当代表
                      final coverSong = entry.value.firstWhere(
                        (song) =>
                            song.coverBytes != null &&
                            song.coverBytes!.isNotEmpty,
                        orElse: () => entry.value.first,
                      );

                      // 🌟 2. 关键补丁：如果连作为代表的 coverSong 都没有封面，
                      // 说明这个分组的所有歌都没洗出封面呢，立刻对这首代表歌曲发起后台懒加载！
                      if (coverSong.coverBytes == null ||
                          coverSong.coverBytes!.isEmpty) {
                        context.read<MusicProvider>().loadCoverLazy(
                          coverSong.id,
                        );
                      }

                      return MediaOverlayCard(
                        title: titleBuilder(entry),
                        subtitle: "${entry.value.length} 首",
                        coverBytes: coverSong.coverBytes,
                        fallbackIcon: emptyIcon,
                        // 智能化转菊花：只要当前作为代表的歌还在后台解析中，卡片就展示 loading 动画
                        isLoading: context.select<MusicProvider, bool>(
                          (p) => p.isCoverLoading(coverSong.id),
                        ),
                        onTap: () {
                          context.push(
                            "/user/files/album-detail",
                            extra: {"albumName": entry.key},
                          );
                        },
                      );
                    }
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================
// 目录选择弹窗
// ==========================================
class _FolderPickDialog extends StatefulWidget {
  final List<String> initialPaths;
  const _FolderPickDialog({required this.initialPaths});

  @override
  State<_FolderPickDialog> createState() => _FolderPickDialogState();
}

class _FolderPickDialogState extends State<_FolderPickDialog> {
  late List<String> _tmpPaths;

  @override
  void initState() {
    super.initState();
    _tmpPaths = [...widget.initialPaths];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("扫描目录"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: () async {
                final selectedPath = await FilePicker.getDirectoryPath();
                if (selectedPath != null && mounted) {
                  setState(() => _tmpPaths.add(selectedPath));
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("添加目录"),
            ),
            const Divider(),
            if (_tmpPaths.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "暂无目录，请点击上方添加",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ..._tmpPaths.map(
              (path) => ListTile(
                title: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _tmpPaths.remove(path)),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("取消"),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _tmpPaths),
          child: const Text("确认"),
        ),
      ],
    );
  }
}
