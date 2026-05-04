import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/stress_gauge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        return AppScaffold(
          title: 'Home',
          currentRoute: '/home',
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
                        Text(
                          appState.greeting,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Stress Score',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        StressGauge(
                          score: appState.stressScore,
                          level: appState.stressLevel,
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            appState.lastUpdatedLabel,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (appState.statusMessage.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            appState.statusMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () =>
                                context.read<AppStateProvider>().refreshData(),
                            child: const Text('Refresh Data'),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed('/analytics'),
                            child: const Text('View Details'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _MetricTile(
                          label: 'Heart Rate',
                          value: '${appState.heartRate} bpm',
                          icon: Icons.favorite,
                        ),
                        const Divider(),
                        _MetricTile(
                          label: 'Steps',
                          value: '${appState.steps}',
                          icon: Icons.directions_walk,
                        ),
                        const Divider(),
                        _MetricTile(
                          label: 'Sleep',
                          value: '${appState.sleepHours} hrs',
                          icon: Icons.bedtime,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent History',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (appState.history.isEmpty)
                          const Text(
                            'No stress snapshots yet. Data appears after the first refresh.',
                          ),
                        ...appState.history
                            .take(3)
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  '${entry.dayLabel}: Stress ${entry.stressScore} (${entry.level}) - ${entry.note}',
                                ),
                              ),
                            ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed('/history'),
                            child: const Text('Open History'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
