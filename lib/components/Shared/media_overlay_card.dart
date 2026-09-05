import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/app_radius.dart';
import 'package:myapp/model/Music/index.dart'; 

class MediaOverlayCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final MusicSource source; // 新增：显式传入歌曲来源类型
  final Uint8List? coverBytes;
  final String? coverPath;
  final String? coverUrl;
  final Map<String, String>? coverHeaders;
  final IconData fallbackIcon;
  final VoidCallback? onTap;
  final Widget? badge;
  final bool isLoading;
  final BorderRadius? borderRadius;

  const MediaOverlayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.source,
    this.coverBytes,
    this.coverPath,
    this.coverUrl,
    this.coverHeaders,
    required this.fallbackIcon,
    this.onTap,
    this.badge,
    this.isLoading = false,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 根据来源类型，精准判定是否存在有效封面
    final bool hasCover = source == MusicSource.network
        ? (coverUrl != null && coverUrl!.isNotEmpty)
        : ((coverBytes != null && coverBytes!.isNotEmpty) ||
              (coverPath != null && coverPath!.isNotEmpty));

    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.card),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 根据 source 条件分发到对应独立的 Cover 组件
              _buildCoverWidget(cs),

              // 仅在存在封面时渲染渐变遮罩
              if (hasCover)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),

              // 文字信息层
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasCover ? Colors.white : cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasCover
                            ? Colors.white.withValues(alpha: 0.85)
                            : cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              if (badge != null) Positioned(top: 10, right: 10, child: badge!),
            ],
          ),
        ),
      ),
    );
  }

  /// 根据 source 进行组件路由
  Widget _buildCoverWidget(ColorScheme cs) {
    if (source == MusicSource.network) {
      return _NetworkCover(
        coverUrl: coverUrl,
        headers: coverHeaders,
        placeholder: _buildFallback(cs),
      );
    } else {
      return _LocalCover(
        coverBytes: coverBytes,
        coverPath: coverPath,
        placeholder: _buildFallback(cs),
      );
    }
  }

  Widget _buildFallback(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: isLoading
          ? Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              ),
            )
          : Icon(fallbackIcon, size: 44, color: cs.primary),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 1. 网络封面专用组件
// ═══════════════════════════════════════════════════════════
class _NetworkCover extends StatelessWidget {
  final String? coverUrl;
  final Map<String, String>? headers;
  final Widget placeholder;

  const _NetworkCover({this.coverUrl, this.headers, required this.placeholder});

  @override
  Widget build(BuildContext context) {
    if (coverUrl == null || coverUrl!.isEmpty) {
      return placeholder;
    }

    final Map<String, String> requestHeaders = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      ...?headers,
    };

    return CachedNetworkImage(
      key: ValueKey('net_cover_$coverUrl'),
      cacheKey: coverUrl,
      imageUrl: coverUrl!,
      fit: BoxFit.cover,
      httpHeaders: requestHeaders,
      fadeInDuration: Duration.zero, // 命中磁盘/内存缓存时不动画，防止无意义闪烁
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 2. 本地封面专用组件 (内嵌字节 / 本地文件路径)
// ═══════════════════════════════════════════════════════════
class _LocalCover extends StatelessWidget {
  final Uint8List? coverBytes;
  final String? coverPath;
  final Widget placeholder;

  const _LocalCover({
    this.coverBytes,
    this.coverPath,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    // 优先 1：应用内直接传来的 ID3/FLAC 二进制 Tag 封面
    if (coverBytes != null && coverBytes!.isNotEmpty) {
      return Image.memory(
        coverBytes!,
        key: ValueKey('bytes_cover_${coverBytes.hashCode}'),
        fit: BoxFit.cover,
        gaplessPlayback: true, // 防闪烁：构建期间保留最后一帧画面
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    // 优先 2：本地储存的文件地址 (.jpg / .png)
    if (coverPath != null && coverPath!.isNotEmpty) {
      return Image.file(
        File(coverPath!),
        key: ValueKey('file_cover_$coverPath'),
        fit: BoxFit.cover,
        gaplessPlayback: true, // 防闪烁
        errorBuilder: (_, _, _) => placeholder,
      );
    }

    return placeholder;
  }
}
