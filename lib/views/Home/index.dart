import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Text(
          "Home",
          style: TextStyle(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}
