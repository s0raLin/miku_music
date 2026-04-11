import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:myapp/components/BottomBar/index.dart';
import 'package:myapp/components/Header/index.dart';
import 'package:myapp/components/Sidebar/index.dart';
import 'package:myapp/contants/Routes/index.dart';
import 'package:myapp/router/IndexRouter/index.dart';

class MainPage extends StatefulWidget {
  final Widget content;

  const MainPage({super.key, required this.content});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorScheme.surface,
      drawer: Drawer(
        child: Container(
          color: colorScheme.surfaceContainerLow,
          width: 280,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: colorScheme.primaryContainer),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(
                      Icons.music_note,
                      size: 48,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '音乐播放器',
                      style: TextStyle(
                        color: colorScheme.onPrimaryContainer,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
                  appBar: Header(scaffoldKey: _scaffoldKey),
                  body: widget.content,
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
