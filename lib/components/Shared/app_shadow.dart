// ---------------------------------------------------------------------------
// 统一柔和阴影常量 — 精致层次体系
// ---------------------------------------------------------------------------
// 主题整体是扁平 M3 柔色风，这里提供一组「极浅」的环境阴影，
// 用于卡片、面板与悬浮态的层次表达，避免生硬的黑影。
// 暗色模式下阴影不可见也无妨 —— 层次感主要依赖容器色阶。
// ---------------------------------------------------------------------------
import 'package:flutter/material.dart';

abstract final class AppShadow {
  /// 静态卡片：极浅环境阴影
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
  ];

  /// 悬浮态 (桌面 hover / 弹层)：稍强的上浮阴影
  static const List<BoxShadow> hover = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  /// 高浮层 (弹窗 / 播放胶囊)：最明显的阴影
  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 32,
      offset: Offset(0, 14),
    ),
  ];
}
