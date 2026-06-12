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

    // 改用 showGeneralDialog 实现自定义的左侧滑出面板
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54, // 遮罩层颜色
      transitionDuration: const Duration(milliseconds: 280),
      // 控制从左侧滑出的动画
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(-1.0, 0.0), // 从屏幕左侧外开始
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        );
      },
      pageBuilder: (animationContext, animation, secondaryAnimation) {
        final cs = Theme.of(animationContext).colorScheme;

        return Align(
          alignment: Alignment.centerLeft, // 固定在左侧
          child: Material(
            elevation: 16,
            color: cs.surface,
            // 右侧圆角切边，符合 Material 3 抽屉美学
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Container(
                // 核心改动：使用 Constraints 适配全平台设备
                constraints: const BoxConstraints(
                  minWidth: 280, // 确保在极小设备上也有良好的可读性
                  maxWidth: 320, // 跨平台黄金通用宽度（手机、平板、桌面端均适用）
                ),
                // 让宽度在 minWidth 和 maxWidth 之间根据屏幕大小自动弹性伸缩
                width: MediaQuery.of(animationContext).size.width * 0.75,
                height: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 面板头部标题
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20.0,
                        horizontal: 16.0,
                      ),
                      child: Text(
                        "添加到歌单",
                        style: Theme.of(animationContext).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(height: 1),
                    // 歌单列表
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: userPlaylists.length,
                        itemBuilder: (ctx, index) {
                          final p = userPlaylists[index];
                          final alreadyIn = p.songIds.contains(song.id);
                          return ListTile(
                            enabled: !alreadyIn,
                            leading: const Icon(Icons.playlist_add_rounded),
                            title: Text(
                              p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: alreadyIn
                                ? Icon(Icons.check_circle, color: cs.secondary)
                                : null,
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
