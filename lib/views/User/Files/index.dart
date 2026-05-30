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
    with AutomaticKeepAliveClientMixin {
  List<String> _paths = [];
  bool _isScanning = false;
  List<Music> _scannedSongs = [];
  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    FileService.loadPaths().then((loadedPaths) {
      if (mounted) {
        setState(() => _paths = loadedPaths);
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

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
    final pageContext = context;

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
        if (!pageContext.mounted) return;
        musicProvider.updateLibrary(List.from(_scannedSongs));
        setState(() => _isScanning = false);

        if (_scannedSongs.isNotEmpty) {
          AppToast.success(
            pageContext,
            message: '扫描完成，共 ${_scannedSongs.length} 首歌曲',
          );
        } else {
          AppToast.neutral(pageContext, message: '未发现音频文件');
        }
      },
      onError: (err) {
        if (!mounted) return;
        setState(() => _isScanning = false);
        if (!pageContext.mounted) return;
        AppToast.error(pageContext, message: '扫描出错: $err', title: '扫描失败');
      },
    );
  }

  Future<void> _showPickDialog() async {
    final List<String> tmpPaths = [..._paths];
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("扫描目录"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final selectedPath = await FilePicker.getDirectoryPath();
                    if (selectedPath != null) {
                      setDialogState(() => tmpPaths.add(selectedPath));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("添加目录"),
                ),
                const Divider(),
                ...tmpPaths.map(
                  (path) => ListTile(
                    title: Text(
                      path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setDialogState(() => tmpPaths.remove(path)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("取消"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, tmpPaths),
              child: const Text("确认"),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

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
  // 数据分组算法
  // ==========================================

  Map<String, List<Music>> _groupByFolder(List<Music> songs) {
    final groups = <String, List<Music>>{};
    for (final song in songs) {
      groups.putIfAbsent(p.dirname(song.id), () => []).add(song);
    }
    return groups;
  }

  Map<String, List<Music>> _groupByAlbum(List<Music> songs) {
    final groups = <String, List<Music>>{};
    for (final song in songs) {
      final album = song.album?.trim();
      groups
          .putIfAbsent(
            album != null && album.isNotEmpty ? album : '未知专辑',
            () => [],
          )
          .add(song);
    }
    return groups;
  }

  Map<String, List<Music>> _groupByArtist(List<Music> songs) {
    final groups = <String, List<Music>>{};
    for (final song in songs) {
      groups.putIfAbsent(song.artist, () => []).add(song);
    }
    return groups;
  }

  // ==========================================
  // UI 构建核心方法
  // ==========================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 使用 select 粒度化监听，只有 library 引用改变时才触发 build
    final songs = context.select<MusicProvider, List<Music>>((p) => p.library);

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
                groups: _groupByFolder(songs),
                emptyIcon: Icons.folder_open_rounded,
                emptySubtitle: "添加目录后，这里会展示扫描到的内容",
                titleBuilder: (entry) => p.basename(entry.key),
              ),
              _buildTabContent(
                groups: _groupByAlbum(songs),
                emptyIcon: Icons.album_rounded,
                emptySubtitle: "添加目录后，这里会自动整理出专辑内容",
                titleBuilder: (entry) => entry.key,
              ),
              _buildTabContent(
                groups: _groupByArtist(songs),
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

  /// 统一的 Tab 页面工厂，通过参数化消灭三大块重复逻辑
  Widget _buildTabContent({
    required Map<String, List<Music>> groups,
    required IconData emptyIcon,
    required String emptySubtitle,
    required String Function(MapEntry<String, List<Music>> entry) titleBuilder,
  }) {
    // 状态 1：正在全新扫描且暂无任何缓存歌曲展示
    if (_isScanning && _scannedSongs.isEmpty && _paths.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // 状态 2：未选路径（非安卓端）
    if (_paths.isEmpty && !Platform.isAndroid) {
      return AppEmptyState(
        icon: emptyIcon,
        title: "还没有扫描目录",
        subtitle: emptySubtitle,
        compact: true,
      );
    }

    // 状态 3：扫描完成了但是啥也没找到
    if (!_isScanning && groups.isEmpty) {
      return const AppEmptyState(
        icon: Icons.audio_file_rounded,
        title: "没有找到音频文件",
        subtitle: "当前范围内没有可显示的音频文件",
        compact: true,
      );
    }

    final entries = groups.entries.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = constraints.maxWidth >= 1400
            ? 180.0
            : constraints.maxWidth >= 1000
            ? 200.0
            : 220.0;

        return RefreshIndicator(
          onRefresh: () async => _startScan(_paths),
          child: CustomScrollView(
            slivers: [
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

                    // 优化提取 Cover 的逻辑，使用 fast-path 优先定位非空封面
                    final coverSong = entry.value.firstWhere(
                      (song) =>
                          song.coverBytes != null &&
                          song.coverBytes!.isNotEmpty,
                      orElse: () => entry.value.first,
                    );

                    return MediaOverlayCard(
                      title: titleBuilder(entry),
                      subtitle: "${entry.value.length} 首",
                      coverBytes: coverSong.coverBytes,
                      fallbackIcon: emptyIcon,
                      onTap: () {
                        context.push(
                          "/user/files/album-detail",
                          extra: {"albumName": entry.key},
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
