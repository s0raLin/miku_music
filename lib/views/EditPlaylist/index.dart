import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  String? _originalCoverPath; // 记录初始封面路径，用于清理旧缓存文件
  bool _initialized = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final playlistProvider = context.read<PlaylistProvider>();
    final playlist = playlistProvider.getPlaylistById(widget.playlistId);
    if (playlist == null) {
      Future.microtask(() {
        if (!mounted) return;
        context.pop();
      });
      return;
    }

    _nameController = TextEditingController(text: playlist.name);
    _descController = TextEditingController(text: playlist.description ?? '');
    _coverPath = playlist.coverPath;
    _originalCoverPath = playlist.coverPath;

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
    final result = await FilePicker.pickFiles(type: FileType.image);

    if (result == null) return;
    final path = result.files.single.path;
    if (path == null) return;

    setState(() {
      _coverPath = path;
    });
  }

  /// 将选取的文件复制到安全的应用文档目录 (App Documents/playlist_covers)
  Future<String?> _copyCoverToAppStorage(String sourcePath) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory(p.join(docDir.path, 'playlist_covers'));

      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      // 如果选取的图片已经在 playlist_covers 中，说明不需要再次复制
      if (p.isWithin(coversDir.path, sourcePath)) {
        return sourcePath;
      }

      final ext = p.extension(sourcePath);
      final newFileName =
          'cover_${widget.playlistId}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final newPath = p.join(coversDir.path, newFileName);

      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        final copiedFile = await sourceFile.copy(newPath);
        return copiedFile.path;
      }
    } catch (e) {
      debugPrint("复制封面失败: $e");
    }
    return sourcePath; // 若失败则回退至原路径
  }

  /// 尝试清理不再使用的旧封面文件，释放磁盘空间
  Future<void> _cleanOldCover() async {
    if (_originalCoverPath == null || _originalCoverPath == _coverPath) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory(p.join(docDir.path, 'playlist_covers'));

      // 仅清理存放在应用专属封面目录中的旧文件，避免意外删除用户的原始文件
      if (p.isWithin(coversDir.path, _originalCoverPath!)) {
        final oldFile = File(_originalCoverPath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }
    } catch (e) {
      debugPrint("清理旧封面失败: $e");
    }
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
      String? finalCoverPath = _coverPath;

      // 如果设置了封面且封面路径发生了变化，将其持久化拷贝到 Safe Directory
      if (_coverPath != null && _coverPath != _originalCoverPath) {
        finalCoverPath = await _copyCoverToAppStorage(_coverPath!);
      }

      if (!mounted) return;

      await context.read<PlaylistProvider>().updatePlaylist(
        widget.playlistId,
        name,
        description: _descController.text.trim(),
        coverPath: finalCoverPath,
      );

      // 保存成功后清理过期的旧封面文件
      await _cleanOldCover();

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
                          child:
                              _coverPath != null &&
                                  File(_coverPath!).existsSync()
                              ? Image.file(
                                  File(_coverPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(
                                        Icons.broken_image_rounded,
                                        size: 72,
                                        color: cs.error,
                                      ),
                                )
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
                      Icon(Icons.shield_outlined, color: cs.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "封面图片已自动安全备份保存至应用内部，清除缓存或移动原图片不会影响歌单封面展示。",
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
