import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:provider/provider.dart';

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
      (music) {
        //每当冒出一首歌,我们把它加进UI
        setState(() {
          _playList.add(music);
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
                              paths.add(path);
                            });
                          }
                        },
                        label: const Text("选择目录"),
                      ),

                      const SizedBox(height: 15),
                      ...List.generate(paths.length, (index) {
                        return ListTile(
                          leading: Text(paths[index]),
                          trailing: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                paths.removeAt(index);
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
                    //持久化路径
                    FileService.savePaths(paths);
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

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(Icons.library_music_outlined), Text("文件夹列表为空")],
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final musicProvider = context.watch<MusicProvider>();

    return ListTileTheme(
      data: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: colorScheme.primary,
        textColor: colorScheme.onSurface,

        tileColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ), //外轮廓
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(12), // 列表整体内边距
        itemCount: _playList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final item = _playList[index];
          return ListTile(
            // 这里的 ListTile 会自动继承上方 ListTileTheme 的样式
            onTap: () {
              musicProvider.playFromLibrary(item);
              final filePath = item.id;

              context.push("/music-detail", extra: filePath);
            },
            leading: Container(
              width: 50,
              height: 50,
              clipBehavior: Clip.antiAlias, //抗锯齿
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: item.coverBytes != null
                  ? Image.memory(item.coverBytes!, fit: BoxFit.cover)
                  : const Icon(Icons.music_note),
            ),
            title: Text(item.title),
            subtitle: Text(item.artist),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: _playList.isNotEmpty
          ? _buildListView(context)
          : (_isScanning
                ? const Center(child: CircularProgressIndicator())
                : _buildEmptyView()),

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
