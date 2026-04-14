import 'package:flutter/material.dart';

import 'package:myapp/router/IndexRouter/index.dart';

class Sidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const Sidebar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRailTheme(
      data: NavigationRailThemeData(
        // 继承 titleLarge 的所有属性，只覆盖颜色和粗细
        unselectedLabelTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        selectedLabelTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.primary, // 选中文字变色
          fontWeight: FontWeight.bold,
        ),
        // 2. 图标样式
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: 28,
        ),
        selectedIconTheme: IconThemeData(
          color: colorScheme.onPrimaryContainer,
          size: 28,
        ),
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.secondaryContainer,
      ),
      child: NavigationRail(
        extended: true,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => onTap(index),
        leading: const Padding(
          padding: EdgeInsets.only(top: 10, bottom: 10),
          child: Text(
            "Miku Music",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        destinations: navItems.map((item) {
          return NavigationRailDestination(
            icon: item.i!,
            label: Text(item.label),
          );
        }).toList(),
      ),
    );
  }
}
