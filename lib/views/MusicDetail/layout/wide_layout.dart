import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/MusicDetail/widgets/cover_content.dart';
import 'package:myapp/views/MusicDetail/widgets/lyrics_section.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';
import 'package:myapp/views/MusicDetail/widgets/playback_queue_drawer.dart';
import 'package:provider/provider.dart';

class WideLayout extends StatefulWidget {
  final Music music;

  const WideLayout({super.key, required this.music});

  @override
  State<WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends State<WideLayout> {
  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "正在播放",
          style: tt.titleMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // 歌词来源切换图标按钮
          IconButton(
            onPressed: () => _showLyricSourceDialog(context),
            tooltip: '歌词来源',
            icon: const Icon(Icons.lyrics_rounded),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              MusicActionMenu.showMoreOptions(context, details);
            },
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.more_vert_rounded),
            ),
          ),
          const Padding(padding: EdgeInsets.only(right: 8)),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 5, child: CoverContent(music: widget.music)),
                  const SizedBox(width: 24),
                  const Expanded(flex: 4, child: LyricsSection()),
                ],
              ),
            ),
          ),
        ),
      ),
      endDrawer: PlaybackQueueDrawer(),
    );
  }

  void _showLyricSourceDialog(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.lyrics_rounded, color: cs.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        '歌词来源',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(
                      Icons.folder_open_rounded,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  title: const Text('选择本地歌词文件'),
                  subtitle: const Text('从设备中选择 .lrc / .ttml 文件'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickLocalLyricFile(mp, context);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    child: Icon(
                      Icons.search_rounded,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  title: const Text('在线搜索歌词'),
                  subtitle: const Text('通过网络匹配当前歌曲的歌词'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _searchLyrics(mp, context);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickLocalLyricFile(
    MusicProvider mp,
    BuildContext context,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['lrc', 'ttml', 'txt'],
        dialogTitle: '选择歌词文件',
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.path == null) return;

      final content = await File(file.path!).readAsString();
      if (!context.mounted) return;
      mp.setCurrentLrc(content);
      AppToast.success(context, message: "本地歌词加载成功");
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, message: "歌词文件读取失败");
    }
  }

  Future<void> _searchLyrics(MusicProvider mp, BuildContext context) async {
    AppToast.neutral(context, message: "正在查找中...");
    try {
      final music = mp.currentMusic;
      final result = await MusicApi.searchLyrics(music?.artist, music?.title);
      if (!context.mounted) return;
      if (!result.$2) {
        AppToast.neutral(context, message: "暂未找到歌词");
        return;
      }
      mp.setCurrentLrc(result.$1);
      AppToast.neutral(context, message: "歌词获取成功");
    } catch (e) {
      AppToast.error(context, message: "歌词获取失败");
    }
  }
}
