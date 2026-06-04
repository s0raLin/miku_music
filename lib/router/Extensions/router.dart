import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/UserProvider/index.dart';

extension RouterCtx on BuildContext {
  // ── 绝对根路由 ──
  void toHome() => go('/home');
  void toMusic() => go('/music');
  void toUser() => go('/user');

  // ── 独立根级路由 ──
  void toSettings() => go('/settings');
  void toLogin() => go('/login');
  void toRegister() => go('/register');
  void toAbout() => go('/about');
  void toSearch() => go('/search');

  // ── /user 的子路由（修正了之前不匹配的绝对路径） ──
  void toFiles() => go('/user/files');
  void toRecent() => go('/user/recent');
  void toNetwork() => go('/user/network');

  // ── 登出逻辑（优化参数与 mounted 检查） ──
  Future<void> logout() async {
    // 异步前先拿到 provider
    final userProvider = Provider.of<UserProvider>(this, listen: false);
    userProvider.logout();

    // 异步操作后，必须通过 this.mounted 检查上下文是否依然有效
    if (mounted) {
      go('/login');
    }
  }
}
