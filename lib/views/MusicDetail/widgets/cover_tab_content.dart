// ─── 封面 + 元信息 + 控制台 ───────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class CoverTabContent extends StatelessWidget {
  final MusicInfo music;
  final bool isLiked;

  const CoverTabContent({
    super.key,
    required this.music,
    required this.isLiked,
  });

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
              onPressed: () {
                provider.toggleFav(music);
                final isFav = provider.favList.any((m) => m.id == music.id);
                AppToast.neutral(context, message: isFav ? '已添加到喜欢' : '已取消收藏');
              },
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
    String modeTooltip(PlayMode mode) => switch (mode) {
      PlayMode.sequence => "顺序播放",
      PlayMode.shuffle => "随机播放",
      PlayMode.repeat => "单曲循环",
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
              tooltip: modeTooltip(provider.playMode),
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
