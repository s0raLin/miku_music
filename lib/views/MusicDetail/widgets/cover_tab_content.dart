import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';
import 'package:provider/provider.dart';

class CoverTabContent extends StatefulWidget {
  final Music music;

  const CoverTabContent({super.key, required this.music});

  @override
  State<CoverTabContent> createState() => _CoverTabContentState();
}

class _CoverTabContentState extends State<CoverTabContent> {
  double? _draggingValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString();
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

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
        )
        .any((m) => m.id == widget.music.id);

    return Column(
      mainAxisSize: MainAxisSize.min, // 紧凑打包子组件
      mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
      children: [
        // 1. 封面区域（限制最大尺寸，不再用 Expanded 撑满）
        LayoutBuilder(
          builder: (context, constraints) {
            // 限制封面最大为屏幕宽度的 70% 或最大 300，避免过大撑开上下间距
            final size = constraints.maxWidth * 0.7 > 300
                ? 300.0
                : constraints.maxWidth * 0.7;
            return Center(
              child: SizedBox(
                width: size,
                height: size,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: cs.shadow.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: cs.surfaceContainerHighest,
                      child: widget.music.coverBytes?.isNotEmpty == true
                          ? Image.memory(
                              widget.music.coverBytes!,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.music_note_rounded,
                              size: size * 0.3,
                              color: cs.primary.withValues(alpha: 0.5),
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 12), // 缩减间距
        // 2. 核心快捷操作栏
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40), // 收紧水平宽度
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                icon: Icon(
                  Icons.playlist_play_rounded,
                  size: 24,
                  color: cs.onSurface,
                ),
              ),
              IconButton(
                onPressed: () {
                  final wasLiked = playlistProvider
                      .getPlaylistSongs(
                        PlaylistProvider.favoritesPlaylistId,
                        musicProvider.library,
                      )
                      .any((m) => m.id == widget.music.id);
                  playlistProvider.toggleMusicFavorite(widget.music);
                  AppToast.neutral(
                    context,
                    message: wasLiked ? '已取消收藏' : '已添加到喜欢',
                  );
                },
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey<bool>(isLiked),
                    color: isLiked ? Colors.redAccent : cs.onSurface,
                    size: 24,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  MusicActionMenu.showAddToPlaylistSheet(context, widget.music);
                },
                tooltip: "添加到歌单",
                icon: Icon(Icons.add_rounded, size: 24, color: cs.onSurface),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8), // 缩减间距
        // 3. 进度条 + 时间显示区域
        StreamBuilder<PositionData>(
          stream: musicProvider.positionDataStream,
          builder: (context, snapshot) {
            final data =
                snapshot.data ??
                PositionData(Duration.zero, Duration.zero, Duration.zero);
            final totalMs = data.duration.inMilliseconds.toDouble();
            final currentPosMs = data.position.inMilliseconds.toDouble().clamp(
              0.0,
              totalMs,
            );
            final safeTotal = totalMs > 0 ? totalMs : 1.0;
            final sliderValue = _draggingValue ?? currentPosMs;
            final isWaving =
                musicProvider.player.playing && _draggingValue == null;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: useWave
                      ? WavySlider(
                          value: sliderValue.clamp(0.0, safeTotal),
                          max: safeTotal,
                          isWaving: isWaving,
                          onChanged: (v) => setState(() => _draggingValue = v),
                          onChangeEnd: (v) async {
                            await musicProvider.player.seek(
                              Duration(milliseconds: v.toInt()),
                            );
                            setState(() => _draggingValue = null);
                          },
                        )
                      : StraightSlider(
                          value: sliderValue.clamp(0.0, safeTotal),
                          max: safeTotal,
                          onChanged: (v) => setState(() => _draggingValue = v),
                          onChangeEnd: (v) async {
                            await musicProvider.player.seek(
                              Duration(milliseconds: v.toInt()),
                            );
                            setState(() => _draggingValue = null);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _draggingValue != null
                            ? _formatDuration(
                                Duration(milliseconds: _draggingValue!.toInt()),
                              )
                            : _formatDuration(data.position),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _formatDuration(data.duration),
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
        ),

        const SizedBox(height: 12), // 缩减间距
        // 4. 底部播放控制键
        _BottomPlaybackControls(mp: musicProvider),
      ],
    );
  }
}

// 底部按键也适当收紧了间距
class _BottomPlaybackControls extends StatelessWidget {
  final MusicProvider mp;
  const _BottomPlaybackControls({required this.mp});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<ProcessingState>(
      stream: mp.player.processingStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? ProcessingState.idle;
        final playing = mp.player.playing;
        final isLoading =
            state == ProcessingState.loading ||
            state == ProcessingState.buffering;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: mp.playPrev,
              icon: Icon(
                Icons.skip_previous_rounded,
                size: 32,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 24), // 缩小按钮间距
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: mp.togglePlay,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey<bool>(playing),
                        size: 36,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (isLoading)
                    IgnorePointer(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 24), // 缩小按钮间距
            IconButton(
              onPressed: mp.playNext,
              icon: Icon(
                Icons.skip_next_rounded,
                size: 32,
                color: cs.onSurface,
              ),
            ),
          ],
        );
      },
    );
  }
}
