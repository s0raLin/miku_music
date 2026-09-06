import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:provider/provider.dart';

class FolderPickDialog extends StatefulWidget {
  final List<String> initialPaths;
  final ValueChanged<List<String>> onPathsChanged;

  const FolderPickDialog({
    super.key,
    required this.initialPaths,
    required this.onPathsChanged,
  });

  @override
  State<FolderPickDialog> createState() => _FolderPickDialogState();
}

class _FolderPickDialogState extends State<FolderPickDialog> {
  late List<String> _tmpPaths;
  bool _isScanning = false;
  int _scannedCount = 0;
  String? _error;
  StreamSubscription? _scanSub;
  final List<Music> _scannedSongs = [];
  bool _hasScanned = false;

  @override
  void initState() {
    super.initState();
    _tmpPaths = [...widget.initialPaths];
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  void _deletePath(int index) {
    setState(() {
      _tmpPaths.removeAt(index);
      _hasScanned = false;
    });
  }

  Future<void> _addDirectory() async {
    final p = await FilePicker.getDirectoryPath();
    if (p != null && mounted) {
      if (!_tmpPaths.contains(p)) {
        setState(() {
          _tmpPaths.add(p);
          _hasScanned = false;
        });
      }
    }
  }

  Future<void> _startScan() async {
    if (_tmpPaths.isEmpty) return;
    if (Platform.isAndroid &&
        !(await MusicService.ensureAndroidAudioPermission())) {
      if (mounted) setState(() => _error = '请授予存储和音频权限以扫描音乐');
      return;
    }
    if (!mounted) return;

    setState(() {
      _isScanning = true;
      _scannedCount = 0;
      _scannedSongs.clear();
      _error = null;
      _hasScanned = false;
    });

    _scanSub?.cancel();
    _scanSub = MusicService.scanDirectories(_tmpPaths).listen(
      (progress) {
        if (!mounted) return;
        if (progress.music != null) _scannedSongs.add(progress.music!);
        setState(() {
          _scannedCount++;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _isScanning = false;
          _hasScanned = true;
        });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() {
          _isScanning = false;
          _error = '扫描出错: $err';
        });
      },
    );
  }

  void _handleConfirm() {
    FileService.savePaths(_tmpPaths);
    widget.onPathsChanged(_tmpPaths);
    if (_scannedSongs.isNotEmpty) {
      context.read<MusicProvider>().updateLibrary(List.from(_scannedSongs));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.folder_special_rounded,
                      color: cs.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "管理扫描目录",
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "选择本地媒体文件包含路径",
                          style: tt.bodySmall?.copyWith(color: cs.outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Dynamic Content ──────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.fastOutSlowIn,
                child: _buildBodyContent(cs, tt),
              ),

              const SizedBox(height: 24),

              // ── Actions ─────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!_isScanning)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("取消"),
                    ),
                  const SizedBox(width: 8),
                  if (!_hasScanned)
                    FilledButton.icon(
                      onPressed: (_tmpPaths.isEmpty || _isScanning)
                          ? null
                          : _startScan,
                      icon: _isScanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.search_rounded, size: 18),
                      label: Text(_isScanning ? "扫描中..." : "开始扫描"),
                    )
                  else
                    FilledButton(
                      onPressed: _handleConfirm,
                      child: const Text("保存并应用"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(ColorScheme cs, TextTheme tt) {
    if (_isScanning) {
      return _buildScanningState(cs, tt);
    }

    if (_hasScanned && _error == null) {
      return _buildSuccessState(cs, tt);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_error != null) _buildErrorBanner(cs, tt),

        // 路径列表
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: _tmpPaths.isEmpty
              ? _buildEmptyState(cs, tt)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _tmpPaths.length,
                  itemBuilder: (context, index) {
                    final path = _tmpPaths[index];
                    final folder = path
                        .split(Platform.pathSeparator)
                        .lastWhere((e) => e.isNotEmpty, orElse: () => path);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Material(
                        color: cs.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: Icon(
                            Icons.folder_rounded,
                            color: cs.primary,
                            size: 22,
                          ),
                          title: Text(
                            folder,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                              color: cs.outline,
                              fontSize: 11,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              color: cs.outline,
                              size: 18,
                            ),
                            onPressed: () => _deletePath(index),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        const SizedBox(height: 8),

        // 添加目录按钮 (虚线边框样式感)
        OutlinedButton.icon(
          onPressed: _addDirectory,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text("添加新扫描目录"),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            side: BorderSide(
              color: cs.outlineVariant,
              style: BorderStyle.solid,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 40,
            color: cs.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text("暂未添加任何扫描路径", style: tt.bodyMedium?.copyWith(color: cs.outline)),
        ],
      ),
    );
  }

  Widget _buildScanningState(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          LinearProgressIndicator(borderRadius: BorderRadius.circular(4)),
          const SizedBox(height: 20),
          Text(
            "正在扫描本地音乐...",
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "已检索 $_scannedCount 个文件 · 找到 ${_scannedSongs.length} 首歌曲",
            style: tt.bodySmall?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cs.primary,
            radius: 20,
            child: Icon(Icons.check_rounded, color: cs.onPrimary, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "扫描完成",
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  "成功找到 ${_scannedSongs.length} 首歌曲，点击下方按钮应用并保存",
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(ColorScheme cs, TextTheme tt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: tt.bodySmall?.copyWith(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
