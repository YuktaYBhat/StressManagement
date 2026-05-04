import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../widgets/app_scaffold.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final totalSeconds = appState.activeDuration.inSeconds;
    final progress = ((totalSeconds % 3600) / 3600).clamp(0.0, 1.0);

    return AppScaffold(
      title: 'Activity Monitor',
      currentRoute: '/activity',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    SizedBox(
                      height: 220,
                      width: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: -math.pi / 2,
                            child: CircularProgressIndicator(
                              value: 1,
                              strokeWidth: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                          Transform.rotate(
                            angle: -math.pi / 2,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 11,
                              color: Theme.of(context).colorScheme.primary,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                          Text(
                            _formatDuration(appState.activeDuration),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeInfoCard(
                            title: 'Active Duration',
                            value: _formatDuration(appState.activeDuration),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _TimeInfoCard(
                            title: 'Today Steps',
                            value: '${appState.steps}',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: appState.isSessionRunning
                            ? context.read<AppStateProvider>().stopSession
                            : context.read<AppStateProvider>().startSession,
                        child: Text(
                          appState.isSessionRunning ? 'Stop' : 'Start',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: context
                            .read<AppStateProvider>()
                            .resetSession,
                        child: const Text('Reset Session'),
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
  }

  String _formatDuration(Duration duration) {
    String two(int value) => value.toString().padLeft(2, '0');
    final hours = two(duration.inHours);
    final minutes = two(duration.inMinutes.remainder(60));
    final seconds = two(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}

class _TimeInfoCard extends StatelessWidget {
  const _TimeInfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
