import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StressTrendChart extends StatelessWidget {
  const StressTrendChart({super.key, required this.data});

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          lineTouchData: const LineTouchData(enabled: true),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
              ],
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

