import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ActivityVsStressChart extends StatelessWidget {
  const ActivityVsStressChart({super.key, required this.data});

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: 100,
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
          titlesData: const FlTitlesData(show: true),
          barGroups: [
            for (int i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i],
                    color: Theme.of(context).colorScheme.tertiary,
                    width: 10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

