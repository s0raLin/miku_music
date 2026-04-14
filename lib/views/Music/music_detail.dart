import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';

import 'package:provider/provider.dart';

class MusicDetailPage extends StatefulWidget {
  final MusicInfo? music;

  const MusicDetailPage({super.key, required this.music});

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  bool _isLiked = false;

  // 模拟歌词
  static const List<Map<String, dynamic>> _lyrics = [];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    final music = widget.music;

    // 如果 Provider 还没拿到数据，显示加载中
    if (music == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              '正在播放',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              music.title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: isWide
          ? _WideLayout(
              isLiked: _isLiked,
              lyrics: _lyrics,
              colorScheme: colorScheme,

              onToggleLike: () => setState(() => _isLiked = !_isLiked),

              music: music,
            )
          : _NarrowLayout(
              isLiked: _isLiked,
              lyrics: _lyrics,
              colorScheme: colorScheme,

              onToggleLike: () => setState(() => _isLiked = !_isLiked),

              music: music,
            ),
    );
  }
}

// ─── 窄屏布局 ─────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final MusicInfo music;

  final bool isLiked;
  final List<Map<String, dynamic>> lyrics;
  final ColorScheme colorScheme;

  final VoidCallback onToggleLike;

  const _NarrowLayout({
    required this.isLiked,
    required this.lyrics,
    required this.colorScheme,

    required this.onToggleLike,

    required this.music,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _AlbumCover(
            colorScheme: colorScheme,
            size: 320,
            coverBytes: music.coverBytes,
          ),
          const SizedBox(height: 40),
          _SongMeta(
            isLiked: isLiked,
            colorScheme: colorScheme,
            onToggleLike: onToggleLike,
            music: music,
          ),
          const SizedBox(height: 24),
          _PlayerConsole(music: music),
          const SizedBox(height: 40),
          _LyricsSection(lyrics: lyrics, colorScheme: colorScheme),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── 宽屏布局 ────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final MusicInfo music;

  final bool isLiked;
  final List<Map<String, dynamic>> lyrics;
  final ColorScheme colorScheme;

  final VoidCallback onToggleLike;

  const _WideLayout({
    required this.isLiked,
    required this.lyrics,
    required this.colorScheme,

    required this.onToggleLike,

    required this.music,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _AlbumCover(
                  colorScheme: colorScheme,
                  size: 280,
                  coverBytes: music.coverBytes,
                ),
                const SizedBox(height: 40),
                _SongMeta(
                  isLiked: isLiked,
                  colorScheme: colorScheme,
                  onToggleLike: onToggleLike,
                  music: music,
                ),
                const SizedBox(height: 24),
                _PlayerConsole(music: music),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _LyricsSection(
            lyrics: lyrics,
            colorScheme: colorScheme,
            scrollable: true,
          ),
        ),
      ],
    );
  }
}

// ─── 子组件 ───────────────────────────────────────────────────────────────────

class _AlbumCover extends StatelessWidget {
  final Uint8List? coverBytes;
  final ColorScheme colorScheme;
  final double size;

  const _AlbumCover({
    required this.colorScheme,
    required this.size,
    required this.coverBytes,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = coverBytes != null && coverBytes!.isNotEmpty;
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28), // 现代大圆角
          image: hasImage
              ? DecorationImage(
                  // image: NetworkImage('https://placeholder.com/300'), // 这里可以放真实的封面图
                  image: MemoryImage(coverBytes!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Icon(
          Icons.music_note_rounded,
          color: colorScheme.primary.withOpacity(0.5),
          size: size * 0.3,
        ),
      ),
    );
  }
}

class _SongMeta extends StatelessWidget {
  final MusicInfo music;
  final bool isLiked;
  final ColorScheme colorScheme;
  final VoidCallback onToggleLike;

  const _SongMeta({
    required this.isLiked,
    required this.colorScheme,
    required this.onToggleLike,
    required this.music,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                music.title,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${music.artist} · ${music.album}',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onToggleLike,
          icon: Icon(
            isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: isLiked ? colorScheme.primary : colorScheme.onSurfaceVariant,
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _PlayerConsole extends StatelessWidget {
  final MusicInfo music;
  const _PlayerConsole({required this.music});

  String _formatTime(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final musicProvider = context.watch<MusicProvider>();
    final player = musicProvider.player;

    return StreamBuilder<PositionData>(
      stream: musicProvider.positionDataStream,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            PositionData(Duration.zero, Duration.zero, Duration.zero);

        final position = data.position;
        final duration = data.duration;
        final buffered = data.bufferedPosition;

        //计算进度百分比
        double progress = 0.0;
        double bufferProgress = 0.0;
        if (duration.inMicroseconds > 0) {
          progress = (position.inMilliseconds / duration.inMilliseconds).clamp(
            0.0,
            1.0,
          );

          bufferProgress = (buffered.inMilliseconds / duration.inMilliseconds)
              .clamp(0.0, 1.0);
        }
        return Column(
          children: [
            //进度条(带缓冲条效果)
            Stack(
              alignment: Alignment.center,
              children: [
                //缓冲条背景(浅色)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12,
                    activeTrackColor: colorScheme.primary.withOpacity(
                      0.2,
                    ), // 缓冲部分颜色
                    inactiveTrackColor: colorScheme.primary.withOpacity(
                      0.05,
                    ), // 未缓冲颜色
                    thumbShape: SliderComponentShape.noThumb, // 缓冲条不需要滑块
                  ),
                  child: Slider(value: bufferProgress, onChanged: null),
                ),

                //真实的播放进度条
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 12,
                    activeTrackColor: colorScheme.primary,
                    inactiveTrackColor: Colors.transparent, // 背景透明，透出下层的缓冲条
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 20,
                    ),
                  ),
                  child: Slider(
                    value: progress,
                    onChanged: (value) => player.seek(duration * value),
                  ),
                ),
              ],
            ),
            //时间显示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatTime(position),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _formatTime(duration),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            StreamBuilder<bool>(
              stream: player.playingStream,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.shuffle_rounded),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.skip_previous_rounded, size: 42),
                    ),
                    GestureDetector(
                      onTap: () => musicProvider.togglePlay(),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primaryContainer,
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 40,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.skip_next_rounded, size: 42),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.repeat_rounded),
                    ),
                  ],
                );
              },
            ),
          ],

          //时间显示
        );
      },
    );
  }
}

class _LyricsSection extends StatelessWidget {
  final List<Map<String, dynamic>> lyrics;
  final ColorScheme colorScheme;
  final bool scrollable;

  const _LyricsSection({
    required this.lyrics,
    required this.colorScheme,
    this.scrollable = false,
  });

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 使用 Squircle (超圆角矩形) 代替圆形，更有 Android 16 的精致感
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh, // 更具深度的容器色
              borderRadius: BorderRadius.circular(28), // 类似应用图标的超圆角
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 背景微弱扩散效果
                Icon(
                  Icons.music_note_outlined,
                  color: colorScheme.primary.withOpacity(0.1),
                  size: 48,
                ),
                // 主图标：使用更具现代感的 Outlined 风格
                Icon(
                  Icons.speaker_notes_off_outlined,
                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                  size: 32,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 2. 标题文字：加大字重，间距微调
          Text(
            '歌詞が見つかりません', // 考虑到你的日系风格，可以微调文案
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          // 3. 描述文字：更柔和的对比度
          Text(
            'この曲の歌詞データはまだ登録されていません。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (lyrics.isEmpty) _buildEmptyState(context),
        ...lyrics.map(
          (line) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              line['text'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: line['text'] == ''
                    ? Colors.transparent
                    : colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ],
    );

    if (scrollable) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 40, 40),
        child: content,
      );
    }
    return content;
  }
}
