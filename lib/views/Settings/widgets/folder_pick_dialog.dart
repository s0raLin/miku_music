import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/service/Files/index.dart';
import 'package:myapp/service/Music/index.dart';
import 'package:provider/provider.dart';

/// M3 scan-directory management dialog — refined card list + scan progress.
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
  int _foundCount = 0;
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
    setState(() => _tmpPaths.removeAt(index));
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
      _foundCount = 0;
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
          _foundCount = _scannedSongs.length;
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() { _isScanning = false; _hasScanned = true; });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() { _isScanning = false; _error = '扫描出错: $err'; });
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
    final width = (MediaQuery.of(context).size.width * 0.88).clamp(0.0, 520.0);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      title: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.folder_special_rounded, color: cs.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Text("管理扫描目录", style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ]),
      content: SizedBox(
        width: width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Add folder button ────────────────────────────────────────
              FilledButton.tonalIcon(
                onPressed: _isScanning ? null : () async {
                  final p = await FilePicker.getDirectoryPath();
                  if (p != null && mounted) {
                    setState(() { _tmpPaths.add(p); _hasScanned = false; });
                  }
                },
                icon: const Icon(Icons.create_new_folder_rounded, size: 18),
                label: const Text("添加新扫描目录"),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),

              // ── Directory list ───────────────────────────────────────────
              if (_tmpPaths.isEmpty)
                _buildEmptyDirectoryHint(cs, tt)
              else
                Container(
                  constraints: const BoxConstraints(maxHeight: 280),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: _tmpPaths.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1, indent: 60, endIndent: 16,
                      color: cs.outlineVariant.withValues(alpha: 0.25),
                    ),
                    itemBuilder: (context, index) {
                      final path = _tmpPaths[index];
                      final folder = path.split(Platform.pathSeparator).last;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        leading: Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: cs.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.folder_rounded, color: cs.primary, size: 20),
                        ),
                        title: Text(folder, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                        subtitle: Text(path, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(color: cs.outline, fontSize: 11)),
                        trailing: _isScanning ? null : IconButton(
                          icon: Icon(Icons.remove_circle_outline_rounded, color: cs.error, size: 20),
                          onPressed: () => _deletePath(index),
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),

              // ── Scan action area ─────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOut,
                child: Column(children: [
                  if (_isScanning)
                    _ScanningStatus(cs: cs, tt: tt, scanned: _scannedCount, found: _foundCount)
                  else if (_tmpPaths.isNotEmpty && !_hasScanned)
                    FilledButton.icon(
                      onPressed: _startScan,
                      icon: const Icon(Icons.manage_search_rounded, size: 20),
                      label: const Text("开始扫描歌曲"),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  if (!_isScanning && _hasScanned)
                    _ScanSuccess(cs: cs, tt: tt, count: _foundCount),
                  if (_error != null)
                    _ScanError(cs: cs, tt: tt, message: _error!),
                ]),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isScanning ? null : () => Navigator.pop(context), child: const Text("取消")),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _isScanning ? null : _handleConfirm,
          child: Text(_hasScanned ? "完成" : "确定"),
        ),
      ],
    );
  }

  Widget _buildEmptyDirectoryHint(ColorScheme cs, TextTheme tt) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 44),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(Icons.folder_off_rounded, size: 44, color: cs.outline.withValues(alpha: 0.5)),
        const SizedBox(height: 14),
        Text("暂无扫描目录\n点击上方按钮添加",
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _ScanningStatus extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final int scanned;
  final int found;
  const _ScanningStatus({required this.cs, required this.tt, required this.scanned, required this.found});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: const LinearProgressIndicator(minHeight: 5),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary)),
          const SizedBox(width: 12),
          Text("正在扫描…", style: tt.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 10),
        Text("已检查 $scanned 个文件 · 找到 $found 首音乐",
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      ]),
    );
  }
}

class _ScanSuccess extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final int count;
  const _ScanSuccess({required this.cs, required this.tt, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check_rounded, color: cs.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("扫描完成", style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            Text("成功导入 $count 首歌曲",
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ]),
        ),
      ]),
    );
  }
}

class _ScanError extends StatelessWidget {
  final ColorScheme cs;
  final TextTheme tt;
  final String message;
  const _ScanError({required this.cs, required this.tt, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.error.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline_rounded, color: cs.error, size: 24),
        const SizedBox(width: 14),
        Expanded(child: Text(message,
            style: tt.bodyMedium?.copyWith(color: cs.onErrorContainer))),
      ]),
    );
  }
}
