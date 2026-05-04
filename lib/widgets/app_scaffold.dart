import 'package:flutter/material.dart';

import 'app_drawer.dart';
import 'top_overflow_menu.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.body,
    this.floatingActionButton,
  });

  final String title;
  final String currentRoute;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentRoute: currentRoute),
      appBar: AppBar(
        title: Text(title),
        actions: [TopOverflowMenu(currentRoute: currentRoute)],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(child: body),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

