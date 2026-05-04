import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../widgets/app_scaffold.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return AppScaffold(
      title: 'History',
      currentRoute: '/history',
      body: appState.history.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No history yet. Recent stress snapshots will appear here.'),
              ),
            )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.history.length,
        itemBuilder: (context, index) {
          final entry = appState.history[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              leading: const CircleAvatar(child: Icon(Icons.calendar_month)),
              title: Text('${entry.dayLabel} - Stress Score ${entry.stressScore} (${entry.level})'),
              subtitle: Text(entry.note),
            ),
          );
        },
      ),
    );
  }
}

