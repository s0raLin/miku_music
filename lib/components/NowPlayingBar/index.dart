import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────
// now_playing_bar.dart
// ─────────────────────────────────────────────────────────────

class NowPlayingBar extends StatelessWidget {
  static const double _breakpoint    = 520.0;
  static const double _progressWidth = 280.0;

  // final VoidCallback onTap;
  // final VoidCallback onNext;
  // final VoidCallback onPrevious;
  // final VoidCallback onQueue;

  const NowPlayingBar({
    super.key,
    // required this.onTap,
    // required this.onNext,
    // required this.onPrevious,
    // required this.onQueue,
  });

  static String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    // 变化少 → select 精准监听
    final music    = context.select<MusicProvider, MusicInfo?>((p) => p.currentMusic);
    final playMode = context.select<MusicProvider, PlayMode>((p) => p.playMode);

    if (music == null) return const SizedBox.shrink();

    final mp          = context.read<MusicProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        // 进度 + 播放状态 → 两个 Stream 合并，只重建内部
        child: StreamBuilder<PositionData>(
          stream: mp.positionDataStream,
          builder: (context, posSnap) {
            final pos = posSnap.data ?? PositionData(Duration.zero, Duration.zero, Duration.zero);

            return StreamBuilder<bool>(
              stream: mp.player.playingStream,
              builder: (context, playSnap) {
                final isPlaying = playSnap.data ?? false;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= _breakpoint;

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // 左：封面 + 歌名
                        Positioned(
                          left: 0, top: 0, bottom: 0,
                          right: wide ? _breakpoint / 2 : 80,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _LeftSection(music: music, colorScheme: colorScheme),
                          ),
                        ),

                        // 中：控制 + 进度（宽屏专属）
                        if (wide)
                          _CenterSection(
                            music:      music,
                            isPlaying:  isPlaying,
                            playMode:   playMode,
                            position:   pos.position,
                            duration:   pos.duration,
                            colorScheme: colorScheme,
                            progressWidth: _progressWidth,
                            fmt:        _fmt,
                            onPlayPause:      mp.togglePlay,
                            onNext:           () {},
                            onPrevious:       () {},
                            onTogglePlayMode: mp.togglePlayMode,
                            onSeek: (v) => mp.player.seek(pos.duration * v),
                          ),

                        // 右：窄屏播放键 + 队列
                        Positioned(
                          right: 0, top: 0, bottom: 0,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _RightSection(
                              isPlaying:           isPlaying,
                              showCompactControls: !wide,
                              colorScheme:         colorScheme,
                              onPlayPause:         mp.togglePlay,
                              onQueue:             () {},
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ─── 左区域 ───────────────────────────────────────────────────

class _LeftSection extends StatelessWidget {
  final MusicInfo   music;
  final ColorScheme colorScheme;

  const _LeftSection({required this.music, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AlbumArt(coverBytes: music.coverBytes),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                music.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                music.artist,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── 中间区域 ─────────────────────────────────────────────────

class _CenterSection extends StatelessWidget {
  final MusicInfo   music;
  final bool        isPlaying;
  final PlayMode    playMode;
  final Duration    position;
  final Duration    duration;
  final ColorScheme colorScheme;
  final double      progressWidth;
  final String Function(Duration) fmt;
  final VoidCallback        onPlayPause;
  final VoidCallback        onNext;
  final VoidCallback        onPrevious;
  final VoidCallback        onTogglePlayMode;
  final ValueChanged<double> onSeek;

  const _CenterSection({
    required this.music,
    required this.isPlaying,
    required this.playMode,
    required this.position,
    required this.duration,
    required this.colorScheme,
    required this.progressWidth,
    required this.fmt,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onTogglePlayMode,
    required this.onSeek,
  });

  double get _progress {
    if (duration.inMicroseconds == 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlsRow(
          isPlaying:        isPlaying,
          playMode:         playMode,
          colorScheme:      colorScheme,
          onPlayPause:      onPlayPause,
          onNext:           onNext,
          onPrevious:       onPrevious,
          onTogglePlayMode: onTogglePlayMode,
        ),
        _ProgressRow(
          progress:  _progress,
          position:  position,
          duration:  duration,
          colorScheme: colorScheme,
          width:     progressWidth,
          fmt:       fmt,
          onChanged: onSeek,
        ),
      ],
    );
  }
}

class _ControlsRow extends StatelessWidget {
  final bool        isPlaying;
  final PlayMode    playMode;
  final ColorScheme colorScheme;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayMode;

  const _ControlsRow({
    required this.isPlaying,
    required this.playMode,
    required this.colorScheme,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onTogglePlayMode,
  });

  @override
  Widget build(BuildContext context) {
    final isShuffle = playMode == PlayMode.shuffle;
    const btnSize   = BoxConstraints(maxHeight: 32, minWidth: 32);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTogglePlayMode,
          constraints: btnSize,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          tooltip: isShuffle ? '切换为顺序播放' : '开启随机播放',
          icon: Icon(
            isShuffle ? Icons.sort_rounded : Icons.shuffle_rounded,
            size: 20,
            color: isShuffle ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
        IconButton(
          onPressed: onPrevious,
          constraints: btnSize,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          tooltip: '上一首',
          icon: Icon(Icons.skip_previous_rounded, size: 24, color: colorScheme.onSurface),
        ),
        IconButton(
          onPressed: onPlayPause,
          constraints: const BoxConstraints(maxHeight: 36, minWidth: 36),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          tooltip: isPlaying ? '暂停' : '播放',
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 32,
            color: colorScheme.primary,
          ),
        ),
        IconButton(
          onPressed: onNext,
          constraints: btnSize,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          tooltip: '下一首',
          icon: Icon(Icons.skip_next_rounded, size: 24, color: colorScheme.onSurface),
        ),
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  final double   progress;
  final Duration position;
  final Duration duration;
  final ColorScheme colorScheme;
  final double   width;
  final String Function(Duration) fmt;
  final ValueChanged<double> onChanged;

  const _ProgressRow({
    required this.progress,
    required this.position,
    required this.duration,
    required this.colorScheme,
    required this.width,
    required this.fmt,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final timeStyle = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
    );

    return SizedBox(
      width: width,
      child: Row(
        children: [
          Text(fmt(position), style: timeStyle),   // 左：当前时间
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,   // 足够触摸区域
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight:  12.0,
                  trackShape:   const RoundedRectSliderTrackShape(),
                  thumbShape:   const RoundSliderThumbShape(
                    enabledThumbRadius: 0,
                    elevation: 0,
                    pressedElevation: 0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor:   colorScheme.primary,
                  inactiveTrackColor: colorScheme.primary.withOpacity(0.12),
                  overlayColor:       colorScheme.primary.withOpacity(0.1),
                ),
                child: Slider(value: progress, onChanged: onChanged),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(fmt(duration), style: timeStyle),   // 右：总时长
        ],
      ),
    );
  }
}

// ─── 右区域 ───────────────────────────────────────────────────

class _RightSection extends StatelessWidget {
  final bool        isPlaying;
  final bool        showCompactControls;
  final ColorScheme colorScheme;
  final VoidCallback onPlayPause;
  final VoidCallback onQueue;

  const _RightSection({
    required this.isPlaying,
    required this.showCompactControls,
    required this.colorScheme,
    required this.onPlayPause,
    required this.onQueue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCompactControls)
          IconButton(
            onPressed: onPlayPause,
            constraints: const BoxConstraints(maxHeight: 36, minWidth: 36),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 28,
              color: colorScheme.primary,
            ),
          ),
        IconButton(
          onPressed: onQueue,
          constraints: const BoxConstraints(maxHeight: 32, minWidth: 32),
          padding: EdgeInsets.zero,
          color: colorScheme.onSurfaceVariant,
          visualDensity: VisualDensity.compact,
          tooltip: '播放队列',
          icon: const Icon(Icons.queue_music_rounded, size: 24),
        ),
      ],
    );
  }
}

// ─── 封面 ─────────────────────────────────────────────────────

class _AlbumArt extends StatelessWidget {
  final Uint8List? coverBytes;
  const _AlbumArt({this.coverBytes});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: coverBytes != null
          ? Image.memory(
              coverBytes!,
              width: 44, height: 44, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _FallbackArt(),
            )
          : const _FallbackArt(),
    );
  }
}

class _FallbackArt extends StatelessWidget {
  const _FallbackArt();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.music_note_rounded, size: 24, color: cs.onSurfaceVariant),
    );
  }
}
