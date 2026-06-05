import 'package:flutter/material.dart';
import 'package:myapp/src/rust/api/hotkey.dart';

class HotkeyService {
  static final HotkeyService _instance = HotkeyService._internal();
  factory HotkeyService() => _instance;
  HotkeyService._internal();

  bool _isInitialized = false;

  /// 启动 Rust 端的热键监听
  void init({
    required VoidCallback onTogglePlay,
    required VoidCallback onNextTrack,
    required VoidCallback onPrevTrack,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // 调用 Rust 函数，并像听收音机一样监听返回的 Stream
      initNativeHotkeys().listen(
        (event) {
          debugPrint("收到来自 Rust 底层的热键事件: $event");

          switch (event) {
            case 'toggle_play':
              onTogglePlay();
              break;
            case 'next_track':
              onNextTrack();
              break;
            case 'prev_track':
              onPrevTrack();
              break;
          }
        },
        onError: (err) {
          debugPrint("Rust 热键流发生异常: $err");
        },
      );
    } catch (e) {
      debugPrint("初始化 Rust 热键失败: $e");
    }
  }
}
