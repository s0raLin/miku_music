import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/router/IndexRouter/index.dart';
import 'package:provider/provider.dart';

class Header extends StatefulWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const Header({super.key, this.scaffoldKey});

  @override
  State<Header> createState() => _HeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _HeaderState extends State<Header> {
  @override
  Widget build(BuildContext context) {
    final router = context.read<GoRouter>();
    final routeName = router.state.name ?? "未知";
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      centerTitle: true,
      elevation: 0,
      leading: IconButton(
        onPressed: () {
          widget.scaffoldKey?.currentState?.openDrawer();
        },
        icon: Icon(Icons.menu, color: colorScheme.onSurface),
      ),
      title: Text(
        routeName,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(Icons.search, color: colorScheme.onSurface),
        ),
        IconButton(
          onPressed: () => context.toSettings(),
          icon: Icon(Icons.settings, color: colorScheme.onSurface),
        ),
      ],
    );
  }
}
