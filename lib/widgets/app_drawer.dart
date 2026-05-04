import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final items = <_DrawerItem>[
      const _DrawerItem(
        label: 'Home',
        icon: Icons.home_rounded,
        route: '/home',
      ),
      const _DrawerItem(
        label: 'Analytics',
        icon: Icons.show_chart_rounded,
        route: '/analytics',
      ),
      const _DrawerItem(
        label: 'Recommendations',
        icon: Icons.recommend_rounded,
        route: '/recommendations',
      ),
      const _DrawerItem(
        label: 'Activity Monitor',
        icon: Icons.timer_rounded,
        route: '/activity',
      ),
      const _DrawerItem(
        label: 'Profile',
        icon: Icons.person_rounded,
        route: '/profile',
      ),
      const _DrawerItem(
        label: 'History',
        icon: Icons.history_rounded,
        route: '/history',
      ),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.person, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    appState.userDisplayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text('Mindfulness Explorer'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...items.map((item) {
              final selected = currentRoute == item.route;
              return ListTile(
                selected: selected,
                selectedTileColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(item.icon),
                title: Text(item.label),
                onTap: () {
                  Navigator.of(context).pop();
                  if (currentRoute != item.route) {
                    Navigator.of(context).pushReplacementNamed(item.route);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
