import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Header extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const Header({super.key, this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          scaffoldKey?.currentState?.openDrawer();
        },
        icon: const Icon(Icons.menu),
      ),
      title: SearchAnchor(
        builder: (BuildContext context, SearchController controller) {
          return SearchBar(
            elevation: const WidgetStatePropertyAll(0),
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
          icon: const Icon(Icons.settings),
        ),
      ],
    );
  }
}
