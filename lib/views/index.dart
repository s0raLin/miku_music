import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/BottomBar/index.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/Sidebar/index.dart';
import 'package:myapp/contants/Routes/index.dart';

class MainPage extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainPage({super.key, required this.navigationShell});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  var _currentIndex = 0;
  void onTabChanged(int idx) {
    _currentIndex = idx;
    context.go(customNavItems[idx].path);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const maxWidth = 800;
    final colorScheme = Theme.of(context).colorScheme;
    // final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isLargeScreen = constraints.maxWidth >= maxWidth;

          return Row(
            children: [
              if (isLargeScreen)
                Sidebar(currentIndex: _currentIndex, onTap: onTabChanged),
              Expanded(
                child: Scaffold(
                  backgroundColor: colorScheme.surface,
                  appBar: Header(),
                  body: widget.navigationShell,
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= maxWidth) {
            return const SizedBox.shrink();
          }
          return BottomBar(currentIndex: _currentIndex, onTap: onTabChanged);
        },
      ),
    );
  }
}
