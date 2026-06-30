// ---------------------------------------------------------------------------
// 统一圆角常量 — M3 Shape Scale (重设计版: 更柔和、更大的圆角)
// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';

abstract final class AppRadius {
  /// M3 Large (Card 默认): 24dp — 柔和大圆角
  static const double card = 24;

  /// M3 Medium (内嵌图像/头像/panel): 16dp
  static const double inner = 16;

  /// M3 Small (label/chip): 8dp
  static const double sm = 8;

  /// Pill/Stadium: 全圆角
  static const double full = 999;

  static BorderRadius get cardBR => BorderRadius.circular(card);
  static BorderRadius get innerBR => BorderRadius.circular(inner);
  static BorderRadius get pillBR => BorderRadius.circular(full);
}
