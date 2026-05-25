import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
    with AutomaticKeepAliveClientMixin {
  List<String> _paths = [];

  // Stream<List<MusicInfo>>? _musicStream;
  // List<MusicInfo> _musicList = [];
  List<MusicInfo> _scannedSongs = [];
  bool _isScanning = false;

  StreamSubscription? _scanSubscription;

  @override
  void initState() {
    super.initState();
    FileService.loadPaths().then((p) {
      if (!mounted) return;
      setState(() {
        _paths = p;
      });
      _startScan();
    });
  }

  // 核心逻辑：将扫描流转换为“累加列表流”
  void _startScan() {
    _scanSubscription?.cancel(); //取消上一次扫描
    setState(() {
      // _musicList = [];
      _isScanning = true;
      _scannedSongs = [];
    });

    final scanProgressStream = MusicService.scanDirectories(_paths);
    final musicProvider = context.read<MusicProvider>();

    _scanSubscription = scanProgressStream.listen(
      (s) {
        if (!mounted) return;
        if (s.music != null) {
          _scannedSongs.add(s.music!);

          //每积累15首才刷新一次UI,避免频繁setState
          if (_scannedSongs.length % 15 == 0) {
            setState(() {
              musicProvider.updateLibrary(List.from(_scannedSongs));
            });
          }
        }
      },
      onDone: () {
        if (!mounted) return;

        // 扫描完成,把最后剩下不够15首度歌曲一次性倒进去
        musicProvider.updateLibrary(List.from(_scannedSongs));

        setState(() {
          _isScanning = false;
        });
        if (_scannedSongs.isNotEmpty) {
          AppToast.success(
            context,
            message: '扫描完成，共 ${_scannedSongs.length} 首歌曲',
          );
        } else {
          AppToast.neutral(context, message: '未发现音频文件');
        }
      },
      onError: (e) {
        if (!mounted) return;
        setState(() {
          _isScanning = false;
        });
        AppToast.error(context, message: '扫描出错: $e', title: '扫描失败');
      },
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel(); //取消上一次扫描
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;
    // 当扫描流调用 musicProvider.updateLibrary() 时，这里会自动感知并触发重绘
    final songs = context.watch<MusicProvider>().library;

    final folderGroups = _groupByFolder(songs);
    final albumGroups = _groupByAlbum(songs);
    final artistGroups = _groupByArtist(songs);
    return Scaffold(
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                floating: false, // 向上滚动时 AppBar 是否立即显现
                pinned: true, // 滚动后，bottom 部分（TabBar）是否固定在顶部
                title: const Text("文件"),
                bottom: const TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start, // 让 Tab 靠左对齐
                  tabs: [
                    Tab(text: "文件夹"),
                    Tab(text: "专辑"),
                    Tab(text: "艺术家"),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildLeft(folderGroups),
              _buildCenter(albumGroups),
              _buildRight(artistGroups),
            ],
          ),
        ),
      ),

      floatingActionButton: SpeedDial(
        icon: Icons.menu, // 未展开时的图标
        activeIcon: Icons.close, // 展开时的图标
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        overlayColor: colorScheme.scrim,
        overlayOpacity: 0.5,
        spacing: 12, // 子按钮之间的间距
        children: [
          SpeedDialChild(
            // child: const Icon(Icons.folder_open),
            backgroundColor: colorScheme.secondaryContainer,
            labelWidget: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                // Stadium 形状的关键：使用 StadiumBorder 或者设置很大的圆角
                borderRadius: BorderRadius.circular(28.0),
                color: Theme.of(context).colorScheme.secondaryContainer,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // 紧凑
                mainAxisAlignment: MainAxisAlignment.center, // 内容居中
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    '选择目录',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                      // 关键：标签的字体颜色
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () => _showPickDialog(),
          ),
        ],
      ),
    );
  }

  // 弹出选择目录的 Dialog
  Future<void> _showPickDialog() async {
    final List<String> tmp = [..._paths];
    final result = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setTileState) => AlertDialog(
          title: const Text("扫描目录"),
          content: SizedBox(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final p = await FilePicker.getDirectoryPath();
                    if (p != null) setTileState(() => tmp.add(p));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("添加目录"),
                ),
                const Divider(),
                ...tmp.map(
                  (p) => ListTile(
                    title: Text(p, maxLines: 1),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setTileState(() => tmp.remove(p)),
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
              onPressed: () => Navigator.pop(ctx, tmp),
              child: const Text("确认"),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      if (Platform.isAndroid &&
          !(await MusicService.ensureAndroidAudioPermission())) {
        if (mounted) {
          AppToast.error(context, message: '请授予存储和音频权限以扫描音乐', title: '权限不足');
        }
        return;
      }
      await FileService.savePaths(result);
      setState(() {
        _paths = result;
      });
      _startScan();
    }
  }

  Map<String, List<MusicInfo>> _groupByFolder(List<MusicInfo> songs) {
    final groups = <String, List<MusicInfo>>{};
    for (final song in songs) {
      groups.putIfAbsent(p.dirname(song.id), () => []).add(song);
    }
    return groups;
  }

  Map<String, List<MusicInfo>> _groupByAlbum(List<MusicInfo> songs) {
    final groups = <String, List<MusicInfo>>{};
    for (final song in songs) {
      final album = song.album?.trim();
      groups
          .putIfAbsent(album?.isNotEmpty == true ? album! : '未知专辑', () => [])
          .add(song);
    }
    return groups;
  }

  Map<String, List<MusicInfo>> _groupByArtist(List<MusicInfo> songs) {
    final groups = <String, List<MusicInfo>>{};
    for (final song in songs) {
      groups.putIfAbsent(song.artist, () => []).add(song);
    }
    return groups;
  }

  Widget _buildLeft(Map<String, List<MusicInfo>> folderGroups) {
    if (_isScanning && _scannedSongs.isEmpty && _paths.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paths.isEmpty && !Platform.isAndroid) {
      return const AppEmptyState(
        icon: Icons.folder_open_rounded,
        title: "还没有扫描目录",
        subtitle: "点击右下角按钮添加目录后，这里会展示扫描到的内容",
        compact: true,
      );
    }

    if (!_isScanning && folderGroups.isEmpty) {
      return const AppEmptyState(
        icon: Icons.audio_file_rounded,
        title: "没有找到音频文件",
        subtitle: "当前范围内没有可显示的音频文件",
        compact: true,
      );
    }

    final albums = folderGroups.entries.toList();
    return _buildCollectionGrid(
      albums,
      emptyIcon: Icons.folder_open_rounded,
      titleBuilder: (entry) => p.basename(entry.key),
      subtitleBuilder: (entry) => "${entry.value.length} 首",
      onTap: (entry) {
        context.push(
          "/user/files/album-detail",
          extra: {"albumName": entry.key},
        );
      },
    );
  }

  Widget _buildCenter(Map<String, List<MusicInfo>> albumGroups) {
    if (_isScanning && _scannedSongs.isEmpty && _paths.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paths.isEmpty && !Platform.isAndroid) {
      return const AppEmptyState(
        icon: Icons.album_rounded,
        title: "还没有扫描目录",
        subtitle: "添加目录后，这里会自动整理出专辑内容",
        compact: true,
      );
    }

    if (!_isScanning && albumGroups.isEmpty) {
      return const AppEmptyState(
        icon: Icons.audio_file_rounded,
        title: "没有找到音频文件",
        subtitle: "当前范围内没有可显示的音频文件",
        compact: true,
      );
    }

    final albums = albumGroups.entries.toList();
    return _buildCollectionGrid(
      albums,
      emptyIcon: Icons.album_rounded,
      titleBuilder: (entry) => entry.key,
      subtitleBuilder: (entry) => "${entry.value.length} 首",
      onTap: (entry) {
        context.push(
          "/user/files/album-detail",
          extra: {"albumName": entry.key},
        );
      },
    );
  }

  Widget _buildRight(Map<String, List<MusicInfo>> artistGroups) {
    if (_isScanning && _scannedSongs.isEmpty && _paths.isNotEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_paths.isEmpty && !Platform.isAndroid) {
      return const AppEmptyState(
        icon: Icons.person_rounded,
        title: "还没有扫描目录",
        subtitle: "添加目录后，这里会自动整理出艺术家内容",
        compact: true,
      );
    }

    if (!_isScanning && artistGroups.isEmpty) {
      return const AppEmptyState(
        icon: Icons.audio_file_rounded,
        title: "没有找到音频文件",
        subtitle: "当前范围内没有可显示的音频文件",
        compact: true,
      );
    }

    final albums = artistGroups.entries.toList();
    return _buildCollectionGrid(
      albums,
      emptyIcon: Icons.person_rounded,
      titleBuilder: (entry) => entry.key,
      subtitleBuilder: (entry) => "${entry.value.length} 首",
      onTap: (entry) {
        context.push(
          "/user/files/album-detail",
          extra: {"albumName": entry.key},
        );
      },
    );
  }

  Widget _buildCollectionGrid(
    List<MapEntry<String, List<MusicInfo>>> entries, {
    required IconData emptyIcon,
    required String Function(MapEntry<String, List<MusicInfo>> entry)
    titleBuilder,
    required String Function(MapEntry<String, List<MusicInfo>> entry)
    subtitleBuilder,
    required void Function(MapEntry<String, List<MusicInfo>> entry) onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxExtent = constraints.maxWidth >= 1400
            ? 180.0
            : constraints.maxWidth >= 1000
            ? 200.0
            : 220.0;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: maxExtent,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  final cover = entry.value
                      .firstWhere(
                        (song) =>
                            song.coverBytes != null &&
                            song.coverBytes!.isNotEmpty,
                        orElse: () => entry.value.first,
                      )
                      .coverBytes;
                  return MediaGridCard(
                    title: titleBuilder(entry),
                    subtitle: subtitleBuilder(entry),
                    coverBytes: cover,
                    fallbackIcon: Icon(emptyIcon, size: 32),
                    onTap: () => onTap(entry),
                    coverAspectRatio: 1.22,
                    titleLines: 1,
                    contentSpacing: 4,
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true; // 返回 true 以保持状态
}
