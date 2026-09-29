import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/Shared/app_empty_state.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AppEmptyState(
          icon: Icons.explore_off_rounded,
          title: '页面不存在',
          subtitle: '你访问的页面可能已被移动或删除',
          action: FilledButton.tonalIcon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_rounded, size: 18),
            label: const Text('返回首页'),
          ),
        ),
      ),
    );
  }
}
