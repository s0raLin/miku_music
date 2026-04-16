import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class MusicDetailPage extends StatelessWidget {
  const MusicDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 用 select 只监听必要字段，避免无关变化触发重建
    final music = context.select<MusicProvider, MusicInfo?>(
      (p) => p.currentMusic,
    );

    if (music == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLiked = context.select<MusicProvider, bool>(
      (p) => p.favList.any((m) => m.id == music.id),
    );
    final lyrics = context.select<MusicProvider, List<Map<String, dynamic>>>(
      (p) => p.currentLyrics ?? [],
    );

    final isWide = MediaQuery.sizeOf(context).width > 700;
    final colorScheme = Theme.of(context).colorScheme;

    final mainContent = _MainContent(music: music, isLiked: isLiked);

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
                  Expanded(flex: 4, child: _LyricsSection(lyrics: lyrics)),
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

// ─── 主内容区（避免在顶层 watch 全量 provider） ─────────────────────────────────

class _MainContent extends StatelessWidget {
  final MusicInfo music;
  final bool isLiked;

  const _MainContent({required this.music, required this.isLiked});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();

    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: _AlbumCover(title: music.title, coverBytes: music.coverBytes),
        ),
        const SizedBox(height: 32),
        _SongMeta(
          music: music,
          isLiked: isLiked,
          onToggleLike: () => musicProvider.toggleFav(music),
        ),
        const SizedBox(height: 24),
        _PlayerConsole(music: music),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── 子组件 ─────────────────────────────────────────────────────────────────────

class _AlbumCover extends StatelessWidget {
  final String title;
  final Uint8List? coverBytes;

  const _AlbumCover({required this.coverBytes, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight.clamp(0.0, constraints.maxWidth);
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
                      // withOpacity 已弃用，改用 withValues
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
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

// ─── 播放控制台 ──────────────────────────────────────────────────────────────────

class _PlayerConsole extends StatelessWidget {
  final MusicInfo music;

  const _PlayerConsole({required this.music});

  @override
  Widget build(BuildContext context) {
    final musicProvider = context.read<MusicProvider>();

    return StreamBuilder<PositionData>(
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
            // Slider 单独提取避免整列重建
            _ProgressSlider(
              pos: pos,
              total: total,
              onChanged: (v) =>
                  musicProvider.player.seek(Duration(milliseconds: v.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _durationText(data.position, Theme.of(context).colorScheme),
                _durationText(data.duration, Theme.of(context).colorScheme),
              ],
            ),
            const SizedBox(height: 16),
            // 播放/暂停按钮单独 StreamBuilder，减少重建范围
            _PlaybackControls(musicProvider: musicProvider),
          ],
        );
      },
    );
  }

  static Widget _durationText(Duration d, ColorScheme scheme) => Text(
    '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}',
    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
  );
}

class _ProgressSlider extends StatelessWidget {
  final double pos;
  final double total;
  final ValueChanged<double> onChanged;

  const _ProgressSlider({
    required this.pos,
    required this.total,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      child: Slider(
        max: total > 0 ? total : 1.0,
        value: pos,
        onChanged: onChanged,
      ),
    );
  }
}

// 仅监听 playingStream，不依赖 MusicProvider 其他状态
class _PlaybackControls extends StatelessWidget {
  final MusicProvider musicProvider;

  const _PlaybackControls({required this.musicProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<bool>(
      stream: musicProvider.player.playingStream,
      builder: (context, snap) {
        final isPlaying = snap.data ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // TODO: 接入 shuffle 逻辑
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.shuffle_rounded),
            ),
            IconButton(
              onPressed: musicProvider.playPrev,
              icon: const Icon(Icons.skip_previous_rounded, size: 42),
            ),
            GestureDetector(
              onTap: musicProvider.togglePlay,
              child: CircleAvatar(
                radius: 36,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 40,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: musicProvider.playNext,
              icon: const Icon(Icons.skip_next_rounded, size: 42),
            ),
            // TODO: 接入 repeat 逻辑
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

// ─── 歌词区 ──────────────────────────────────────────────────────────────────────

class _LyricsSection extends StatelessWidget {
  final List<Map<String, dynamic>> lyrics;

  const _LyricsSection({required this.lyrics});

  @override
  Widget build(BuildContext context) {
    if (lyrics.isNotEmpty) {
      return ListView.builder(
        itemCount: lyrics.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            lyrics[i]['text'] as String,
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
