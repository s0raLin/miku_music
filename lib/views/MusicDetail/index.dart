import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/contants/Assets/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// ─── 主页面 ───────────────────────────────────────────────────────────────────

class MusicDetailPage extends StatefulWidget {
  const MusicDetailPage({super.key});

  @override
  State<MusicDetailPage> createState() => _MusicDetailPageState();
}

class _MusicDetailPageState extends State<MusicDetailPage> {
  @override
  Widget build(BuildContext context) {
    final music = context.select<MusicProvider, MusicInfo?>(
      (p) => p.currentMusic,
    );
    if (music == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLiked = context.select<MusicProvider, bool>(
      (p) => p.favList.any((m) => m.id == music.id),
    );
    final isWide = MediaQuery.sizeOf(context).width > 700;

    return isWide
        ? _WideLayout(music: music, isLiked: isLiked)
        : _NarrowLayout(music: music, isLiked: isLiked);
  }
}

//宽屏布局
class _WideLayout extends StatelessWidget {
  final MusicInfo music;
  final bool isLiked;

  const _WideLayout({required this.music, required this.isLiked});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '正在播放',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            Text(
              music.title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _CoverTabContent(music: music, isLiked: isLiked),
            ),
          ),
          const VerticalDivider(width: 40, color: Colors.transparent),
          const Expanded(flex: 4, child: _LyricsSection()),
        ],
      ),
    );
  }
}

//窄屏布局
class _NarrowLayout extends StatefulWidget {
  final MusicInfo music;
  final bool isLiked;
  const _NarrowLayout({required this.music, required this.isLiked});

  @override
  State<_NarrowLayout> createState() => __NarrowLayoutState();
}

class __NarrowLayoutState extends State<_NarrowLayout>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => context.pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '正在播放',
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            Text(
              widget.music.title,
              style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(child: Text("歌曲")),
            Tab(child: Text("歌词")),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: _CoverTabContent(
              music: widget.music,
              isLiked: widget.isLiked,
            ),
          ),
          const _LyricsSection(),
        ],
      ),
    );
  }
}

// ─── 封面 + 元信息 + 控制台 ───────────────────────────────────────────────────

class _CoverTabContent extends StatelessWidget {
  final MusicInfo music;
  final bool isLiked;

  const _CoverTabContent({required this.music, required this.isLiked});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxHeight.clamp(
                0.0,
                constraints.maxWidth,
              );
              return Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: size,
                    height: size,
                    color: cs.surfaceContainerHighest,
                    child: music.coverBytes?.isNotEmpty == true
                        ? Image.memory(music.coverBytes!, fit: BoxFit.cover)
                        : Icon(
                            Icons.music_note_rounded,
                            size: size * 0.3,
                            color: cs.primary.withValues(alpha: 0.5),
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
        Row(
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
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${music.artist} · ${music.album}',
                    style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => provider.toggleFav(music),
              icon: Icon(
                isLiked
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isLiked ? cs.primary : cs.onSurfaceVariant,
                size: 28,
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: cs.onSurfaceVariant,
                size: 24,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'add', child: Text('添加到歌单')),
              ],
              onSelected: (_) => _showAddToPlaylistSheet(context, music),
            ),
          ],
        ),
        const SizedBox(height: 20),
        StreamBuilder<PositionData>(
          stream: provider.positionDataStream,
          builder: (context, snapshot) {
            final data =
                snapshot.data ??
                PositionData(Duration.zero, Duration.zero, Duration.zero);
            final totalMs = data.duration.inMilliseconds.toDouble();
            final posMs = data.position.inMilliseconds.toDouble().clamp(
              0.0,
              totalMs,
            );
            final safeTotal = totalMs > 0 ? totalMs : 1.0;

            String fmtMs(double ms) {
              final s = (ms / 1000).round();
              return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
            }

            String fmtDur(Duration d) =>
                '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(
                    context,
                  ).copyWith(showValueIndicator: ShowValueIndicator.onDrag),
                  child: Slider(
                    year2023: false,
                    value: posMs.clamp(0.0, safeTotal),
                    max: safeTotal,
                    divisions: totalMs > 0 ? totalMs.toInt() : null,
                    label: fmtMs(posMs),
                    onChanged: (v) =>
                        provider.player.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      fmtDur(data.position),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      fmtDur(data.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _PlaybackControls(provider: provider),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Future<void> _showAddToPlaylistSheet(
    BuildContext context,
    MusicInfo song,
  ) async {
    // TODO
  }
}

// ─── 歌词区域 ─────────────────────────────────────────────────────────────────

class _LyricsSection extends StatefulWidget {
  const _LyricsSection();

  @override
  State<_LyricsSection> createState() => _LyricsSectionState();
}

class _LyricsSectionState extends State<_LyricsSection>
    with AutomaticKeepAliveClientMixin {
  final ItemScrollController _scrollController = ItemScrollController();
  int _lastAutoScrollIndex = -1;
  List<Map<String, dynamic>> _prevLyrics = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final lyrics = context.read<MusicProvider>().currentLyrics;
    if (!_lyricsEqual(lyrics, _prevLyrics)) {
      _prevLyrics = List.from(lyrics);
      _lastAutoScrollIndex = -1;
    }
  }

  bool _lyricsEqual(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i]['time'] != b[i]['time'] || a[i]['text'] != b[i]['text']) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final lyrics = context.watch<MusicProvider>().currentLyrics;
    final cs = Theme.of(context).colorScheme;

    if (lyrics.isEmpty) {
      return Center(
        child: Text(
          '暂无歌词',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }

    return StreamBuilder<PositionData>(
      stream: context.read<MusicProvider>().positionDataStream,
      builder: (context, snapshot) {
        final position = snapshot.data?.position ?? Duration.zero;

        int currentIndex = 0;
        for (var i = 0; i < lyrics.length; i++) {
          if (position >= (lyrics[i]['time'] as Duration)) {
            currentIndex = i;
          } else {
            break;
          }
        }

        if (currentIndex != _lastAutoScrollIndex &&
            _scrollController.isAttached) {
          _lastAutoScrollIndex = currentIndex;
          final isNearEnd = currentIndex >= lyrics.length - 3;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _scrollController.scrollTo(
              index: currentIndex,
              alignment: isNearEnd ? 0.1 : 0.5,
              duration: Duration(milliseconds: isNearEnd ? 340 : 300),
              curve: Curves.easeOutCubic,
            );
          });
        }

        Widget fadeGradient(Alignment alignment) => IgnorePointer(
          child: Align(
            alignment: alignment,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: alignment,
                  end: alignment == Alignment.topCenter
                      ? Alignment.bottomCenter
                      : Alignment.topCenter,
                  colors: [cs.surface, cs.surface.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
        );

        return Stack(
          children: [
            ScrollablePositionedList.builder(
              itemScrollController: _scrollController,
              itemCount: lyrics.length,
              padding: const EdgeInsets.symmetric(vertical: 80),
              itemBuilder: (context, index) {
                final item = lyrics[index];
                final isActive = index == currentIndex;
                final isNear = (index - currentIndex).abs() == 1;

                final style = isActive
                    ? TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.primary,
                        height: 1.4,
                      )
                    : isNear
                    ? TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.6),
                        height: 1.4,
                      )
                    : TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                        height: 1.4,
                      );

                return InkWell(
                  onTap: () => context.read<MusicProvider>().player.seek(
                    item['time'] as Duration,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 24,
                    ),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      style: style,
                      child: Text(
                        (item['text'] as String).isEmpty
                            ? '\u00a0'
                            : item['text'] as String,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
            fadeGradient(Alignment.topCenter),
            fadeGradient(Alignment.bottomCenter),
          ],
        );
      },
    );
  }
}

// ─── 播放控制按钮组 ────────────────────────────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  final MusicProvider provider;

  const _PlaybackControls({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    IconData modeIcon(PlayMode mode) => switch (mode) {
      PlayMode.sequence => Icons.repeat_rounded,
      PlayMode.shuffle => Icons.shuffle_rounded,
      PlayMode.repeat => Icons.repeat_one_rounded,
    };

    return StreamBuilder<ProcessingState>(
      stream: provider.player.processingStateStream,
      builder: (context, _) {
        final playing = provider.player.playing;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: provider.togglePlayMode,
              icon: Icon(modeIcon(provider.playMode)),
              color: cs.onSurfaceVariant,
              tooltip: '播放模式',
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: provider.playPrev,
              tooltip: '上一首',
              icon: ImageIcon(AssetImage(MyAssets.prev)),
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: provider.togglePlay,
              icon: ImageIcon(
                AssetImage(playing ? MyAssets.pause : MyAssets.play),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: const CircleBorder(),
                fixedSize: const Size(64, 64),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: provider.playNext,
              tooltip: '下一首',
              icon: ImageIcon(AssetImage(MyAssets.next)),
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            _VolumeButton(provider: provider),
          ],
        );
      },
    );
  }
}

// ─── 音量按钮 ─────────────────────────────────────────────────────────────────

class _VolumeButton extends StatefulWidget {
  final MusicProvider provider;

  const _VolumeButton({required this.provider});

  @override
  State<_VolumeButton> createState() => _VolumeButtonState();
}

class _VolumeButtonState extends State<_VolumeButton> {
  final MenuController _menuController = MenuController();
  double _lastNonZeroVolume = 1.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<double>(
      stream: widget.provider.player.volumeStream,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? widget.provider.volume;
        if (volume > 0) _lastNonZeroVolume = volume;

        final icon = volume == 0
            ? Icons.volume_off_rounded
            : volume < 0.5
            ? Icons.volume_down_rounded
            : Icons.volume_up_rounded;

        return MenuAnchor(
          controller: _menuController,
          alignmentOffset: const Offset(-8, -6),
          menuChildren: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: SizedBox(
                height: 160,
                child: RotatedBox(
                  quarterTurns: -1,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      inactiveTrackColor: cs.surfaceContainerHighest,
                      activeTrackColor: cs.primary,
                    ),
                    child: Slider(
                      value: volume.clamp(0.0, 1.0),
                      onChanged: (v) => widget.provider.setVolume(v),
                    ),
                  ),
                ),
              ),
            ),
          ],
          child: IconButton(
            tooltip: _menuController.isOpen ? '静音' : '音量',
            onPressed: () async {
              if (_menuController.isOpen) {
                await widget.provider.setVolume(
                  volume == 0 ? _lastNonZeroVolume.clamp(0.0, 1.0) : 0.0,
                );
                return;
              }
              _menuController.open();
            },
            icon: Icon(icon),
            style: IconButton.styleFrom(
              foregroundColor: cs.onSurfaceVariant,
              backgroundColor: Colors.transparent,
              shape: const CircleBorder(),
            ),
          ),
        );
      },
    );
  }
}
