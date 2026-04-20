import 'package:flutter/material.dart';
import 'package:myapp/router/IndexRouter/index.dart';

class SideBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SideBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: NavigationDrawer(
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 20, 16, 10),
            child: Text(
              "Miku Music",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 10),
          ...navItems.asMap().entries.map((entry) {
            final item = entry.value;
            return NavigationDrawerDestination(
              icon: item.i!,
              label: Text(item.label),
              selectedIcon: Icon(item.icon),
            );
          }),
        ],
      ),
    );
  }
}
