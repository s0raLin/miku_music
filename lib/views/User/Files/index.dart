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
import 'package:shared_preferences/shared_preferences.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  static const String _prefCompactKey = 'files_page_is_compact';

  List<String> _paths = [];
  bool _isPathsLoading = true;
  bool _isScanning = false;
  List<Music> _scannedSongs = [];
  StreamSubscription? _scanSubscription;

  // 本地密集/宽松视图状态，持久化存储
  bool _isCompact = false;

  // 缓存分组数据及上一次处理的歌单引用，避免频繁在 build() 内部跑循环
  List<Music>? _lastSongsReference;
  Map<String, List<Music>> _folderGroups = {};
  Map<String, List<Music>> _albumGroups = {};
  Map<String, List<Music>> _artistGroups = {};

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _initPaths();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  /// 读取持久化的视图配置
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isCompact = prefs.getBool(_prefCompactKey) ?? false;
      });
    }
  }

  /// 切换并保存视图配置
  Future<void> _toggleCompactMode() async {
    final nextState = !_isCompact;
    setState(() {
      _isCompact = nextState;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefCompactKey, nextState);
  }

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
            message: '扫描完成，共 ${_scannedSongs.length} 首本地歌曲',
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
  // 数据分组算法（高效率缓存机制）
  // ==========================================

  void _updateGroupsIfNeeded(List<Music> currentSongs) {
    // 只有当歌曲列表内存引用改变时，才重新计算分组
    if (identical(_lastSongsReference, currentSongs)) return;
    _lastSongsReference = currentSongs;

    final folders = <String, List<Music>>{};
    final albums = <String, List<Music>>{};
    final artists = <String, List<Music>>{};

    for (final song in currentSongs) {
      // 提取文件夹路径
      final dir = p.dirname(song.id);
      folders.putIfAbsent(dir, () => []).add(song);

      // 提取专辑名
      final albumName = song.album?.trim();
      final albumKey = (albumName != null && albumName.isNotEmpty)
          ? albumName
          : '未知专辑';
      albums.putIfAbsent(albumKey, () => []).add(song);

      // 提取艺术家
      final artistName = song.artist.trim();
      final artistKey = artistName.isNotEmpty ? artistName : '未知艺术家';
      artists.putIfAbsent(artistKey, () => []).add(song);
    }

    _folderGroups = folders;
    _albumGroups = albums;
    _artistGroups = artists;
  }

  /// 文件夹路径转换：确保只提取最末一级文件名/目录名，防止路径过长溢出
  String _buildFolderTitle(String fullPath) {
    final cleanPath = p.normalize(fullPath);
    final basename = p.basename(cleanPath);
    if (basename.isEmpty || basename == '.' || basename == '/') {
      return cleanPath;
    }
    return basename;
  }

  // ==========================================
  // UI 构建核心方法
  // ==========================================

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 仅选择 Provider 中的 localLibrary
    final songs = context.select<MusicProvider, List<Music>>(
      (p) => p.localLibrary,
    );

    // 仅在数据发生真正变更时才计算分组
    _updateGroupsIfNeeded(songs);

    if (_isPathsLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              title: const Text("本地文件"),
              actions: [
                Tooltip(
                  message: _isCompact ? "切换到大图模式" : "切换到紧凑模式",
                  child: IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _isCompact
                            ? Icons.view_compact_rounded
                            : Icons.grid_view_rounded,
                        key: ValueKey<bool>(_isCompact),
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    onPressed: _toggleCompactMode,
                  ),
                ),
                const SizedBox(width: 8),
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
                emptySubtitle: "添加目录后，这里会展示扫描到的本地内容",
                titleBuilder: (entry) => _buildFolderTitle(entry.key),
                isCompact: _isCompact,
              ),
              _buildTabContent(
                groups: _albumGroups,
                emptyIcon: Icons.album_rounded,
                emptySubtitle: "添加目录后，这里会自动整理出本地专辑内容",
                titleBuilder: (entry) => entry.key,
                isCompact: _isCompact,
              ),
              _buildTabContent(
                groups: _artistGroups,
                emptyIcon: Icons.person_rounded,
                emptySubtitle: "添加目录后，这里会自动整理出本地艺术家内容",
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

        final double maxExtent = isCompact
            ? (width > 1200 ? 130.0 : (width > 600 ? 140.0 : 145.0))
            : (width > 1200 ? 180.0 : (width > 600 ? 190.0 : 200.0));

        final double spacing = isCompact ? 10.0 : 16.0;

        return RefreshIndicator(
          onRefresh: () async => _startScan(_paths),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                            title: "没有找到本地音频文件",
                            subtitle: "当前选择的目录下没有发现本地歌曲",
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
                    96, // 预留底部 PlayerBar 空间
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
    // 优先选取包含封面的歌曲作为展示图
    final coverSong = entry.value.firstWhere(
      (song) => song.coverBytes != null && song.coverBytes!.isNotEmpty,
      orElse: () => entry.value.first,
    );

    // 延时异步加载封面
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
          source: MusicSource.local,
        );
      },
    );
  }
}
