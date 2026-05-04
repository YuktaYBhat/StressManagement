class AnalyticsData {
  const AnalyticsData({
    required this.stressTrend,
    required this.activityVsStress,
    required this.sleepVsStress,
  });

  final List<double> stressTrend;
  final List<double> activityVsStress;
  final List<double> sleepVsStress;
}

