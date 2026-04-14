import 'dart:async';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/contants/Assets/index.dart';
import 'package:myapp/model/Music/index.dart';

import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<MusicInfo> _playList = [];
  bool _isScanning = false; //是否正在扫描
  StreamSubscription? _scanSub; //扫描任务遥控器
  List<String> paths = [];

  // 开始扫描
  void _startScan(List<String> paths) {
    if (paths.isEmpty) return;

    // 如果有正在扫描的任务,关闭它
    _scanSub?.cancel();
    setState(() {
      _playList.clear(); //确保为新扫描,清空旧的
      _isScanning = true;
    });

    //像"接水"一样监听数据流
    _scanSub = MusicService.scanDirectories(paths).listen(
      (scan) {
        //每当冒出一首歌,我们把它加进UI
        setState(() {
          final music = scan.music;
          if (music != null) {
            _playList.add(music);
          }
          _isScanning = false; //只要有一首歌了,就不必显示大转圈
        });
      },
      onDone: () {
        //扫完了
        setState(() {
          _isScanning = false;
        });
      },
      onError: (e) {
        setState(() {
          _isScanning = false;
          debugPrint("扫描出错 $e");
        });
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initScan();
  }

  Future<void> _initScan() async {
    paths = await FileService.loadPaths();
    if (paths.isNotEmpty) {
      _startScan(paths);
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel(); //页面关掉时停止扫描任务,防止内存泄漏
    super.dispose();
  }

  void _showPickDirectoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final List<String> tmpPaths = [...paths];
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("选择扫描目录"),
              content: SizedBox(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () async {
                          final path = await FilePicker.getDirectoryPath();
                          if (path != null) {
                            setDialogState(() {
                              tmpPaths.add(path);
                            });
                          }
                        },
                        label: const Text("选择目录"),
                      ),

                      const SizedBox(height: 15),
                      ...List.generate(tmpPaths.length, (index) {
                        return ListTile(
                          leading: Text(tmpPaths[index]),
                          trailing: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                tmpPaths.removeAt(index);
                              });
                            },
                            icon: Icon(Icons.close),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 关闭弹窗
                  },
                  child: const Text("取消"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    paths = tmpPaths;
                    //持久化路径
                    await FileService.savePaths(paths);

                    _startScan(paths);
                    Navigator.of(context).pop(); //关闭弹窗
                  },
                  child: const Text("确认"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    var albumMap = groupBy(_playList, (MusicInfo music) => music.album);
    var albumNames = albumMap.keys.toList();

    return GridView.builder(
      itemCount: albumMap.length, //总条目数
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 三列
        mainAxisSpacing: 16, // 行间距
        crossAxisSpacing: 16, // 列间距
        childAspectRatio: 1, // 子项宽高比 (宽/高)
      ),
      itemBuilder: (context, index) {
        final albumName = albumNames[index];
        final songsInAlbum = albumMap[albumName] ?? [];

        final coverBytes = songsInAlbum[0].coverBytes;

        return Card(
          clipBehavior: Clip.antiAlias, // 裁剪水波纹
          color: colorScheme.surfaceContainer,
          child: InkWell(
            onTap: () {
              context.push(
                "/album-detail",
                extra: {"albumName": albumName, "songs": songsInAlbum},
              );
            },
            child: coverBytes != null && coverBytes.isNotEmpty
                ? Image.memory(coverBytes)
                : ImageIcon(AssetImage(MyAssets.music_note)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      // body: _playList.isNotEmpty
      //     ? _buildListView(context)
      //     : (_isScanning
      //           ? const Center(child: CircularProgressIndicator())
      //           : _buildEmptyView()),
      body: _buildGridView(context),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPickDirectoryDialog(context),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        icon: const Icon(Icons.folder_open_rounded),
        label: const Text('选择目录'),
      ),
    );
  }
}
