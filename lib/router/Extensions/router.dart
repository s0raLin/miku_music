import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:myapp/providers/UserProvider/index.dart';

extension RouterCtx on BuildContext {
  void toSettings() => go('/settings');
  void toHome() => go('/home');
  void toMusic() => go('/music');
  void toFiles() => go("/files");
  void toLogin() => go("/login");
  void toRegister() => go("/register");
  void toAbout() => go('/about');
  void toRecent() => go('/user/recent');

  Future<void> logout(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.logout();
    if (mounted) {
      go('/login');
    }
  }
}
