import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../widgets/app_scaffold.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return AppScaffold(
      title: 'Recommendations',
      currentRoute: '/recommendations',
      body: appState.recommendations.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Recommendations appear after your first data refresh.'),
              ),
            )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: appState.recommendations.length,
        itemBuilder: (context, index) {
          final item = appState.recommendations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Trigger: ${item.trigger}'),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () => context.read<AppStateProvider>().toggleRecommendationDone(item.id),
                      style: FilledButton.styleFrom(
                        backgroundColor: item.isDone ? Colors.green.shade700 : null,
                      ),
                      child: Text(item.isDone ? 'Completed' : 'Mark as Done'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

