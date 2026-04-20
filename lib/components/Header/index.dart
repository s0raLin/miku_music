import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Header extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Color? backgroundColor;

  const Header({super.key, this.scaffoldKey, this.backgroundColor});

  @override
  State<Header> createState() => _HeaderState();
}

class _HeaderState extends State<Header> {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: widget.backgroundColor ?? colorScheme.surface,
      centerTitle: true,
      elevation: 0,
      surfaceTintColor: colorScheme.surface,
      leading: IconButton(
        onPressed: () {
          widget.scaffoldKey?.currentState?.openDrawer();
        },
        icon: Icon(Icons.menu, color: colorScheme.onSurface),
      ),
      title: SearchAnchor(
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            //去除阴影
            elevation: const WidgetStatePropertyAll(0),
            //调整高度
            constraints: const BoxConstraints(minHeight: 45.0, maxHeight: 45.0),
            controller: controller,
            padding: const WidgetStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 16.0),
            ),
            onTap: () {
              controller.openView();
            },
            leading: const Icon(Icons.search),
            hintText: "搜索",
          );
        },
        suggestionsBuilder:
            (BuildContext context, SearchController controller) {
              // 这里返回搜索建议列表
              return List<ListTile>.generate(5, (int index) {
                final String item = '建议项 $index';
                return ListTile(
                  title: Text(item),
                  onTap: () {
                    controller.closeView(item);
                  },
                );
              });
            },
      ),
      actions: [
        IconButton(
          onPressed: () {
            context.push("/settings");
          },
          icon: Icon(Icons.settings, color: colorScheme.onSurface),
        ),
      ],
    );
  }
}
