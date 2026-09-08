import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/model/Music/index.dart';
import 'package:myapp/providers/MusicProvider/index.dart';
import 'package:myapp/providers/PlaylistProvider/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:provider/provider.dart';

class MusicActionMenu {
  /// 弹出主更多选项菜单
  static void showMoreOptions(BuildContext context, TapDownDetails details) {
    AdaptiveMenu.show(
      title: "更多选项",
      context,
      details: details,
      items: [
        AdaptiveMenuItem(
          title: "设置进度条样式",
          onTap: () {
            // 💡 延迟错开前一个菜单的 pop 动画，随后拉起二级菜单
            Future.delayed(const Duration(milliseconds: 250), () {
              if (!context.mounted) return;
              _showProgressBarStylesMenu(context, details);
            });
          },
        ),
        AdaptiveMenuItem(
          title: "歌曲信息",
          onTap: () {
            AppToast.neutral(context, message: "暂无歌曲详细信息");
          },
        ),
      ],
    );
  }

  /// 内部私有方法：弹出进度条样式选择菜单
  static void _showProgressBarStylesMenu(
    BuildContext context,
    TapDownDetails details,
  ) {
    AdaptiveMenu.show(
      title: "选择进度条样式",
      context,
      details: details,
      items: [
        AdaptiveMenuItem(
          title: "标准直线",
          onTap: () {
            context.read<ThemeProvider>().setSliderStyle(SliderStyle.straight);
            AppToast.neutral(context, message: "已切换为标准直线");
          },
        ),
        AdaptiveMenuItem(
          title: "波浪",
          onTap: () {
            context.read<ThemeProvider>().setSliderStyle(SliderStyle.wave);
            AppToast.neutral(context, message: "已切换为波浪");
          },
        ),
      ],
    );
  }

  /// 弹出「添加到歌单」左侧面板
  static void showAddToPlaylistSheet(BuildContext context, Music song) {
    final playlistProvider = context.read<PlaylistProvider>();
    final userPlaylists = playlistProvider.userPlaylists;

    if (userPlaylists.isEmpty) {
      AppToast.neutral(context, message: "还没有创建歌单，请先前往「音乐」页创建");
      return;
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(-1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
      pageBuilder: (animationContext, animation, secondaryAnimation) {
        final theme = Theme.of(animationContext);
        final cs = theme.colorScheme;

        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            elevation: 16,
            color: cs.surfaceContainerLow, // M3 侧边抽屉推荐底色
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.horizontal(
                right: Radius.circular(28), // 采用 M3 规范的大圆角
              ),
            ),
            child: SafeArea(
              child: Container(
                constraints: const BoxConstraints(minWidth: 280, maxWidth: 320),
                width: MediaQuery.of(animationContext).size.width * 0.75,
                height: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 面板顶部 Header (包含标题与关闭按钮)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.playlist_add_rounded,
                            color: cs.primary,
                            size: 26,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "添加到歌单",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => Navigator.pop(animationContext),
                            tooltip: "关闭",
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),

                    // 2. 歌单选择列表
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        itemCount: userPlaylists.length,
                        itemBuilder: (ctx, index) {
                          final p = userPlaylists[index];
                          final alreadyIn = p.songIds.contains(song.id);

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: ListTile(
                              enabled: !alreadyIn,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              // 歌单图标/封面占位
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: alreadyIn
                                      ? cs.surfaceContainerHighest.withOpacity(
                                          0.5,
                                        )
                                      : cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.music_note_rounded,
                                  size: 22,
                                  color: alreadyIn
                                      ? cs.onSurfaceVariant.withOpacity(0.5)
                                      : cs.onPrimaryContainer,
                                ),
                              ),
                              title: Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: alreadyIn
                                      ? cs.onSurface.withOpacity(0.38)
                                      : cs.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                "${p.songIds.length} 首歌曲",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: alreadyIn
                                      ? cs.onSurfaceVariant.withOpacity(0.38)
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                              trailing: alreadyIn
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "已添加",
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(color: cs.outline),
                                      ),
                                    )
                                  : Icon(
                                      Icons.add_circle_outline_rounded,
                                      color: cs.primary,
                                      size: 22,
                                    ),
                              onTap: () async {
                                final musicProvider = context
                                    .read<MusicProvider>();
                                await playlistProvider.addToPlaylist(
                                  p.id,
                                  song,
                                  musicProvider: musicProvider,
                                );
                                if (animationContext.mounted) {
                                  Navigator.pop(animationContext);
                                  AppToast.success(
                                    context,
                                    message: '已添加到「${p.name}」',
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
