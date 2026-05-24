import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/config/globals.dart';

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
                      actions: [
                        IconButton(
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.settings_rounded),
                        ),
                      ],
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
  double _progress = 0.45;
  static const double _totalSeconds = 225;

  String _formatTime(double seconds) {
    final d = Duration(seconds: seconds.toInt());
    return '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  }

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
              final content = _NowPlayingContent(
                theme: theme,
                colorScheme: cs,
                progress: _progress,
                onProgressChanged: (v) => setState(() => _progress = v),
                elapsed: _formatTime(_progress * _totalSeconds),
              );
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
  const _NowPlayingContent({
    required this.theme,
    required this.colorScheme,
    required this.progress,
    required this.onProgressChanged,
    required this.elapsed,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final double progress;
  final ValueChanged<double> onProgressChanged;
  final String elapsed;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOW PLAYING',
          style: theme.textTheme.labelSmall?.copyWith(
            color: cs.onSecondaryContainer.withValues(alpha: 0.7),
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Blinding Lights',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSecondaryContainer,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'The Weeknd',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSecondaryContainer.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 20),
        WavySlider(
          value: progress,
          onChanged: onProgressChanged,
          activeColor: cs.primary,
          inactiveColor: cs.outlineVariant,
          thumbColor: cs.primary,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              elapsed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSecondaryContainer.withValues(alpha: 0.7),
              ),
            ),
            const Spacer(),
            Text(
              '3:45',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSecondaryContainer.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
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
