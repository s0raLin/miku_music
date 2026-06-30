import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/media_overlay_card.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class ObservableMusicGridCard extends StatefulWidget {
  final int index;
  final Music music;
  final VoidCallback? onTap;

  const ObservableMusicGridCard({
    super.key,
    required this.music,
    required this.index,
    this.onTap,
  });

  @override
  State<ObservableMusicGridCard> createState() =>
      _ObservableMusicGridCardState();
}

class _ObservableMusicGridCardState extends State<ObservableMusicGridCard> {
  void _triggerLazyCover() {
    final hasNoCover =
        widget.music.coverBytes == null || widget.music.coverBytes!.isEmpty;
    if (hasNoCover) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<MusicProvider>().loadCoverLazy(widget.music.id);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _triggerLazyCover();
  }

  @override
  void didUpdateWidget(ObservableMusicGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.music.id != widget.music.id) {
      _triggerLazyCover();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final musicProvider = context.watch<MusicProvider>();

    final music = musicProvider.library.firstWhere(
      (m) => m.id == widget.music.id,
      orElse: () => widget.music,
    );

    final bool hasNoCover =
        music.coverBytes == null || music.coverBytes!.isEmpty;

    final badgeBackground = colorScheme.surfaceContainerHigh.withValues(
      alpha: colorScheme.brightness == Brightness.dark ? 0.88 : 0.82,
    );

    final isNetwork = music.source == MusicSource.network;
    final coverUrl = isNetwork ? musicProvider.getCoverUrl(music.id) : null;

    return MediaOverlayCard(
      title: music.title,
      subtitle: music.artist,
      coverBytes: music.coverBytes,
      coverUrl: coverUrl,
      coverHeaders: isNetwork && coverUrl != null && coverUrl.contains('music.126.net')
          ? {'Referer': 'https://music.163.com/'}
          : null,
      fallbackIcon: Icons.music_note_rounded,
      onTap: widget.onTap,
      isLoading: hasNoCover && musicProvider.isCoverLoading(music.id),
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBackground,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '#${widget.index + 1}',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
