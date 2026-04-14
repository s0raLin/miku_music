import 'dart:io';
import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/contants/Assets/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

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
                ElevatedButton.icon(
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
            ElevatedButton(
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
    return Scaffold(
      body: StreamBuilder<List<MusicInfo>>(
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

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: albums.length,
            itemBuilder: (context, i) {
              final cover = albums[i].value.first.coverBytes;
              return InkWell(
                onTap: () {
                  final albumName = albums[i].key;
                  final album = albums[i].value;
                  context.push(
                    "/album-detail",

                    extra: {"albumName": albumName, "songs": album},
                  );
                },
                child: Card(
                  elevation: 0, // 去掉卡片阴影，更简洁
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: cover != null && cover.isNotEmpty
                      ? Image.memory(cover, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          child: Center(
                            child: Image.asset(MyAssets.music_note, width: 40),
                          ),
                        ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showPickDialog,
        elevation: 0, // 彻底干掉阴影，走极简风
        highlightElevation: 0,
        icon: const Icon(Icons.folder_open),
        label: const Text('选择目录'),
      ),
    );
  }
}
