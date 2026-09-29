// ---------------------------------------------------------------------------
// 统一圆角常量 — M3 Shape Scale (重设计版: 更柔和、更大的圆角)
// ---------------------------------------------------------------------------
// 提供从「极小」到「全圆角」的完整刻度，替代散落在各页面中的硬编码圆角，
// 保证全 App 圆角节奏一致、可维护。
// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';

abstract final class AppRadius {
  /// 极小 (badge / 进度点): 6dp
  static const double xs = 6;

  /// 小 (chip / 按钮): 10dp
  static const double sm = 10;

  /// 中 (输入框 / 内嵌小块): 14dp
  static const double md = 14;

  /// M3 Medium (内嵌图像/头像/panel): 16dp
  static const double inner = 16;

  /// 大 (快捷入口 / 小组件): 20dp
  static const double lg = 20;

  /// M3 Large (Card 默认): 28dp — 柔和大圆角
  static const double card = 28;

  /// 超大 (大幅海报/面板): 32dp
  static const double xl = 32;

  /// Pill/Stadium: 全圆角
  static const double full = 999;

  static BorderRadius get xsBR => BorderRadius.circular(xs);
  static BorderRadius get smBR => BorderRadius.circular(sm);
  static BorderRadius get mdBR => BorderRadius.circular(md);
  static BorderRadius get innerBR => BorderRadius.circular(inner);
  static BorderRadius get lgBR => BorderRadius.circular(lg);
  static BorderRadius get cardBR => BorderRadius.circular(card);
  static BorderRadius get xlBR => BorderRadius.circular(xl);
  static BorderRadius get pillBR => BorderRadius.circular(full);
}
