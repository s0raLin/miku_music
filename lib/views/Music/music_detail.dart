import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class MusicDetailPage extends StatefulWidget {
  // final MusicInfo? music;
  const MusicDetailPage({super.key});

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    final music = context.watch<MusicProvider>().currentMusic;
    if (music == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isWide = MediaQuery.of(context).size.width > 700;
    final colorScheme = Theme.of(context).colorScheme;

    // 通用的主体 UI 组件
    final mainContent = Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: _AlbumCover(title: music.title, coverBytes: music.coverBytes),
        ),
        const SizedBox(height: 32),
        _SongMeta(
          music: music,
          isLiked: _isLiked,
          onToggleLike: () => setState(() => _isLiked = !_isLiked),
        ),
        const SizedBox(height: 24),
        _PlayerConsole(music: music),
        const SizedBox(height: 32),
      ],
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context, music, colorScheme),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: isWide
            ? Row(
                children: [
                  Expanded(flex: 5, child: mainContent),
                  const VerticalDivider(width: 40, color: Colors.transparent),
                  Expanded(flex: 4, child: const _LyricsSection(lyrics: [])),
                ],
              )
            : mainContent,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    MusicInfo music,
    ColorScheme scheme,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
        onPressed: () => context.pop(),
      ),
      title: Column(
        children: [
          Text(
            '正在播放',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
          Text(
            music.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─── 抽取子组件 ─────────────────────────────────────────────────────────────────

class _AlbumCover extends StatelessWidget {
  final String title;
  final Uint8List? coverBytes;
  const _AlbumCover({required this.coverBytes, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, c) {
        final size = c.maxHeight.clamp(0.0, c.maxWidth);
        return Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: size,
              height: size,
              color: theme.colorScheme.surfaceContainerHighest,
              child: coverBytes?.isNotEmpty == true
                  ? Image.memory(coverBytes!, fit: BoxFit.cover)
                  : Icon(
                      Icons.music_note_rounded,
                      size: size * 0.3,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _SongMeta extends StatelessWidget {
  final MusicInfo music;
  final bool isLiked;
  final VoidCallback onToggleLike;

  const _SongMeta({
    required this.music,
    required this.isLiked,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.watch<MusicProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<PositionData>(
      // key: ValueKey(music.id), // 歌曲变了,StreamBuilder重新初始化
      stream: musicProvider.positionDataStream,
      builder: (context, snapshot) {
        final data =
            snapshot.data ??
            PositionData(Duration.zero, Duration.zero, Duration.zero);
        final total = data.duration.inMilliseconds.toDouble();
        final pos = data.position.inMilliseconds.toDouble().clamp(
          0.0,
          total > 0 ? total : 0.0,
        );

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 8,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Slider(
                max: total > 0 ? total : 1.0,
                value: pos,
                onChanged: (v) => musicProvider.player.seek(
                  Duration(milliseconds: v.toInt()),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _timeText(data.position, colorScheme),
                _timeText(data.duration, colorScheme),
              ],
            ),
            const SizedBox(height: 16),
            _buildControls(musicProvider, colorScheme),
          ],
        );
      },
    );
  }

  Widget _timeText(Duration d, ColorScheme scheme) => Text(
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}',
    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
  );

  Widget _buildControls(MusicProvider mp, ColorScheme scheme) {
    return StreamBuilder<bool>(
      stream: mp.player.playingStream,
      builder: (context, snap) {
        final isPlaying = snap.data ?? false;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.shuffle_rounded),
            ),
            IconButton(
              onPressed: () => mp.playPrev(),
              icon: const Icon(Icons.skip_previous_rounded, size: 42),
            ),
            GestureDetector(
              onTap: mp.togglePlay,
              child: CircleAvatar(
                radius: 36,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 40,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: () => mp.playNext(),
              icon: const Icon(Icons.skip_next_rounded, size: 42),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.repeat_rounded),
            ),
          ],
        );
      },
    );
  }
}

class _LyricsSection extends StatelessWidget {
  final List<Map<String, dynamic>> lyrics;
  const _LyricsSection({required this.lyrics});

  @override
  Widget build(BuildContext context) {
    if (lyrics.isNotEmpty) {
      return ListView.builder(
        itemCount: lyrics.length,
        itemBuilder: (c, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            lyrics[i]['text'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }
    return const Center(
      child: Text(
        '歌詞が見つかりません',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }
}
