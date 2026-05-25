import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:myapp/constants/Assets/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class NowPlayingBar extends StatelessWidget {
  const NowPlayingBar({super.key});

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    final music = context.select<MusicProvider, MusicInfo?>(
      (p) => p.currentMusic,
    );

    if (music == null) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: InkWell(
        onTap: () {
          context.push("/music-detail");
        },
        child: SizedBox(
          height: 72,
          child: isWide
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _WideLayout(music: music, fmt: NowPlayingBar._fmt),
                )
              : Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: _MiniProgressBar(fmt: NowPlayingBar._fmt),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _CompactLayout(music: music),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ============================================================
// 宽屏布局：[左: 歌曲信息] [中: 控制区] [右: 音量]
// ============================================================
class _WideLayout extends StatelessWidget {
  final MusicInfo music;
  final String Function(Duration) fmt;
  const _WideLayout({required this.music, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 左侧：歌曲信息 flex=3
        Expanded(flex: 3, child: _TrackInfoTile(music: music)),

        // 中间：播放控制 + 详细进度条 flex=5
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // M3 控制按钮行：间距遵循 M3 spacing scale
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // M3 Icon Button — Standard
                  IconButton(
                    icon: const Icon(Icons.shuffle_rounded),
                    iconSize: 20,
                    tooltip: '随机播放',
                    onPressed: mp.togglePlayMode,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 24,
                    tooltip: '上一首',
                    onPressed: mp.playPrev,
                  ),
                  // M3 Filled Icon Button — 主操作，使用 primary container
                  IconButton.filled(
                    onPressed: () => mp.togglePlay(),
                    style: IconButton.styleFrom(
                      // M3：Filled Icon Button 使用 primary color，尺寸 40dp
                      minimumSize: const Size(40, 40),
                      maximumSize: const Size(40, 40),
                    ),
                    tooltip: isPlaying ? '暂停' : '播放',
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 24,
                    tooltip: '下一首',
                    onPressed: mp.playNext,
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat_rounded),
                    iconSize: 20,
                    tooltip: '循环',
                    onPressed: () {},
                  ),
                ],
              ),
              // 详细进度条（含时间标签）
              _DetailedProgressBar(fmt: fmt),
            ],
          ),
        ),

        // 右侧：音量 + 队列 flex=3
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _VolumeControl(),
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                iconSize: 24,
                tooltip: '播放队列',
                onPressed: () => _showQueue(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      // M3 Modal Bottom Sheet shape：top corners 28dp（extra-large）
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _QueueSheet(),
    );
  }
}

// ============================================================
// 紧凑布局（窄屏）
// ============================================================
class _CompactLayout extends StatelessWidget {
  final MusicInfo music;
  const _CompactLayout({required this.music});

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _TrackInfoTile(music: music)),
        // M3 Icon Button — Standard（48dp 触摸目标）
        IconButton(
          icon: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          iconSize: 24,
          tooltip: isPlaying ? '暂停' : '播放',
          onPressed: () => mp.togglePlay(),
        ),
        IconButton(
          icon: const Icon(Icons.queue_music_rounded),
          iconSize: 24,
          tooltip: '播放队列',
          onPressed: () => context.push("/queue"),
        ),
        IconButton(
          icon: const Icon(Icons.close_fullscreen_rounded, size: 16),
          onPressed: () => context.read<MusicProvider>().setMiniMode(true),
        ),
      ],
    );
  }
}

// ============================================================
// 歌曲信息块
// ============================================================
class _TrackInfoTile extends StatelessWidget {
  final MusicInfo music;
  const _TrackInfoTile({required this.music});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // M3 Shape：small（8dp corners）用于封面图
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: music.coverBytes != null && music.coverBytes!.isNotEmpty
              ? Image.memory(
                  music.coverBytes!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 48,
                  height: 48,
                  color: cs.surfaceContainerHighest,
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 24,
                    color: cs.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // M3 TypeScale：titleSmall（14sp / medium weight）
              Text(
                music.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.titleSmall,
              ),
              const SizedBox(height: 2),
              // M3 TypeScale：bodySmall（12sp），onSurfaceVariant
              Text(
                music.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 详细进度条（宽屏用，含时间戳）
// ============================================================
class _DetailedProgressBar extends StatelessWidget {
  final String Function(Duration) fmt;
  const _DetailedProgressBar({required this.fmt});

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return StreamBuilder<PositionData>(
      stream: mp.positionDataStream,
      builder: (context, snap) {
        final pos =
            snap.data ??
            PositionData(Duration.zero, Duration.zero, Duration.zero);
        final value = pos.duration.inMilliseconds > 0
            ? (pos.position.inMilliseconds / pos.duration.inMilliseconds).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return Row(
          children: [
            // M3 TypeScale：labelSmall（11sp）
            SizedBox(
              width: 36,
              child: Text(
                fmt(pos.position),
                textAlign: TextAlign.right,
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  // M3 Slider 规范值
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: cs.primary,
                  inactiveTrackColor: cs.surfaceContainerHighest,
                  thumbColor: cs.primary,
                  overlayColor: cs.primary.withOpacity(0.12),
                ),
                child: Slider(
                  value: value,
                  onChanged: (v) => mp.player.seek(
                    Duration(
                      milliseconds: (pos.duration.inMilliseconds * v).toInt(),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 36,
              child: Text(
                fmt(pos.duration),
                style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ============================================================
// 顶部迷你进度条（M3 LinearProgressIndicator style）
// ============================================================
class _MiniProgressBar extends StatelessWidget {
  final String Function(Duration) fmt;
  const _MiniProgressBar({required this.fmt});

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<PositionData>(
      stream: mp.positionDataStream,
      builder: (context, snap) {
        final pos =
            snap.data ??
            PositionData(Duration.zero, Duration.zero, Duration.zero);
        final value = pos.duration.inMilliseconds > 0
            ? (pos.position.inMilliseconds / pos.duration.inMilliseconds).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox;
            final dx = details.localPosition.dx / box.size.width;
            mp.player.seek(
              Duration(
                milliseconds: (pos.duration.inMilliseconds * dx).toInt(),
              ),
            );
          },
          child: SizedBox(
            height: 4,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(cs.primary),
              minHeight: 4,
              borderRadius: BorderRadius.zero,
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// 音量控制
// ============================================================
class _VolumeControl extends StatelessWidget {
  const _VolumeControl();

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final volume = context.select<MusicProvider, double>((p) => p.volume);
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          size: 20,
          color: cs.onSurfaceVariant,
        ),
        SizedBox(
          width: 88,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: cs.primary,
              inactiveTrackColor: cs.surfaceContainerHighest,
              thumbColor: cs.primary,
              overlayColor: cs.primary.withOpacity(0.12),
            ),
            child: Slider(value: volume, onChanged: (v) => mp.setVolume(v)),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 播放队列 Bottom Sheet
// M3 Modal Bottom Sheet 规范：
//   • 顶部 drag handle（4×32dp，rounded，onSurfaceVariant，透明度 0.4）
//   • 内容区 padding：top 24dp（handle 下方），horizontal 16dp
//   • 列表项使用 ListTile（M3 标准高度 56/72dp）
// ============================================================
class _QueueSheet extends StatelessWidget {
  const _QueueSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final mp = context.watch<MusicProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // M3 Drag Handle
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 0),
          child: Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        // M3 Header：titleMedium
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('播放队列', style: tt.titleMedium),
          ),
        ),
        const Divider(height: 1),
        // 队列列表，限制最大高度避免撑满屏幕
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.5,
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: mp.queue.length,
            itemBuilder: (context, index) {
              final m = mp.queue[index];
              final isCurrent = mp.currentMusic?.id == m.id;

              return ListTile(
                // M3 ListTile：leading 40dp
                leading: isCurrent
                    ? Lottie.asset(
                        MyAssets.equalizer,
                        width: 24,
                        height: 24,
                        animate: mp.player.playing,
                      )
                    : Icon(
                        Icons.music_note_rounded,
                        size: 24,
                        color: cs.onSurfaceVariant,
                      ),
                title: Text(
                  m.title,
                  // M3 TypeScale：bodyLarge（正文）
                  style: tt.bodyLarge?.copyWith(
                    // 当前播放项使用 primary 色
                    color: isCurrent ? cs.primary : null,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  m.artist,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                // M3 StateLayer：通过 InkWell 内置提供
                selected: isCurrent,
                selectedTileColor: cs.secondaryContainer.withOpacity(0.3),
                onTap: () => mp.playByIndex(index),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              );
            },
          ),
        ),
      ],
    );
  }
}
