import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/album_art_image.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';

import 'package:provider/provider.dart';

/// 沉浸式封面背景
///
/// 视觉原则：
///
///     封面 = 色彩
///     底色 = 明度
///     渐变 = 可读性
///
/// 不制造中心光圈，不制造明显暗角。
/// 让整个背景成为一个统一的“环境色层”。
class BlurCoverBackground extends StatelessWidget {
  final Music music;
  final Widget child;

  const BlurCoverBackground({
    super.key,
    required this.music,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final provider = context.watch<MusicProvider>();
    final coverUrl = provider.getCoverUrl(music.id);

    final hasCover =
        music.coverBytes?.isNotEmpty == true || coverUrl?.isNotEmpty == true;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ------------------------------------------------------------
        // 基础色
        // ------------------------------------------------------------
        ColoredBox(
          color: isDark ? const Color(0xFF101114) : const Color(0xFFF3F4F6),
        ),

        if (hasCover) _AmbientCover(music: music, isDark: isDark),

        // ------------------------------------------------------------
        // 内容
        // ------------------------------------------------------------
        child,
      ],
    );
  }
}

class _AmbientCover extends StatelessWidget {
  final Music music;
  final bool isDark;

  const _AmbientCover({required this.music, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ==========================================================
          // 1. 封面环境层
          //
          // 不是为了“看见封面”
          // 而是提取封面的整体色彩。
          //
          // blur 不宜太大。
          // ==========================================================
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Transform.scale(
                scale: 1.12,
                child: Opacity(
                  opacity: isDark ? 0.38 : 0.20,
                  child: AlbumArtImage(
                    key: ValueKey('ambient_${music.id}'),
                    music: music,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // ==========================================================
          // 2. 统一明度层
          //
          // 这是整个效果最重要的一层。
          //
          // 暗色：
          //     把所有封面颜色拉回深色空间
          //
          // 浅色：
          //     把所有封面颜色拉回浅色空间
          //
          // 所以无论什么封面，都不会突然蹦出特别亮/特别脏的颜色。
          // ==========================================================
          Positioned.fill(
            child: ColoredBox(
              color: isDark ? const Color(0x7A101114) : const Color(0xC2F3F4F6),
            ),
          ),

          // ==========================================================
          // 3. 顶部保护层
          //
          // 只处理顶部，不影响中间。
          // ==========================================================
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: isDark
                      ? const [Color(0x35101114), Color(0x00101114)]
                      : const [Color(0x20F3F4F6), Color(0x00F3F4F6)],
                ),
              ),
            ),
          ),

          // ==========================================================
          // 4. 底部保护层
          //
          // 播放进度、按钮、歌词等通常位于这里。
          // ==========================================================
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [Color(0x00101114), Color(0xB8101114)]
                      : const [Color(0x00F3F4F6), Color(0xE6F3F4F6)],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ==========================================================
          // 5. 最后统一一层非常轻的雾
          //
          // 消除不同封面之间的视觉差异。
          // ==========================================================
          Positioned.fill(
            child: ColoredBox(
              color: isDark ? const Color(0x0DFFFFFF) : const Color(0x0AFFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
