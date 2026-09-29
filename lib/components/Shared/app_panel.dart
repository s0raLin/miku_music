import 'package:flutter/material.dart';
import 'package:myapp/components/Shared/app_radius.dart';

class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final BorderRadius? borderRadius;
  final bool bordered;
  final double elevation;

  const AppPanel({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius,
    this.bordered = false,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card.filled(
      margin: EdgeInsets.zero,
      elevation: elevation,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black,
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? AppRadius.cardBR,
        side: bordered
            ? BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              )
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: colorScheme.onSurface.withValues(alpha: 0.04),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(12),
          child: child,
        ),
      ),
    );
  }
}
