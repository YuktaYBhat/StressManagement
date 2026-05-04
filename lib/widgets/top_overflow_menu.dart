import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';

class TopOverflowMenu extends StatelessWidget {
  const TopOverflowMenu({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) async {
        if (value == 'settings') {
          if (currentRoute != '/profile') {
            Navigator.of(context).pushReplacementNamed('/profile');
          }
          return;
        }
        if (value == 'logout') {
          await context.read<AppStateProvider>().signOut();
          if (!context.mounted) {
            return;
          }
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem<String>(value: 'settings', child: Text('Settings')),
        PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
      ],
    );
  }
}
