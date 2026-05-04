import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final appState = context.watch<AppStateProvider>();

    return AppScaffold(
      title: 'Profile',
      currentRoute: '/profile',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      child: Icon(Icons.person, size: 40),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      appState.userDisplayName,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text('Mindfulness explorer - Since Jan. 2024'),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WEEKLY GOAL PROGRESS',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (appState.steps / 10000).clamp(0.0, 1.0),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(appState.steps / 10000 * 100).clamp(0, 100).round()}%  |  Stress: ${appState.stressLevel}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Wellness Report'),
                    subtitle: const Text('Monthly mental health summary'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('History'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.of(context).pushReplacementNamed('/history'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Personal Details'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('General'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_none),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.dark_mode_outlined),
                    title: const Text('Dark Mode'),
                    value: themeProvider.isDarkMode,
                    onChanged: context.read<ThemeProvider>().toggleDarkMode,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
