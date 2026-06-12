import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
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
        return SingleChildScrollView(
          // 确保内容不满一屏时，也能撑开到最大高度
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                // 核心：让所有子组件在垂直方向上均匀居中分布
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. 封面
                  _AlbumArt(music: music),

                  // 如果空间足够，可以换成 Spacer() 或者弹性间距，空间不够时用固定的
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
  const _AlbumArt({required this.music});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth * 0.72).clamp(200.0, 320.0);

        return Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildAlbumArt(music, musicProvider, cs, size),

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
        );
      },
    );
  }

  Widget _buildAlbumArt(
    Music music,
    MusicProvider mp,
    ColorScheme cs,
    double size,
  ) {
    // 内存图片优先
    if (music.coverBytes?.isNotEmpty == true) {
      return Image.memory(music.coverBytes!, fit: BoxFit.cover);
    }

    // 网络图片
    final coverUrl = mp.getCoverUrl(music.id);
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: coverUrl,
        fit: BoxFit.cover,
        httpHeaders: coverUrl.contains('music.126.net')
            ? {'Referer': 'https://music.163.com/'}
            : null,
        placeholder: (_, _) => _placeholder(cs, size),
        errorWidget: (_, _, _) => _placeholder(cs, size),
      );
    }

    // 兜底
    return _placeholder(cs, size);
  }

  Widget _placeholder(ColorScheme cs, double size) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.35,
        color: cs.primary.withValues(alpha: 0.6),
      ),
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
          IconButton(
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            icon: Icon(Icons.playlist_play_rounded, color: cs.onSurface),
          ),
          IconButton(
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
                color: isLiked ? Colors.redAccent : cs.onSurface,
                size: 28,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                MusicActionMenu.showAddToPlaylistSheet(context, music),
            icon: Icon(Icons.add_rounded, color: cs.onSurface),
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

//4. 底部控制（基本保持，但更简洁）
class _BottomPlaybackControls extends StatelessWidget {
  const _BottomPlaybackControls({super.key});

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
            IconButton(
              onPressed: mp.playPrev,
              icon: Icon(
                Icons.skip_previous_rounded,
                size: 36,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: mp.togglePlay,
                    iconSize: 48,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        key: ValueKey(playing),
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (isLoading)
                    const CircularProgressIndicator(strokeWidth: 3),
                ],
              ),
            ),
            const SizedBox(width: 20),
            IconButton(
              onPressed: mp.playNext,
              icon: Icon(
                Icons.skip_next_rounded,
                size: 36,
                color: cs.onSurface,
              ),
            ),
          ],
        );
      },
    );
  }
}
