// ─── 可复用：沉浸式顶部条 ───────────────────────────────────────────────────
//  替代传统 AppBar 标题，仅保留「返回」手柄与右侧操作图标，
//  将标题与元信息下沉到封面下方，强化沉浸式全屏播放器观感。
//  按钮遵循 MD3E：透明背景的图标按钮（onSurface / primary），
//  不附加额外的圆形底色，避免压在模糊背景上时产生脏乱的玻璃块。
import 'package:flutter/material.dart';

class ImmersiveTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final List<Widget> actions;
  final EdgeInsets padding;

  const ImmersiveTopBar({
    super.key,
    required this.onBack,
    this.actions = const [],
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 52,
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: cs.onSurface),
              onPressed: onBack,
              tooltip: '收起',
            ),
            const Spacer(),
            ...actions,
          ],
        ),
      ),
    );
  }
}

/// 顶部条右侧的 MD3E 图标按钮：透明背景，仅以颜色表达状态
class ImmersiveIconButton extends StatelessWidget {
  final GestureTapDownCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color? color;

  const ImmersiveIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: IconButton(
        icon: Icon(icon, color: color ?? cs.onSurface),
        onPressed: () => onPressed(TapDownDetails()),
        tooltip: tooltip,
      ),
    );
  }
}
