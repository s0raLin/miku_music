import 'package:flutter/material.dart';
import 'package:myapp/contants/Routes/index.dart';

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      elevation: 0,
      height: 65,
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.secondaryContainer,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: customNavItems.map((item) {
        return NavigationDestination(
          icon: Icon(item.icon, size: 36),
          selectedIcon: Icon(item.icon, size: 36),
          label: item.label,
        );
      }).toList(),
    );
  }
}
