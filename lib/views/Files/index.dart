import 'dart:io';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/contants/Assets/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:permission_handler/permission_handler.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});
  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<String> _paths = [];

  Stream<List<MusicInfo>>? _musicStream;

  @override
  void initState() {
    super.initState();
    FileService.loadPaths().then((p) {
      if (p.isNotEmpty) {
        setState(() {
          _paths = p;
          _startScan();
        });
      }
    });
  }

  // 核心逻辑：将扫描流转换为“累加列表流”
  void _startScan() {
    List<MusicInfo> acc = [];
    _musicStream = MusicService.scanDirectories(_paths).map((s) {
      if (s.music != null) acc.add(s.music!);
      return List<MusicInfo>.from(acc);
    }).asBroadcastStream();
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
      if (Platform.isAndroid && !(await Permission.audio.request().isGranted)) {
        return;
      }
      await FileService.savePaths(result);
      setState(() {
        _paths = result;

        _startScan();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: RefreshIndicator(
        edgeOffset: MediaQuery.of(context).padding.top + 56,
        onRefresh: () async {
          _startScan();
        },
        child: StreamBuilder<List<MusicInfo>>(
          key: ValueKey(_paths.toString()),
          stream: _musicStream,
          builder: (context, snapshot) {
            final list = snapshot.data ?? [];
            if (list.isEmpty && _paths.isNotEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final albums = groupBy(
              list,
              (MusicInfo m) => m.album,
            ).entries.toList();

            return LayoutBuilder(
              builder: (context, constraints) {
                final maxExtent = constraints.maxWidth >= 1400
                    ? 180.0
                    : constraints.maxWidth >= 1000
                    ? 200.0
                    : 220.0;
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      pinned: false,
                      snap: false,
                      floating: false,
                      expandedHeight: 80,
                      flexibleSpace: const FlexibleSpaceBar(title: Text("库")),
                    ),
                    SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: maxExtent,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: albums.length,
                      itemBuilder: (context, i) {
                        final cover = albums[i].value.first.coverBytes;
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () {
                              final albumName = albums[i].key;
                              final album = albums[i].value;
                              context.push(
                                "/album-detail",
                                extra: {"albumName": albumName, "songs": album},
                              );
                            },
                            child: cover != null && cover.isNotEmpty
                                ? Image.memory(cover, fit: BoxFit.cover)
                                : Container(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainer,
                                    child: Center(
                                      child: Image.asset(
                                        MyAssets.music_note,
                                        width: 40,
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.menu, // 未展开时的图标
        activeIcon: Icons.close, // 展开时的图标
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        overlayColor: Colors.black, // 展开时的背景遮罩色
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
}
