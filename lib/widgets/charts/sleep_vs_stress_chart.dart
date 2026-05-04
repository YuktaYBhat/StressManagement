import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SleepVsStressChart extends StatelessWidget {
  const SleepVsStressChart({super.key, required this.data});

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
              ],
              isCurved: true,
              color: Theme.of(context).colorScheme.secondary,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

