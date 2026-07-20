// ─── 可复用：沉浸式模糊封面背景 ───────────────────────────────────────────
//  以当前歌曲封面作为模糊背景，叠加 theme surface 的径向收拢，
//  制造现代的「沉浸全屏播放器」质感。无封面时回退到 surface 渐变。
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/album_art_image.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

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
    final cs = Theme.of(context).colorScheme;
    final mp = Provider.of<MusicProvider>(context, listen: false);
    final coverUrl = mp.getCoverUrl(music.id);
    final hasCover =
        (music.coverBytes?.isNotEmpty ?? false) ||
        (coverUrl != null && coverUrl.isNotEmpty);
    final isDark = cs.brightness == Brightness.dark;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 模糊封面
        if (hasCover)
          Positioned.fill(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AlbumArtImage(music: music, fit: BoxFit.cover),
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                // 统一 surface 蒙层：整页内容落在一块一致、可控对比度的
                // 表面上（MD3E：内容置于 scrim 之上，而非直接压在照片上）。
                // 使用 surfaceContainer 与 onSurface 混合，保证深浅主题都可读。
                Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.7)
                      : cs.surface.withValues(alpha: 0.82),
                ),
              ],
            ),
          )
        else
          Container(color: cs.surface),

        child,
      ],
    );
  }
}
