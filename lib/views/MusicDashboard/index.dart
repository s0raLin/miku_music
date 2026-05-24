import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/config/globals.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

// ─── 断点 ────────────────────────────────────────────────
const double _kCompactBreakpoint = 700;
const double _kCardBreakpoint = 500;

// ─── 页面入口 ─────────────────────────────────────────────

class MusicDashboardPage extends StatelessWidget {
  const MusicDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < _kCompactBreakpoint;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: CustomScrollView(
                  slivers: [
                    Header(
                      pinned: true,
                      leading: IconButton(
                        onPressed: () =>
                            rootScaffoldKey.currentState?.openDrawer(),
                        icon: const Icon(Icons.menu_rounded),
                      ),
                      title: const Text('M3Music'),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
                      sliver: SliverToBoxAdapter(
                        child: compact ? _CompactLayout() : _WideLayout(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── 响应式布局壳 ─────────────────────────────────────────

class _CompactLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NowPlayingCard(),
        SizedBox(height: 12),
        _PlaybackControlCard(),
        SizedBox(height: 12),
        _VolumeControlCard(),
        SizedBox(height: 12),
        _AudioInfoCard(),
        SizedBox(height: 12),
        _OutputDeviceCard(),
      ],
    );
  }
}

class _WideLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _NowPlayingCard(),
              SizedBox(height: 12),
              _PlaybackControlCard(),
              SizedBox(height: 12),
              _VolumeControlCard(),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _AudioInfoCard(),
              SizedBox(height: 12),
              _OutputDeviceCard(),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── NowPlaying 卡片 ──────────────────────────────────────

class _NowPlayingCard extends StatefulWidget {
  const _NowPlayingCard();

  @override
  State<_NowPlayingCard> createState() => _NowPlayingCardState();
}

class _NowPlayingCardState extends State<_NowPlayingCard> {
  // double _progress = 0.45;
  // static const double _totalSeconds = 225;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card.filled(
      color: cs.secondaryContainer,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/dashboard/cover-flow'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < _kCardBreakpoint;
              final content = _NowPlayingContent();
              return narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AlbumCover(colorScheme: cs),
                        const SizedBox(height: 20),
                        content,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AlbumCover(colorScheme: cs),
                        const SizedBox(width: 24),
                        Expanded(child: content),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }
}

class _AlbumCover extends StatelessWidget {
  const _AlbumCover({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'album_cover',
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.album_rounded,
          size: 44,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _NowPlayingContent extends StatelessWidget {
  const _NowPlayingContent();

  String _formatTime(double seconds) {
    final d = Duration(seconds: seconds.toInt());
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ts = Theme.of(context).textTheme;
    final mp = context.read<MusicProvider>();
    return StreamBuilder(
      stream: mp.positionDataStream,
      builder: (context, snapshot) {
        final pos =
            snapshot.data ??
            PositionData(Duration.zero, Duration.zero, Duration.zero);
        final value = pos.duration.inMilliseconds > 0
            ? (pos.position.inMilliseconds / pos.duration.inMilliseconds).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOW PLAYING',
              style: ts.labelSmall?.copyWith(
                color: cs.onSecondaryContainer.withValues(alpha: 0.7),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Blinding Lights',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ts.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'The Weeknd',
              style: ts.bodyMedium?.copyWith(
                color: cs.onSecondaryContainer.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 20),
            WavySlider(
              value: value,
              onChanged: (v) => mp.player.seek(
                Duration(
                  milliseconds: (pos.duration.inMilliseconds * v).toInt(),
                ),
              ),
              activeColor: cs.primary,
              inactiveColor: cs.outlineVariant,
              thumbColor: cs.primary,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _formatTime(pos.position.inSeconds.toDouble()),
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSecondaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTime(pos.duration.inSeconds.toDouble()),
                  style: ts.bodySmall?.copyWith(
                    color: cs.onSecondaryContainer.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ─── Playback 控制卡片 ────────────────────────────────────

class _PlaybackControlCard extends StatefulWidget {
  const _PlaybackControlCard();

  @override
  State<_PlaybackControlCard> createState() => _PlaybackControlCardState();
}

class _PlaybackControlCardState extends State<_PlaybackControlCard> {
  bool _playing = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card.filled(
      color: cs.surfaceContainerHigh,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Playback',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.skip_previous_rounded),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () => setState(() => _playing = !_playing),
              style: IconButton.styleFrom(
                fixedSize: const Size(56, 56),
                iconSize: 28,
              ),
              icon: Icon(
                _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () {},
              icon: const Icon(Icons.skip_next_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 信息卡片 ─────────────────────────────────────────────

class _AudioInfoCard extends StatelessWidget {
  const _AudioInfoCard();

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: const ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Icon(Icons.high_quality_rounded),
          title: Text('Audio Quality'),
          subtitle: Text('96kHz / 24bit'),
          trailing: FilledButton.tonal(onPressed: null, child: Text('Hi-Res')),
        ),
      ),
    );
  }
}

class _OutputDeviceCard extends StatelessWidget {
  const _OutputDeviceCard();

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: const ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Icon(Icons.bluetooth_audio_rounded),
          title: Text('Output Device'),
          subtitle: Text('LDAC Headphones'),
          trailing: Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _VolumeControlCard extends StatefulWidget {
  const _VolumeControlCard();

  @override
  State<_VolumeControlCard> createState() => _VolumeControlCardState();
}

class _VolumeControlCardState extends State<_VolumeControlCard> {
  double _volume = 0;

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    return Expanded(
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 56,
          trackShape: const RoundedRectSliderTrackShape(),
          thumbShape: const NoThumbShape(),
          overlayShape: SliderComponentShape.noOverlay,
        ),
        child: Stack(
          children: [
            Slider(
              value: _volume,

              onChanged: (v) {
                setState(() {
                  mp.setVolume(v);
                  _volume = v;
                });
              },
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 20,
              child: Icon(Icons.volume_up_rounded, size: 36),
            ),
          ],
        ),
      ),
    );
  }
}

class NoThumbShape extends SliderComponentShape {
  const NoThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(0, 0);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    // 什么都不画 = 完全隐藏
  }
}
