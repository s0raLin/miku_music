import 'package:flutter/material.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

enum PlayMode { sequence, shuffle }

class NowPlayingInfo {
  final String title;
  final String artist;
  final String? coverUrl;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final PlayMode playMode;

  const NowPlayingInfo({
    required this.title,
    required this.artist,
    this.coverUrl,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.playMode = PlayMode.sequence,
  });

  NowPlayingInfo copyWith({
    String? title,
    String? artist,
    String? coverUrl,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    PlayMode? playMode,
  }) {
    return NowPlayingInfo(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      coverUrl: coverUrl ?? this.coverUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      playMode: playMode ?? this.playMode,
    );
  }

  double get progress {
    if (duration.inSeconds == 0) return 0.0;
    return (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0);
  }
}

// ─── Main Widget ──────────────────────────────────────────────────────────────

class NowPlayingBar extends StatefulWidget {
  final String songId;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onQueue;

  const NowPlayingBar({
    super.key,
    required this.onTap,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onQueue,
    required this.songId,
  });

  @override
  State<NowPlayingBar> createState() => _NowPlayingBarState();
}

class _NowPlayingBarState extends State<NowPlayingBar> {
  static const double _centerSectionBreakpoint = 520.0;
  static const double _progressBarWidth = 280.0;

  late NowPlayingInfo info;

  @override
  void initState() {
    super.initState();
    info = const NowPlayingInfo(
      title: '夜曲',
      artist: '周杰伦',
      isPlaying: true,
      position: Duration(seconds: 98),
      duration: Duration(minutes: 4, seconds: 12),
    );
  }

  void _togglePlayMode() {
    setState(() {
      info = info.copyWith(
        playMode: info.playMode == PlayMode.sequence
            ? PlayMode.shuffle
            : PlayMode.sequence,
      );
    });
  }

  static String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(d.inMinutes.remainder(60))}:${twoDigits(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showCenter = constraints.maxWidth >= _centerSectionBreakpoint;

            return Stack(
              alignment: Alignment.center,
              children: [
                // ── 左：靠左对齐，封面 + 歌曲信息 ────────────────────────
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  // 右边界留出中间区域的一半宽度，防止文字钻到中间区域下面
                  right: showCenter ? _centerSectionBreakpoint / 2 : 80,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _LeftSection(
                      info: info,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),

                // ── 中：绝对居中，控制按钮 + 进度条 ──────────────────────
                if (showCenter)
                  _CenterSection(
                    info: info,
                    colorScheme: colorScheme,
                    progressBarWidth: _progressBarWidth,
                    formatDuration: _formatDuration,
                    onPlayPause: widget.onPlayPause,
                    onNext: widget.onNext,
                    onPrevious: widget.onPrevious,
                    onTogglePlayMode: _togglePlayMode,
                    onSeek: (value) {
                      // TODO: audioPlayer.seek(...)
                    },
                  ),

                // ── 右：靠右对齐，歌单按钮 ────────────────────────────────
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _RightSection(
                      colorScheme: colorScheme,
                      showCompactControls: !showCenter,
                      info: info,
                      onPlayPause: widget.onPlayPause,
                      onQueue: widget.onQueue,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── 左区域：封面 + 歌曲信息 ──────────────────────────────────────────────────

class _LeftSection extends StatelessWidget {
  final NowPlayingInfo info;
  final ColorScheme colorScheme;

  const _LeftSection({required this.info, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AlbumArt(coverUrl: info.coverUrl),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                info.artist,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
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

// ─── 中间区域：固定宽度，控制按钮行 + 进度条行 ───────────────────────────────

class _CenterSection extends StatelessWidget {
  final NowPlayingInfo info;
  final ColorScheme colorScheme;
  final double progressBarWidth;
  final String Function(Duration) formatDuration;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayMode;
  final ValueChanged<double> onSeek;

  const _CenterSection({
    required this.info,
    required this.colorScheme,
    required this.progressBarWidth,
    required this.formatDuration,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onTogglePlayMode,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlsRow(
          info: info,
          colorScheme: colorScheme,
          onPlayPause: onPlayPause,
          onNext: onNext,
          onPrevious: onPrevious,
          onTogglePlayMode: onTogglePlayMode,
        ),
        _ProgressRow(
          info: info,
          colorScheme: colorScheme,
          width: progressBarWidth,
          formatDuration: formatDuration,
          onChanged: onSeek,
        ),
      ],
    );
  }
}

class _ControlsRow extends StatelessWidget {
  final NowPlayingInfo info;
  final ColorScheme colorScheme;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onTogglePlayMode;

  const _ControlsRow({
    required this.info,
    required this.colorScheme,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onTogglePlayMode,
  });

  @override
  Widget build(BuildContext context) {
    final isShuffle = info.playMode == PlayMode.shuffle;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onTogglePlayMode,
          constraints: const BoxConstraints(maxHeight: 32, minWidth: 32),
          padding: EdgeInsets.zero,
          icon: Icon(
            isShuffle ? Icons.sort_rounded : Icons.shuffle_rounded,
            size: 20,
            color: isShuffle
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          visualDensity: VisualDensity.compact,
          tooltip: isShuffle ? '切换为顺序播放' : '开启随机播放',
        ),
        IconButton(
          onPressed: onPrevious,
          constraints: const BoxConstraints(maxHeight: 32, minWidth: 32),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.skip_previous_rounded,
            size: 24,
            color: colorScheme.onSurface,
          ),
          visualDensity: VisualDensity.compact,
          tooltip: '上一首',
        ),
        IconButton(
          onPressed: onPlayPause,
          constraints: const BoxConstraints(maxHeight: 36, minWidth: 36),
          padding: EdgeInsets.zero,
          icon: Icon(
            info.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            size: 32,
            color: colorScheme.primary,
          ),
          visualDensity: VisualDensity.compact,
          tooltip: info.isPlaying ? '暂停' : '播放',
        ),
        IconButton(
          onPressed: onNext,
          constraints: const BoxConstraints(maxHeight: 32, minWidth: 32),
          padding: EdgeInsets.zero,
          icon: Icon(
            Icons.skip_next_rounded,
            size: 24,
            color: colorScheme.onSurface,
          ),
          visualDensity: VisualDensity.compact,
          tooltip: '下一首',
        ),
      ],
    );
  }
}
class _ProgressRow extends StatelessWidget {
  final NowPlayingInfo info;
  final ColorScheme colorScheme;
  final double width;
  final String Function(Duration) formatDuration;
  final ValueChanged<double> onChanged;

  const _ProgressRow({
    required this.info,
    required this.colorScheme,
    required this.width,
    required this.formatDuration,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        children: [
          Text(
            formatDuration(info.position),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 20, // 稍微压缩容器高度
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  // Android 16 风格核心配置
                  trackHeight: 12.0, // 加粗轨道
                  trackShape: const RoundedRectSliderTrackShape(),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 0, // 隐藏圆形滑块点，使其像一个填充条
                    elevation: 0,
                    pressedElevation: 0,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16, // 点击时的光晕范围
                  ),
                  // 颜色适配
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: colorScheme.primary.withOpacity(0.12),
                  overlayColor: colorScheme.primary.withOpacity(0.1),
                ),
                child: Slider(
                  value: info.progress,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatDuration(info.duration),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 右区域：歌单按钮（窄屏时仅附带播放/暂停）────────────────────────────────

class _RightSection extends StatelessWidget {
  final ColorScheme colorScheme;
  final bool showCompactControls;
  final NowPlayingInfo info;
  final VoidCallback onPlayPause;
  final VoidCallback onQueue;

  const _RightSection({
    required this.colorScheme,
    required this.showCompactControls,
    required this.info,
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
            icon: Icon(
              info.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 28,
              color: colorScheme.primary,
            ),
            visualDensity: VisualDensity.compact,
          ),
        IconButton(
          onPressed: onQueue,
          constraints: const BoxConstraints(maxHeight: 32, minWidth: 32),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.queue_music_rounded, size: 24),
          color: colorScheme.onSurfaceVariant,
          visualDensity: VisualDensity.compact,
          tooltip: '播放队列',
        ),
      ],
    );
  }
}

// ─── 封面 Sub-widgets ─────────────────────────────────────────────────────────

class _AlbumArt extends StatelessWidget {
  final String? coverUrl;
  const _AlbumArt({this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: coverUrl != null
          ? Image.network(
              coverUrl!,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
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
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: 24,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
