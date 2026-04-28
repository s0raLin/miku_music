import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

/// 底部播放进度栏组件
class NowPlayingBar extends StatelessWidget {
  static const double _breakpoint = 700.0; // 响应式切换阈值
  const NowPlayingBar({super.key});

  /// 时间格式化辅助函数：将 Duration 转为 00:00 格式
  static String _fmt(Duration d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.inMinutes.remainder(60))}:${p(d.inSeconds.remainder(60))}';
  }

  @override
  Widget build(BuildContext context) {
    // 监听当前音乐信息，如果没有播放内容则隐藏
    final music = context.select<MusicProvider, MusicInfo?>(
      (p) => p.currentMusic,
    );
    if (music == null) return const SizedBox.shrink();

    return _BarContainer(
      onTap: () => context.push('/music-detail'), // 点击跳转详情页
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _breakpoint;
          // 根据容器宽度决定布局模式
          if (isWide) return _WideLayout(music: music, fmt: _fmt);
          return _CompactLayout(music: music);
        },
      ),
    );
  }
}

/// 播放栏外层容器：处理背景色、圆角、高度和点击反馈
class _BarContainer extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _BarContainer({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SizedBox(
          width: double.infinity,
          height: 84, // 固定高度
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 宽屏模式布局：左右固定/自适应，中间绝对居中
class _WideLayout extends StatelessWidget {
  final MusicInfo music;
  final String Function(Duration) fmt;
  const _WideLayout({required this.music, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();

    // 使用 Stack 配合 Center 实现中间内容绝对居中
    return Stack(
      alignment: Alignment.center,
      children: [
        // 左侧：歌曲信息
        Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300), // 限制左侧最大宽度避免挤压中间
            child: _TrackInfo(music: music),
          ),
        ),

        // 中间：播放控制按钮和进度条（绝对居中）
        _PlaybackCenter(fmt: fmt),

        // 右侧：功能操作
        Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _VolumeControllerWidget(),
              _QueueActions(
                showCompactPlayPause: false,
                onPlayPause: mp.togglePlay,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 紧凑模式布局：仅显示歌曲信息和基本控制
class _CompactLayout extends StatelessWidget {
  final MusicInfo music;
  const _CompactLayout({required this.music});

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    return Row(
      children: [
        Expanded(child: _TrackInfo(music: music)),
        _QueueActions(showCompactPlayPause: true, onPlayPause: mp.togglePlay),
      ],
    );
  }
}

/// 歌曲基本信息：封面 + 歌名 + 歌手
class _TrackInfo extends StatelessWidget {
  final MusicInfo music;
  const _TrackInfo({required this.music});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AlbumArt(coverBytes: music.coverBytes),
        const SizedBox(width: 12),
        Flexible(
          // 使用 Flexible 允许文本在空间不足时省略
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                music.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                music.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 中间播放控制区域
class _PlaybackCenter extends StatelessWidget {
  final String Function(Duration) fmt;
  const _PlaybackCenter({required this.fmt});

  @override
  Widget build(BuildContext context) {
    final mp = context.read<MusicProvider>();
    final cs = Theme.of(context).colorScheme;
    // 监听播放状态
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );
    final isShuffle = context.select<MusicProvider, bool>(
      (p) => p.playMode == PlayMode.shuffle,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniIconButton(
              icon: isShuffle ? Icons.sort_rounded : Icons.shuffle_rounded,
              tooltip: isShuffle ? '顺序播放' : '随机播放',
              color: isShuffle ? cs.primary : cs.onSurfaceVariant,
              onPressed: mp.togglePlayMode,
            ),
            _MiniIconButton(
              icon: Icons.skip_previous_rounded,
              onPressed: mp.playPrev,
            ),
            // 主播放按钮
            _MiniIconButton(
              icon: isPlaying
                  ? Icons.pause_circle_filled_rounded
                  : Icons.play_circle_filled_rounded,
              size: 40, // 突出显示
              color: cs.primary,
              onPressed: mp.togglePlay,
            ),
            _MiniIconButton(
              icon: Icons.skip_next_rounded,
              onPressed: mp.playNext,
            ),
          ],
        ),
        const SizedBox(height: 2),
        _ProgressBar(fmt: fmt),
      ],
    );
  }
}

/// 进度条组件：使用 StreamBuilder 实现秒级更新
class _ProgressBar extends StatelessWidget {
  final String Function(Duration) fmt;
  const _ProgressBar({required this.fmt});

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
        final durationMs = pos.duration.inMilliseconds;
        final positionMs = pos.position.inMilliseconds;
        double value = (durationMs > 0) ? positionMs / durationMs : 0.0;

        return SizedBox(
          width: 320,
          // 既然要变大，我们把高度稍微拉一点点，确保文字对齐
          height: 36,
          child: Row(
            children: [
              // 时间文本稍微放大一点点以匹配变粗的线条
              Text(fmt(pos.position), style: _ts(cs)),
              const SizedBox(width: 8), // 增加一点文本和线条的间距
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    // 1. 核心改动：显著增加轨道高度，使其看起来“更大”
                    trackHeight: 10.0, // 从 2.0 增加到 10.0
                    // 2. 核心改动：彻底移除圆形滑块（Thumb）
                    thumbShape: SliderComponentShape.noThumb,

                    // 3. 核心改动：点击时不再显示圆形光晕（Overlay）
                    overlayShape: SliderComponentShape.noOverlay,

                    // 4. 调整轨道形状：使用圆角矩形，更 M3
                    trackShape: const RoundedRectSliderTrackShape(),

                    // 气泡样式保持一致
                    showValueIndicator: ShowValueIndicator.onlyForContinuous,
                    valueIndicatorShape: const DropSliderValueIndicatorShape(),
                    // 因为没有滑块，气泡可能需要往上调一点点
                    valueIndicatorColor: cs.primary,
                  ),
                  child: Slider(
                    year2023: false,
                    label: fmt(pos.position),
                    value: value.clamp(0.0, 1.0),
                    // 虽然视觉上没有滑块，但 onChanged 依然有效
                    // 用户点击或拖动整根线条都能跳转进度
                    onChanged: (v) => mp.player.seek(
                      Duration(milliseconds: (durationMs * v).toInt()),
                    ),
                    // 鲜艳模式下使用 primary
                    activeColor: cs.primary,
                    // 未激活部分使用表面色的变体，增加层级感
                    inactiveColor: cs.surfaceContainerHighest,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(fmt(pos.duration), style: _ts(cs)),
            ],
          ),
        );
      },
    );
  }

  TextStyle _ts(ColorScheme cs) => TextStyle(
    fontSize: 11,
    color: cs.onSurfaceVariant,
    fontWeight: FontWeight.w500,
  );
}

/// 音量控制
class _VolumeControllerWidget extends StatelessWidget {

  const _VolumeControllerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final mp = context.read<MusicProvider>();
    final volume = context.select<MusicProvider, double>((p) => p.volume);
    final isMuted = volume == 0.0;

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              // 核心修复：改为 onlyForContinuous，这样连续滑动的 Slider 也会在拖动时显示气泡
              showValueIndicator: ShowValueIndicator.onlyForContinuous,
              // 可选：美化气泡形状（M3 风格）
              valueIndicatorShape: const DropSliderValueIndicatorShape(),
            ),
            child: Slider(
              year2023: false,
              label: "${(volume * 100).toInt()}%",
              value: volume,
              onChanged: (value) {
                mp.setVolume(value);
              },
              activeColor: colorScheme.primary,
              inactiveColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        _MiniIconButton(
          icon: isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
          tooltip: isMuted ? '打开声音' : '静音',
          onPressed: () {
            if (isMuted) {
              mp.setVolume(0.5); // 恢复到中等音量
            } else {
              mp.setVolume(0.0); // 静音
            }
          },
        ),
      ],
    );
  }
}

/// 更多操作：包括播放队列菜单
class _QueueActions extends StatelessWidget {
  final bool showCompactPlayPause;
  final VoidCallback onPlayPause;
  const _QueueActions({
    required this.showCompactPlayPause,
    required this.onPlayPause,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPlaying = context.select<MusicProvider, bool>(
      (p) => p.player.playing,
    );
    final queue = context.select<MusicProvider, List<MusicInfo>>(
      (p) => p.queue,
    );

    final currentMusic = context.select<MusicProvider, MusicInfo?>(
      (p) => p.currentMusic,
    );

    final mp = context.read<MusicProvider>();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showCompactPlayPause)
          _MiniIconButton(
            icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onPressed: onPlayPause,
          ),
        // 点击弹出播放队列菜单
        MenuAnchor(
          menuChildren: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    '播放队列',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${queue.length} 首',
                    style: TextStyle(color: cs.outline),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 300,
              width: 260,
              child: ListView(
                children: queue.asMap().entries.map((entry) {
                  final music = entry.value;
                  final isCurrent = currentMusic?.id == music.id;
                  return MenuItemButton(
                    onPressed: () => mp.playByIndex(entry.key),
                    leadingIcon: isCurrent
                        ? const Icon(Icons.play_arrow_rounded, size: 24)
                        : (music.coverBytes != null &&
                                  music.coverBytes!.isNotEmpty
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      music.coverBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.music_note_rounded, size: 24)),
                    child: Text(
                      music.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          builder: (context, controller, child) {
            return _MiniIconButton(
              icon: Icons.queue_music_rounded,
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 以下为基础 UI 小组件，增加了容错处理
// ---------------------------------------------------------------------------

class _MiniIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final Color? color;
  final String? tooltip;

  const _MiniIconButton({
    required this.icon,
    required this.onPressed,
    this.size = 28,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: size, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final Uint8List? coverBytes;
  const _AlbumArt({this.coverBytes});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: coverBytes != null && coverBytes!.isNotEmpty
          ? Image.memory(coverBytes!, fit: BoxFit.cover)
          : const Icon(Icons.music_note_rounded),
    );
  }
}
