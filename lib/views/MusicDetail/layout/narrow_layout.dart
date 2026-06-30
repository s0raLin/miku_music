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
  int _page = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int p) {
    setState(() => _page = p);
    _pageController.animateToPage(
      p,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isCover = _page == 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: PlaybackQueueDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            // ── PageView ──
            PageView(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                CoverTabContent(music: widget.music),
                const LyricsSection(),
              ],
            ),

            // ── 顶部操作栏 ──
            Positioned(
              top: 0, left: 0, right: 0,
              child: _TopBar(
                isCover: isCover,
                page: _page,
                onBack: () => context.pop(),
                onPageDot: _goToPage,
                onMore: (det) => MusicActionMenu.showMoreOptions(context, det),
                onLyricSource: () => _showLyricSourceDialog(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLyricSourceDialog(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final cs = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 32, height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Icon(Icons.lyrics_rounded, color: cs.primary, size: 20),
                const SizedBox(width: 10),
                Text('歌词来源',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ]),
            ),
            const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Icon(Icons.folder_open_rounded, color: cs.onPrimaryContainer),
              ),
              title: const Text('选择本地歌词文件'),
              subtitle: const Text('从设备中选择 .lrc / .ttml 文件'),
              onTap: () { Navigator.pop(sheetCtx); _pickLocalLyricFile(mp, context); },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.secondaryContainer,
                child: Icon(Icons.search_rounded, color: cs.onSecondaryContainer),
              ),
              title: const Text('在线搜索歌词'),
              subtitle: const Text('通过网络匹配当前歌曲的歌词'),
              onTap: () { Navigator.pop(sheetCtx); _searchLyrics(mp, context); },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickLocalLyricFile(MusicProvider mp, BuildContext ctx) async {
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
      if (!ctx.mounted) return;
      mp.setCurrentLrc(content);
      AppToast.success(ctx, message: '本地歌词加载成功');
    } catch (e) {
      if (!ctx.mounted) return;
      AppToast.error(ctx, message: '歌词文件读取失败');
    }
  }

  Future<void> _searchLyrics(MusicProvider mp, BuildContext ctx) async {
    AppToast.neutral(ctx, message: '正在查找中...');
    try {
      final music = mp.currentMusic;
      final result = await MusicApi.searchLyrics(music?.artist, music?.title);
      if (!ctx.mounted) return;
      if (!result.$2) { AppToast.neutral(ctx, message: '暂未找到歌词'); return; }
      mp.setCurrentLrc(result.$1);
      AppToast.neutral(ctx, message: '歌词获取成功');
    } catch (e) {
      AppToast.error(context, message: '歌词获取失败');
    }
  }
}

// ── 顶部操作栏 ──
class _TopBar extends StatelessWidget {
  final bool isCover;
  final int page;
  final VoidCallback onBack;
  final void Function(int) onPageDot;
  final void Function(TapDownDetails) onMore;
  final VoidCallback onLyricSource;

  const _TopBar({
    required this.isCover,
    required this.page,
    required this.onBack,
    required this.onPageDot,
    required this.onMore,
    required this.onLyricSource,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 52,
      child: Row(children: [
        // 返回
        IconButton(
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurface),
          onPressed: onBack,
        ),
        const Spacer(),
        // 页面指示点
        _PageDots(page: page, onTap: onPageDot),
        const Spacer(),
        // 右侧按钮
        if (isCover)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: onMore,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.more_vert_rounded, color: cs.onSurface),
            ),
          )
        else
          IconButton(
            onPressed: onLyricSource,
            icon: Icon(Icons.lyrics_rounded, color: cs.primary),
          ),
      ]),
    );
  }
}

class _PageDots extends StatelessWidget {
  final int page;
  final void Function(int) onTap;
  const _PageDots({required this.page, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(2, (i) {
        final sel = page == i;
        return GestureDetector(
          onTap: () => onTap(i),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: sel ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: sel
                    ? cs.primary
                    : cs.onSurfaceVariant.withValues(alpha: 0.28),
              ),
            ),
          ),
        );
      }),
    );
  }
}
