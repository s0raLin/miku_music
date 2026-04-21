import 'package:flutter/material.dart';
import 'package:myapp/router/IndexRouter/index.dart';

class SideBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SideBar({super.key, required this.currentIndex, required this.onTap});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  bool isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(

      extended: false,
      selectedIndex: widget.currentIndex,
      onDestinationSelected: widget.onTap,

      // 顶部标题栏
      leading: FloatingActionButton(
        elevation: 0,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),

      // 导航项转换
      destinations: navItems.map((item) {
        return NavigationRailDestination(
          // 选中时使用填色图标，未选中时使用描边图标
          icon: Icon(item.icon),
          selectedIcon: Icon(item.icon),
          label: Text(item.label),
        );
      }).toList(),

      labelType: NavigationRailLabelType.all,
    );
  }
}
