import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/api/Client/Music/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/views/MusicDetail/widgets/lyrics_section.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';
import 'package:myapp/views/MusicDetail/widgets/playback_queue_drawer.dart';
import 'package:provider/provider.dart';

// ─── 手机横屏布局 ──────────────────────────────────────────────────────────
//  横屏时可用高度有限：左侧紧凑封面 + 信息，右侧歌词 + 底部控制条。
//  顶部操作栏为沉浸式：空闲数秒后自动隐藏，点击内容任意处重新呼出；
//  操作栏本身仅由实际按钮构成（与竖屏一致的 ImmersiveTopBar），
//  不拦截其余区域点击，避免误触。

class LandscapeLayout extends StatefulWidget {
  final Music music;
  const LandscapeLayout({super.key, required this.music});

  @override
  State<LandscapeLayout> createState() => _LandscapeLayoutState();
}

class _LandscapeLayoutState extends State<LandscapeLayout> {
  bool _topBarVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _topBarVisible = false);
    });
  }

  void _revealTopBar() {
    if (!_topBarVisible) setState(() => _topBarVisible = true);
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: PlaybackQueueDrawer(),
      body: BlurCoverBackground(
        music: widget.music,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              // 点击任何空白区域都能呼出操作栏
              if (!_topBarVisible) {
                _revealTopBar();
              }
            },
            child: Stack(
              children: [
                // 主内容
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final lyricsWidth = (constraints.maxWidth * 0.42).clamp(
                        240.0,
                        480.0,
                      );
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _CoverAndMeta(
                              music: widget.music,
                              topBarVisible: _topBarVisible,
                              onRevealTopBar: _revealTopBar,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: lyricsWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    clipBehavior: Clip.hardEdge,
                                    borderRadius: AppRadius.cardBR,
                                    child: const LyricsSection(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const _LandscapeControls(),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // 顶部操作栏
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _topBarVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !_topBarVisible,
                      child: ImmersiveTopBar(
                        onBack: () => context.pop(),
                        actions: [
                          ImmersiveIconButton(
                            onPressed: (_) => _showLyricSourceDialog(context),
                            icon: Icons.lyrics_rounded,
                            tooltip: '歌词来源',
                            color: cs.primary,
                          ),
                          const _MoreMenuButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

class _CoverAndMeta extends StatefulWidget {
  final Music music;
  final bool topBarVisible;
  final VoidCallback onRevealTopBar;
  const _CoverAndMeta({
    required this.music,
    required this.topBarVisible,
    required this.onRevealTopBar,
  });

  @override
  State<_CoverAndMeta> createState() => _CoverAndMetaState();
}

class _CoverAndMetaState extends State<_CoverAndMeta> {
  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final useWave = themeProvider.sliderStyle == SliderStyle.wave;

    final isLiked = playlistProvider
        .getPlaylistSongs(
          PlaylistProvider.favoritesPlaylistId,
          musicProvider.library,
          musicProvider: musicProvider,
        )
        .any((m) => m.id == widget.music.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final coverSize = (constraints.maxHeight * 0.62)
            .clamp(80.0, constraints.maxWidth * 0.9)
            .clamp(80.0, 360.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 封面 + 快捷操作：在进度条上方剩余区域内居中
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 封面：操作栏可见时进入封面轮播；隐藏时点击先呼出操作栏
                    GestureDetector(
                      onTap: () {
                        if (widget.topBarVisible) {
                          context.push('/cover-flow');
                        } else {
                          widget.onRevealTopBar();
                        }
                      },
                      child: ClipRRect(
                        borderRadius: AppRadius.cardBR,
                        child: Container(
                          width: coverSize,
                          height: coverSize,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: cs.shadow.withValues(alpha: 0.18),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: AlbumArtImage(
                            music: widget.music,
                            size: coverSize,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 快捷操作（队列 / 添加到歌单 / 收藏）
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        IconButton.filledTonal(
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.queue_music_rounded,
                            color: cs.onSecondaryContainer,
                          ),
                          tooltip: '播放队列',
                        ),
                        IconButton.filledTonal(
                          onPressed: () =>
                              MusicActionMenu.showAddToPlaylistSheet(
                                context,
                                widget.music,
                              ),
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.add_rounded,
                            color: cs.onSecondaryContainer,
                          ),
                          tooltip: '添加到歌单',
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            final wasLiked = isLiked;
                            playlistProvider.toggleMusicFavorite(
                              widget.music,
                              musicProvider: musicProvider,
                            );
                            AppToast.neutral(
                              context,
                              message: wasLiked ? '已取消收藏' : '已添加到喜欢',
                            );
                          },
                          visualDensity: VisualDensity.compact,
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (child, anim) =>
                                ScaleTransition(scale: anim, child: child),
                            child: Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              key: ValueKey<bool>(isLiked),
                              color: isLiked
                                  ? Colors.redAccent
                                  : cs.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 进度条 + 时长指示器：底部对齐，与右侧控制栏底对齐
            _LandscapeProgress(music: widget.music, useWave: useWave),
          ],
        );
      },
    );
  }
}

class _LandscapeProgress extends StatefulWidget {
  final Music music;
  final bool useWave;
  const _LandscapeProgress({required this.music, required this.useWave});

  @override
  State<_LandscapeProgress> createState() => _LandscapeProgressState();
}

class _LandscapeProgressState extends State<_LandscapeProgress> {
  double? _draggingValue;

  String _format(Duration d) {
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<PositionData>(
      stream: mp.positionDataStream,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            PositionData(Duration.zero, Duration.zero, Duration.zero);
        final totalMs = data.duration.inMilliseconds.toDouble();
        final currentMs = data.position.inMilliseconds.toDouble().clamp(
          0.0,
          totalMs,
        );
        final safeTotal = totalMs > 0 ? totalMs : 1.0;
        final value = _draggingValue ?? currentMs;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: widget.useWave
                  ? WavySlider(
                      value: value.clamp(0.0, safeTotal),
                      max: safeTotal,
                      isWaving: mp.player.playing && _draggingValue == null,
                      onChanged: (v) => setState(() => _draggingValue = v),
                      onChangeEnd: (v) async {
                        await mp.player.seek(Duration(milliseconds: v.toInt()));
                        setState(() => _draggingValue = null);
                      },
                    )
                  : StraightSlider(
                      value: value.clamp(0.0, safeTotal),
                      max: safeTotal,
                      onChanged: (v) => setState(() => _draggingValue = v),
                      onChangeEnd: (v) async {
                        await mp.player.seek(Duration(milliseconds: v.toInt()));
                        setState(() => _draggingValue = null);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _format(
                      _draggingValue != null
                          ? Duration(milliseconds: _draggingValue!.toInt())
                          : data.position,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _format(data.duration),
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── 底部控制条（置于歌词区底部）：播放模式 / 上一首 / 播放暂停 / 下一首 ──
class _LandscapeControls extends StatelessWidget {
  const _LandscapeControls();

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    IconData modeIcon(PlayMode mode) => switch (mode) {
      PlayMode.sequence => Icons.repeat_rounded,
      PlayMode.shuffle => Icons.shuffle_rounded,
      PlayMode.repeat => Icons.repeat_one_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppRadius.cardBR,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _Ctrl(
            onPressed: mp.togglePlayMode,
            tooltip: switch (mp.playMode) {
              PlayMode.sequence => '顺序播放',
              PlayMode.shuffle => '随机播放',
              PlayMode.repeat => '单曲循环',
            },
            child: Icon(modeIcon(mp.playMode), color: cs.onSecondaryContainer),
          ),
          _Ctrl(
            onPressed: mp.playPrev,
            tooltip: '上一首',
            child: Icon(
              Icons.skip_previous_rounded,
              color: cs.onSecondaryContainer,
            ),
          ),
          SizedBox(
            width: 52,
            height: 52,
            child: StreamBuilder<ProcessingState>(
              stream: mp.player.processingStateStream,
              builder: (context, snapshot) {
                final state = snapshot.data ?? ProcessingState.idle;
                final isLoading =
                    state == ProcessingState.loading ||
                    state == ProcessingState.buffering;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    FilledButton(
                      onPressed: mp.togglePlay,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          mp.player.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          key: ValueKey(mp.player.playing),
                          size: 28,
                        ),
                      ),
                    ),
                    if (isLoading)
                      const Positioned.fill(
                        child: IgnorePointer(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _Ctrl(
            onPressed: mp.playNext,
            tooltip: '下一首',
            child: Icon(
              Icons.skip_next_rounded,
              color: cs.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _Ctrl extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final Widget child;
  const _Ctrl({
    required this.onPressed,
    required this.tooltip,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: cs.secondaryContainer,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(width: 40, height: 40, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _MoreMenuButton extends StatelessWidget {
  const _MoreMenuButton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopupMenuButton<_MoreMenuItem>(
      tooltip: '更多',
      icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.innerBR),
      elevation: 6,
      onSelected: (item) {
        switch (item) {
          case _MoreMenuItem.sliderStyle:
            _showProgressBarStylesMenu(context);
            break;
          case _MoreMenuItem.songInfo:
            AppToast.neutral(context, message: "暂无歌曲详细信息");
            break;
        }
      },
      itemBuilder: (context) => [
        _MenuItem(
          value: _MoreMenuItem.sliderStyle,
          icon: Icons.timeline_rounded,
          label: '设置进度条样式',
          trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        ),
        _MenuItem(
          value: _MoreMenuItem.songInfo,
          icon: Icons.info_outline_rounded,
          label: '歌曲信息',
        ),
      ],
    );
  }

  void _showProgressBarStylesMenu(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final currentStyle = themeProvider.sliderStyle;
    final RenderBox? button = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<SliderStyle>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.innerBR),
      elevation: 6,
      items: [
        _MenuItem(
          value: SliderStyle.straight,
          icon: Icons.show_chart_rounded,
          label: '标准直线',
          selected: currentStyle == SliderStyle.straight,
        ),
        _MenuItem(
          value: SliderStyle.wave,
          icon: Icons.waves_rounded,
          label: '波浪',
          selected: currentStyle == SliderStyle.wave,
        ),
      ],
    ).then((style) {
      if (style == null) return;
      themeProvider.setSliderStyle(style);
      if (context.mounted) {
        AppToast.neutral(
          context,
          message: style == SliderStyle.wave ? "已切换为波浪" : "已切换为标准直线",
        );
      }
    });
  }
}

/// 带图标 / 选中态的菜单项，避免纯文字样式
class _MenuItem<T> extends PopupMenuItem<T> {
  _MenuItem({
    required IconData icon,
    required String label,
    bool selected = false,
    Widget? trailing,
    super.key,
    super.value,
  }) : super(
         height: 44,
         child: Builder(
           builder: (context) {
             final cs = Theme.of(context).colorScheme;
             final color = selected ? cs.primary : cs.onSurface;
             return Row(
               children: [
                 Icon(icon, size: 20, color: color),
                 const SizedBox(width: 12),
                 Expanded(
                   child: Text(
                     label,
                     style: TextStyle(
                       color: color,
                       fontWeight: selected ? FontWeight.w600 : null,
                     ),
                   ),
                 ),
                  if (selected)
                    Icon(Icons.check_rounded, size: 18, color: cs.primary)
                  else if (trailing != null) ...[
                    trailing,
                  ],
               ],
             );
           },
         ),
       );
}

enum _MoreMenuItem { sliderStyle, songInfo }
