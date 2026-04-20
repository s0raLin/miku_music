import 'package:flutter/material.dart';
import 'package:myapp/router/IndexRouter/index.dart';

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: navItems.map((item) {
        return NavigationDestination(
          tooltip: item.label,
          icon: item.i!,
          selectedIcon: Icon(item.icon),
          label: item.label,
        );
      }).toList(),
    );
  }
}
