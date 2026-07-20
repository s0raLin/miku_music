// ─── 可复用：专辑封面图片 ─────────────────────────────────────────────────────
//  统一处理 内存字节 / 网络 URL / 兜底图标 三种来源，供播放详情、队列、CoverFlow 复用。
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:provider/provider.dart';

class AlbumArtImage extends StatelessWidget {
  final Music music;
  final BoxFit fit;
  final double? size;

  const AlbumArtImage({
    super.key,
    required this.music,
    this.fit = BoxFit.cover,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mp = Provider.of<MusicProvider>(context, listen: false);

    final coverUrl = mp.getCoverUrl(music.id);
    final hasUrl = coverUrl != null && coverUrl.isNotEmpty;

    final placeholder = _PlaceholderArt(cs: cs, size: size);

    if (music.coverBytes?.isNotEmpty == true) {
      return Image.memory(music.coverBytes!, fit: fit);
    }
    if (hasUrl) {
      final url = coverUrl;
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        httpHeaders:
            url.contains('music.126.net')
                ? {'Referer': 'https://music.163.com/'}
                : {},
        fadeInDuration: const Duration(milliseconds: 250),
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      );
    }
    return placeholder;
  }
}

class _PlaceholderArt extends StatelessWidget {
  final ColorScheme cs;
  final double? size;
  const _PlaceholderArt({required this.cs, this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.music_note_rounded,
        size: (size ?? double.infinity) * 0.32,
        color: cs.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
