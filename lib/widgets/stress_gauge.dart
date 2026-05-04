import 'dart:math' as math;

import 'package:flutter/material.dart';

class StressGauge extends StatelessWidget {
  const StressGauge({super.key, required this.score, required this.level});

  final int score;
  final String level;

  @override
  Widget build(BuildContext context) {
    final progress = (score / 100).clamp(0.0, 1.0);

    return SizedBox(
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -math.pi,
            child: SizedBox(
              height: 160,
              width: 160,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: 12,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
          Transform.rotate(
            angle: -math.pi,
            child: SizedBox(
              height: 160,
              width: 160,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 12,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(level, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

