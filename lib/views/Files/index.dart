import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myapp/service/Files/index.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  List<FileSystemEntity> musicFiles = [];
  var _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _showPickDirectoryDialog(BuildContext context) {
    String? _tmpPath; //用于弹窗临时选中
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("选择扫描目录"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      String? path = await FilePicker.getDirectoryPath();
                      if (path != null) {
                        setDialogState(() {
                          _tmpPath = path;
                        });
                      }
                    },
                    label: const Text("选择目录"),
                  ),

                  const SizedBox(height: 15),
                  Text(_tmpPath ?? ""),
                ],
              ),
              actions: [
                TextButton(onPressed: () {}, child: const Text("取消")),
                ElevatedButton(
                  onPressed: _tmpPath == null
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                          });
                          Navigator.of(context).pop(); //关闭弹窗

                          musicFiles = await MusicScanner.scanDirectory(
                            _tmpPath!,
                          );
                          setState(() {
                            _isLoading = false;
                          });
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

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(), //进度条
          Text("正在全力加载中..."),
        ],
      ),
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

  Widget _buildListView() {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: musicFiles.length,
      itemBuilder: (context, index) {
        final path = musicFiles[index].path;
        return Material(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: ListTile(
                leading: Text(path, style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        );
        
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: _isLoading
          ? _buildLoadingView()
          : (musicFiles.isEmpty ? _buildEmptyView() : _buildListView()),

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

  // Future<void> pickDirectory() async {
  //   final selectedDirectory = await FilePicker.getDirectoryPath();
  //   if (selectedDirectory != null) {
  //     setState(() => _isLoading = true);

  //     try {
  //       final directory = Directory(selectedDirectory);
  //       final List<FileSystemEntity> entities = await directory
  //           .list(recursive: false)
  //           .toList();

  //       final List<File> files = entities.whereType<File>().where((file) {
  //         final mimeType = lookupMimeType(file.path);
  //         return mimeType != null && mimeType.startsWith("audio/");
  //       }).toList();

  //       setState(() {
  //         _musicFiles = files;
  //         _isLoading = false;
  //       });
  //     } catch (e) {
  //       setState(() => _isLoading = false);
  //       if (mounted) {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(SnackBar(content: Text('读取目录失败: $e')));
  //       }
  //     }
  //   }
  // }

// floatingActionButton: FloatingActionButton.extended(
//         onPressed: pickDirectory,
//         backgroundColor: colorScheme.primary,
//         foregroundColor: colorScheme.onPrimary,
//         icon: const Icon(Icons.folder_open_rounded),
//         label: const Text('选择目录'),
//       ),
