import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state_provider.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/charts/activity_vs_stress_chart.dart';
import '../widgets/charts/sleep_vs_stress_chart.dart';
import '../widgets/charts/stress_trend_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _range = 'day';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();
    final data = appState.analyticsDataFor(_range);

    return AppScaffold(
      title: 'Analytics',
      currentRoute: '/analytics',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stress Trends & Patterns', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _RangeChip(label: 'Day', value: 'day', groupValue: _range, onTap: _updateRange),
                        _RangeChip(label: 'Week', value: 'week', groupValue: _range, onTap: _updateRange),
                        _RangeChip(label: 'Month', value: 'month', groupValue: _range, onTap: _updateRange),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Stress Trend', style: TextStyle(fontWeight: FontWeight.w600)),
                    StressTrendChart(data: data.stressTrend),
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
                    const Text('Activity vs. Stress (Strong Negative Correlation)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ActivityVsStressChart(data: data.activityVsStress),
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
                    const Text('Sleep vs. Stress (Positive Correlation)', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SleepVsStressChart(data: data.sleepVsStress),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateRange(String value) {
    setState(() {
      _range = value;
    });
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onTap,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: groupValue == value,
      onSelected: (_) => onTap(value),
    );
  }
}

