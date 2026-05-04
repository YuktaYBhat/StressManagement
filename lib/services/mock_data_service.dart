import 'dart:math';

import '../models/analytics_data.dart';
import '../models/history_entry.dart';
import '../models/recommendation_item.dart';

class MockDataService {
  final Random _random = Random();

  int randomStressScore() => 35 + _random.nextInt(46);

  int randomHeartRate() => 62 + _random.nextInt(38);

  int randomSteps() => 2800 + _random.nextInt(7200);

  double randomSleepHours() {
    final value = 4.5 + _random.nextDouble() * 4.0;
    return double.parse(value.toStringAsFixed(1));
  }

  List<RecommendationItem> defaultRecommendations() {
    return const [
      RecommendationItem(
        id: 'r1',
        title: 'Try Deep Breathing',
        trigger: 'Moderate stress',
      ),
      RecommendationItem(
        id: 'r2',
        title: 'Go for a Walk',
        trigger: 'Prolonged inactivity',
      ),
      RecommendationItem(
        id: 'r3',
        title: 'Schedule Bedtime',
        trigger: 'Irregular sleep patterns',
      ),
      RecommendationItem(
        id: 'r4',
        title: 'Hydration Break',
        trigger: 'High heart rate',
      ),
    ];
  }

  List<HistoryEntry> defaultHistory() {
    return const [
      HistoryEntry(
        dayLabel: 'Oct 28',
        stressScore: 61,
        level: 'Elevated',
        note: 'Trigger: Work meeting',
      ),
      HistoryEntry(
        dayLabel: 'Oct 28',
        stressScore: 55,
        level: 'Moderate',
        note: 'Walk completed',
      ),
      HistoryEntry(
        dayLabel: 'Oct 27',
        stressScore: 55,
        level: 'Low',
        note: 'Walk completed',
      ),
      HistoryEntry(
        dayLabel: 'Oct 26',
        stressScore: 48,
        level: 'Low',
        note: 'Deep breathing done',
      ),
      HistoryEntry(
        dayLabel: 'Oct 25',
        stressScore: 72,
        level: 'High',
        note: 'Sleep: 4 hours',
      ),
      HistoryEntry(
        dayLabel: 'Oct 24',
        stressScore: 52,
        level: 'Moderate',
        note: 'Hydration break logged',
      ),
    ];
  }

  AnalyticsData analyticsForRange(String range) {
    switch (range) {
      case 'day':
        return const AnalyticsData(
          stressTrend: [42, 35, 40, 58, 62, 52, 58],
          activityVsStress: [88, 82, 78, 72, 70, 66, 62],
          sleepVsStress: [24, 30, 35, 40, 42, 46, 52],
        );
      case 'week':
        return const AnalyticsData(
          stressTrend: [52, 44, 56, 62, 48, 58, 54],
          activityVsStress: [92, 85, 82, 76, 70, 68, 63],
          sleepVsStress: [30, 38, 40, 48, 55, 60, 66],
        );
      case 'month':
      default:
        return const AnalyticsData(
          stressTrend: [48, 62, 58, 44, 55, 60, 52],
          activityVsStress: [90, 84, 80, 74, 72, 69, 64],
          sleepVsStress: [28, 36, 42, 54, 60, 68, 72],
        );
    }
  }

  HistoryEntry buildNewHistoryEntry(int score) {
    final level = _stressLevel(score);
    final notes = [
      'Walk completed',
      'Deep breathing done',
      'Trigger: Project deadline',
      'Sleep improved',
      'Hydration break logged',
    ];

    final index = _random.nextInt(notes.length);
    return HistoryEntry(
      dayLabel: 'Today',
      stressScore: score,
      level: level,
      note: notes[index],
    );
  }

  String _stressLevel(int score) {
    if (score >= 70) {
      return 'High';
    }
    if (score >= 56) {
      return 'Moderate';
    }
    if (score >= 45) {
      return 'Low';
    }
    return 'Calm';
  }
}

