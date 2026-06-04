import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  List<String> _paths = [];
  bool _isPathsLoading = true;
  bool _isScanning = false;
  List<Music> _scannedSongs = [];
  StreamSubscription? _scanSubscription;

  // 本地状态，不持久化
  bool _isCompact = false;

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

    final songs = context.select<MusicProvider, List<Music>>((p) => p.library);

    _updateGroupsIfNeeded(songs);

    final isDesktop =
        Platform.isWindows || Platform.isMacOS || Platform.isLinux;

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
              actions: [
                if (isDesktop)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.grid_view_rounded),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          icon: Icon(Icons.view_compact_rounded),
                        ),
                      ],
                      selected: {_isCompact},
                      onSelectionChanged: (Set<bool> v) {
                        setState(() => _isCompact = v.first);
                      },
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: "文件夹"),
                  Tab(text: "专辑"),
                  Tab(text: "艺术家"),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildTabContent(
                groups: _folderGroups,
                emptyIcon: Icons.folder_open_rounded,
                emptySubtitle: "添加目录后，这里会展示扫描到的内容",
                titleBuilder: (entry) => p.basename(entry.key),
                isCompact: _isCompact,
              ),
              _buildTabContent(
                groups: _albumGroups,
                emptyIcon: Icons.album_rounded,
                emptySubtitle: "添加目录后，这里会自动整理出专辑内容",
                titleBuilder: (entry) => entry.key,
                isCompact: _isCompact,
              ),
              _buildTabContent(
                groups: _artistGroups,
                emptyIcon: Icons.person_rounded,
                emptySubtitle: "添加目录后，这里会自动整理出艺术家内容",
                titleBuilder: (entry) => entry.key,
                isCompact: _isCompact,
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
    required bool isCompact,
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
        final double width = constraints.maxWidth;

        // 紧凑模式用更小的 item 尺寸，宽松用更大的
        final double maxExtent = isCompact
            ? (width > 1200 ? 140.0 : (width > 800 ? 150.0 : 160.0))
            : (width > 1200 ? 180.0 : (width > 800 ? 190.0 : 210.0));

        final double spacing = isCompact ? 10.0 : 16.0;

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
                  padding: EdgeInsets.fromLTRB(
                    spacing,
                    spacing / 2,
                    spacing,
                    80,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: maxExtent,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      return _MediaGridItem(
                        key: ValueKey(entries[i].key),
                        entry: entries[i],
                        emptyIcon: emptyIcon,
                        titleBuilder: titleBuilder,
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

// ==========================================
// 独立出来的网格单项子组件
// ==========================================
class _MediaGridItem extends StatelessWidget {
  final MapEntry<String, List<Music>> entry;
  final IconData emptyIcon;
  final String Function(MapEntry<String, List<Music>> entry) titleBuilder;

  const _MediaGridItem({
    super.key,
    required this.entry,
    required this.emptyIcon,
    required this.titleBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final coverSong = entry.value.firstWhere(
      (song) => song.coverBytes != null && song.coverBytes!.isNotEmpty,
      orElse: () => entry.value.first,
    );

    if (coverSong.coverBytes == null || coverSong.coverBytes!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          final provider = context.read<MusicProvider>();
          if (!provider.isCoverLoading(coverSong.id)) {
            provider.loadCoverLazy(coverSong.id);
          }
        }
      });
    }

    return Selector<MusicProvider, bool>(
      selector: (_, provider) => provider.isCoverLoading(coverSong.id),
      builder: (context, isLoading, _) {
        return MediaOverlayCard(
          title: titleBuilder(entry),
          subtitle: "${entry.value.length} 首",
          coverBytes: coverSong.coverBytes,
          fallbackIcon: emptyIcon,
          isLoading: isLoading,
          onTap: () {
            context.push(
              "/user/files/album-detail",
              extra: {"albumName": entry.key},
            );
          },
        );
      },
    );
  }
}
