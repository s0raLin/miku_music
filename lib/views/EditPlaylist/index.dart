import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:provider/provider.dart';

class PlaylistEditPage extends StatefulWidget {
  final String playlistId;

  const PlaylistEditPage({super.key, required this.playlistId});

  @override
  State<PlaylistEditPage> createState() => _PlaylistEditPageState();
}

class _PlaylistEditPageState extends State<PlaylistEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  String? _coverPath;
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final playlistProvider = context.read<PlaylistProvider>();
    final playlist = playlistProvider.getPlaylistById(widget.playlistId);
    if (playlist == null) {
      // 如果 Provider 里找不到，说明可能是不合法 ID，直接退出
      Future.microtask(() {
        if (!mounted) return;
        context.pop();
      });
      return;
    }
    // 1. 先用构造函数传进来的数据做基础初始化，防止界面卡顿或空白
    _nameController = TextEditingController(text: playlist.name);
    _descController = TextEditingController(text: playlist.description);

    // 2. 如果 Provider 存在最新数据，用最新数据覆盖（保持数据同步）
    _nameController.text = playlist.name;
    _descController.text = playlist.description ?? '';
    _coverPath = playlist.coverPath;

    _initialized = true;
  }

  @override
  void dispose() {
    if (_initialized) {
      _nameController.dispose();
      _descController.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    // 修复：改用新版 FilePicker API
    final result = await FilePicker.pickFiles(type: FileType.image);

    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;

    setState(() {
      _coverPath = path;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      AppToast.error(context, message: "歌单名称不能为空");
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await context.read<PlaylistProvider>().updatePlaylist(
        widget.playlistId,
        name,
        description: _descController.text.trim(),
        coverPath: _coverPath,
      );

      if (!mounted) return;
      AppToast.success(context, message: "歌单信息已更新");
      context.pop();
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, message: "保存失败");
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("编辑歌单"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("保存"),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _coverPath != null
                              ? Image.file(File(_coverPath!), fit: BoxFit.cover)
                              : Icon(
                                  Icons.photo_rounded,
                                  size: 72,
                                  color: cs.primary,
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        children: [
                          FilledButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_rounded),
                            label: const Text("更换封面"),
                          ),
                          if (_coverPath != null)
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _coverPath = null;
                                });
                              },
                              icon: const Icon(Icons.delete_outline_rounded),
                              label: const Text("移除封面"),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  maxLength: 30,
                  decoration: InputDecoration(
                    labelText: "歌单名称",
                    hintText: "输入歌单名称",
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _descController,
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: "歌单描述",
                    hintText: "写点什么介绍这个歌单吧...",
                    alignLabelWithHint: true,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "封面图片仅保存本地路径，请勿删除原始文件。",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
