import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension RouterCtx on BuildContext {
  void toSettings() => this.go('/settings');
  void toHome() => this.go('/home');
  void toMusic() => this.go('/music');
}
