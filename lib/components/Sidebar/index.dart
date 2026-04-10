import 'package:flutter/material.dart';
import 'package:myapp/contants/Routes/index.dart';

class Sidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const Sidebar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.selected,
      minWidth: 80,
      indicatorColor: colorScheme.secondaryContainer,
      destinations: customNavItems.map((item) {
        return NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.icon),
          label: Text(item.label),
        );
      }).toList(),
    );
  }
}
