import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/model/Toplist/index.dart';

class ToplistCard extends StatelessWidget {
  final ToplistInfo info;
  final VoidCallback? onTap;

  const ToplistCard({
    super.key,
    required this.info,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap ?? () => context.push('/toplist'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 封面 — CachedNetworkImage 解决 163 CDN 防盗链
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: info.cover,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  httpHeaders: const {
                    'Referer': 'https://music.163.com/',
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
                  },
                  placeholder: (_, _) => Container(
                    width: 64,
                    height: 64,
                    color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  ),
                  errorWidget: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.music_note_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 文字信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      info.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info.description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${info.count} 首歌曲',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // 箭头
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
