import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:myapp/views/MusicDetail/widgets/music_action_menu.dart';
import 'package:provider/provider.dart';

class CoverTabContent extends StatelessWidget {
  final Music music;
  const CoverTabContent({super.key, required this.music});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final useWave = themeProvider.sliderStyle == SliderStyle.wave;

    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : double.infinity;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: SizedBox(
              height: minHeight == double.infinity ? null : minHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. 封面 (with CoverFlow tap)
                  _AlbumArt(
                    music: music,
                    onTapCoverFlow: () => context.push('/cover-flow'),
                  ),

                  const SizedBox(height: 24),

                  // 2. 快捷操作栏
                  _ActionBar(music: music),

                  const SizedBox(height: 16),

                  // 3. 进度条 + 时间
                  _ProgressSection(music: music, useWave: useWave),

                  const SizedBox(height: 24),

                  // 4. 底部控制
                  _BottomPlaybackControls(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

//1. 封面组件（独立提取）
class _AlbumArt extends StatelessWidget {
  final Music music;
  final VoidCallback onTapCoverFlow;
  const _AlbumArt({required this.music, required this.onTapCoverFlow});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth * 0.72).clamp(200.0, 320.0);

        return GestureDetector(
          onTap: onTapCoverFlow,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: AppRadius.cardBR,
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.18),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: AppRadius.cardBR,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AlbumArtImage(music: music, size: size),

                    // 网络标识
                    if (music.source == MusicSource.network)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: _NetworkBadge(cs: cs),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NetworkBadge extends StatelessWidget {
  final ColorScheme cs;
  const _NetworkBadge({required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_rounded, size: 15, color: cs.onPrimary),
          const SizedBox(width: 5),
          Text(
            '网络',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: cs.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

//2. 操作栏
class _ActionBar extends StatelessWidget {
  final Music music;
  const _ActionBar({required this.music});

  @override
  Widget build(BuildContext context) {
    final playlistProvider = context.watch<PlaylistProvider>();
    final musicProvider = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    final isLiked = playlistProvider
        .getPlaylistSongs(
          PlaylistProvider.favoritesPlaylistId,
          musicProvider.library,
          musicProvider: musicProvider,
        )
        .any((m) => m.id == music.id);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            icon: Icon(Icons.playlist_play_rounded, color: cs.onSecondaryContainer),
          ),
          IconButton.filledTonal(
            onPressed: () {
              final wasLiked = isLiked;
              playlistProvider.toggleMusicFavorite(
                music,
                musicProvider: musicProvider,
              );
              AppToast.neutral(context, message: wasLiked ? '已取消收藏' : '已添加到喜欢');
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                key: ValueKey<bool>(isLiked),
                color: isLiked ? Colors.redAccent : cs.onSecondaryContainer,
                size: 28,
              ),
            ),
          ),
          IconButton.filledTonal(
            onPressed: () =>
                MusicActionMenu.showAddToPlaylistSheet(context, music),
            icon: Icon(Icons.add_rounded, color: cs.onSecondaryContainer),
            tooltip: '添加到歌单',
          ),
        ],
      ),
    );
  }
}

//3. 进度条区域（独立管理拖拽状态）
class _ProgressSection extends StatefulWidget {
  final Music music;
  final bool useWave;
  const _ProgressSection({required this.music, required this.useWave});

  @override
  State<_ProgressSection> createState() => _ProgressSectionState();
}

class _ProgressSectionState extends State<_ProgressSection> {
  double? _draggingValue;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString();
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<PositionData>(
      stream: musicProvider.positionDataStream,
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

        final sliderValue = _draggingValue ?? currentMs;
        final isWaving = musicProvider.player.playing && _draggingValue == null;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: widget.useWave
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
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _draggingValue != null
                        ? _formatDuration(
                            Duration(milliseconds: _draggingValue!.toInt()),
                          )
                        : _formatDuration(data.position),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    _formatDuration(data.duration),
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
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

//4. 底部控制
class _BottomPlaybackControls extends StatelessWidget {
  const _BottomPlaybackControls();

  @override
  Widget build(BuildContext context) {
    final mp = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<ProcessingState>(
      stream: mp.player.processingStateStream,
      builder: (context, snapshot) {
        final state = snapshot.data ?? ProcessingState.idle;
        final isLoading =
            state == ProcessingState.loading ||
            state == ProcessingState.buffering;
        final playing = mp.player.playing;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filledTonal(
              onPressed: mp.playPrev,
              icon: Icon(
                Icons.skip_previous_rounded,
                size: 32,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton.filled(
                    onPressed: mp.togglePlay,
                    iconSize: 48,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(playing),
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                  if (isLoading)
                    const CircularProgressIndicator(strokeWidth: 3),
                ],
              ),
            ),
            const SizedBox(width: 20),
            IconButton.filledTonal(
              onPressed: mp.playNext,
              icon: Icon(
                Icons.skip_next_rounded,
                size: 32,
                color: cs.onSecondaryContainer,
              ),
            ),
          ],
        );
      },
    );
  }
}
