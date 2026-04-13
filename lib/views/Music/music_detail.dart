import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/service/Music/index.dart';

class MusicDetailPage extends StatefulWidget {
  final String? id;

  const MusicDetailPage({super.key, this.id});

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  // 定义 Future 变量，避免 build 时重复请求
  late Future<MusicInfo> _musicFuture;

  bool _isPlaying = true;
  bool _isLiked = false;
  double _progress = 0.38;

  // 模拟歌词
  static const List<Map<String, dynamic>> _lyrics = [];

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  void initState() {
    super.initState();
    // 初始化时加载数据
    _musicFuture = MusicService.getSongById(widget.id ?? '0');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return FutureBuilder<MusicInfo>(
      future: _musicFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [CircularProgressIndicator(), Text("加载中...")],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(child: Text("数据加载失败")),
          );
        }

        //拿到数据实体
        final music = snapshot.data!;

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
                  progress: _progress,
                  isPlaying: _isPlaying,
                  isLiked: _isLiked,
                  lyrics: _lyrics,
                  colorScheme: colorScheme,
                  onTogglePlay: _togglePlay,
                  onToggleLike: () => setState(() => _isLiked = !_isLiked),
                  onProgressChanged: (v) => setState(() => _progress = v),
                  music: music,
                )
              : _NarrowLayout(
                  progress: _progress,
                  isPlaying: _isPlaying,
                  isLiked: _isLiked,
                  lyrics: _lyrics,
                  colorScheme: colorScheme,
                  onTogglePlay: _togglePlay,
                  onToggleLike: () => setState(() => _isLiked = !_isLiked),
                  onProgressChanged: (v) => setState(() => _progress = v),
                  music: music,
                ),
        );
      },
    );
  }
}

// ─── 窄屏布局 ─────────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  final MusicInfo music;
  final double progress;
  final bool isPlaying;
  final bool isLiked;
  final List<Map<String, dynamic>> lyrics;
  final ColorScheme colorScheme;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleLike;
  final ValueChanged<double> onProgressChanged;

  const _NarrowLayout({
    required this.progress,
    required this.isPlaying,
    required this.isLiked,
    required this.lyrics,
    required this.colorScheme,
    required this.onTogglePlay,
    required this.onToggleLike,
    required this.onProgressChanged,
    required this.music,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _AlbumCover(colorScheme: colorScheme, size: 320),
          const SizedBox(height: 40),
          _SongMeta(
            isLiked: isLiked,
            colorScheme: colorScheme,
            onToggleLike: onToggleLike,
            music: music,
          ),
          const SizedBox(height: 24),
          _ProgressSection(
            progress: progress,
            colorScheme: colorScheme,
            onChanged: onProgressChanged,
            totalDuration: music.duration,
          ),
          const SizedBox(height: 16),
          _ControlButtons(
            isPlaying: isPlaying,
            colorScheme: colorScheme,
            onTogglePlay: onTogglePlay,
          ),
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
  final double progress;
  final bool isPlaying;
  final bool isLiked;
  final List<Map<String, dynamic>> lyrics;
  final ColorScheme colorScheme;
  final VoidCallback onTogglePlay;
  final VoidCallback onToggleLike;
  final ValueChanged<double> onProgressChanged;

  const _WideLayout({
    required this.progress,
    required this.isPlaying,
    required this.isLiked,
    required this.lyrics,
    required this.colorScheme,
    required this.onTogglePlay,
    required this.onToggleLike,
    required this.onProgressChanged,
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
                _AlbumCover(colorScheme: colorScheme, size: 280),
                const SizedBox(height: 40),
                _SongMeta(
                  isLiked: isLiked,
                  colorScheme: colorScheme,
                  onToggleLike: onToggleLike,
                  music: music,
                ),
                const SizedBox(height: 24),
                _ProgressSection(
                  progress: progress,
                  colorScheme: colorScheme,
                  onChanged: onProgressChanged,
                  totalDuration: music.duration,
                ),
                const SizedBox(height: 16),
                _ControlButtons(
                  isPlaying: isPlaying,
                  colorScheme: colorScheme,
                  onTogglePlay: onTogglePlay,
                ),
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
  final ColorScheme colorScheme;
  final double size;

  const _AlbumCover({required this.colorScheme, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28), // 现代大圆角
          image: const DecorationImage(
            image: NetworkImage('https://placeholder.com/300'), // 这里可以放真实的封面图
            fit: BoxFit.cover,
          ),
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

class _ProgressSection extends StatelessWidget {
  final double progress;
  final Duration totalDuration; //总时长
  final ColorScheme colorScheme;
  final ValueChanged<double> onChanged;
  // final String Function(double, Duration totalDuration) formatDuration;

  const _ProgressSection({
    required this.progress,
    required this.colorScheme,
    required this.onChanged,
    required this.totalDuration,
    // required this.formatDuration,
  });

  String _formatTime(double p) {
    final totalSec = totalDuration.inSeconds;
    final sec = (p * totalSec).round();
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            // Android 13-16 风格：极粗轨道，无明显 Thumb（或小点）
            trackHeight: 12,
            trackShape: const RoundedRectSliderTrackShape(),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 0, // 默认不显示滑块，触摸时显示或保持简约
              elevation: 0,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withOpacity(0.1),
          ),
          child: Slider(value: progress, onChanged: onChanged),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(progress),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _formatTime(1.0),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final bool isPlaying;
  final ColorScheme colorScheme;
  final VoidCallback onTogglePlay;

  const _ControlButtons({
    required this.isPlaying,
    required this.colorScheme,
    required this.onTogglePlay,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.shuffle_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.skip_previous_rounded,
            color: colorScheme.onSurface,
            size: 42,
          ),
        ),
        GestureDetector(
          onTap: onTogglePlay,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primaryContainer,
            ),
            child: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: colorScheme.onPrimaryContainer,
              size: 40,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.skip_next_rounded,
            color: colorScheme.onSurface,
            size: 42,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.repeat_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 24,
          ),
        ),
      ],
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
