import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/index.dart';
import 'package:myapp/providers/ThemeProvider/index.dart';
import 'package:provider/provider.dart';
// import 'package:myapp/providers/ThemeProvider/index.dart';
// import 'package:provider/provider.dart';

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
}
