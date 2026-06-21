import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/views/MusicDetail/widgets/cover_tab_content.dart';
import 'package:myapp/views/MusicDetail/widgets/lyrics_section.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';
import 'package:myapp/views/MusicDetail/widgets/playback_queue_drawer.dart';
import 'package:provider/provider.dart';

class NarrowLayout extends StatefulWidget {
  final Music music;

  const NarrowLayout({super.key, required this.music});

  @override
  State<NarrowLayout> createState() => _NarrowLayoutState();
}

class _NarrowLayoutState extends State<NarrowLayout> {
  int _selectedSegment = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedSegment);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCoverTab = _selectedSegment == 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => _selectedSegment = index);
              },
              children: [
                CoverTabContent(music: widget.music),
                const LyricsSection(),
              ],
            ),
            // 顶部沉浸式操作栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: cs.onSurface,
                      ),
                      onPressed: () => context.pop(),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DotIndicator(
                          isSelected: _selectedSegment == 0,
                          onTap: () {
                            setState(() => _selectedSegment = 0);
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        _DotIndicator(
                          isSelected: _selectedSegment == 1,
                          onTap: () {
                            setState(() => _selectedSegment = 1);
                            _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (isCoverTab)
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          MusicActionMenu.showMoreOptions(context, details);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Icon(Icons.more_vert_rounded),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: () => _showLyricSourceDialog(context),
                        tooltip: '歌词来源',
                        icon: Icon(Icons.lyrics_rounded, color: cs.primary),
                      ),
                  ],
                ),
              ),
            ),
          ],
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

class _DotIndicator extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const _DotIndicator({required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isSelected
              ? cs.primary
              : cs.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
