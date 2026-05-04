class StressCalculator {
  const StressCalculator._();

  // Elevated resting HR and low activity increase stress; movement lowers it.
  static int calculate({required int heartRate, required int steps}) {
    final heartComponent = ((heartRate - 55) * 1.25).clamp(0, 65).toDouble();
    final activityPenalty = ((8000 - steps) / 100).clamp(0, 35).toDouble();
    final activityRelief = (steps / 500).clamp(0, 12).toDouble();

    final rawScore = heartComponent + activityPenalty - activityRelief;
    return rawScore.round().clamp(0, 100);
  }

  static String levelFor(int score) {
    if (score <= 40) {
      return 'Low';
    }
    if (score <= 70) {
      return 'Moderate';
    }
    return 'High';
  }
}
