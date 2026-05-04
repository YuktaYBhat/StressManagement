import 'dart:async';

import 'package:flutter/material.dart';

import '../models/analytics_data.dart';
import '../models/history_entry.dart';
import '../models/recommendation_item.dart';
import '../services/google_fit_bridge_service.dart';
import '../services/stress_calculator.dart';

class AppStateProvider extends ChangeNotifier {
  AppStateProvider() {
    _bootstrap();
  }

  final GoogleFitBridgeService _bridge = GoogleFitBridgeService();
  final Map<String, String> _registeredUsers = <String, String>{
    'demo@stresssense.com': 'demo1234',
  };

  bool isLoading = true;
  bool isSignedIn = false;
  bool fitPermissionGranted = false;
  bool runtimePermissionGranted = false;
  bool permissionDenied = false;
  String userDisplayName = 'User';
  String? currentEmail;
  String statusMessage = '';

  int stressScore = 0;
  int heartRate = 0;
  int steps = 0;
  double sleepHours = 0.0;
  DateTime? lastUpdated;

  List<RecommendationItem> _recommendations = const [];
  List<HistoryEntry> _history = const [];

  Timer? _pollTimer;

  Timer? _sessionTimer;
  Duration activeDuration = Duration.zero;
  bool isSessionRunning = false;

  List<RecommendationItem> get recommendations => _recommendations;
  List<HistoryEntry> get history => _history;

  String get stressLevel => StressCalculator.levelFor(stressScore);

  String get greeting => 'Hi, $userDisplayName';

  String get lastUpdatedLabel {
    if (lastUpdated == null) {
      return 'Waiting for sync';
    }
    final value = lastUpdated!;
    final hour = value.hour > 12
        ? value.hour - 12
        : (value.hour == 0 ? 12 : value.hour);
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return 'Last Updated: $hour:$minute $meridiem';
  }

  Future<void> _bootstrap() async {
    isLoading = true;
    notifyListeners();

    // Keep startup light: app opens to login and waits for user credentials.
    isSignedIn = false;
    statusMessage = '';

    isLoading = false;
    notifyListeners();
  }

  Future<bool> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    final validation = _validateCredentials(
      email: normalizedEmail,
      password: normalizedPassword,
    );
    if (validation != null) {
      statusMessage = validation;
      notifyListeners();
      return false;
    }

    final storedPassword = _registeredUsers[normalizedEmail];
    if (storedPassword == null) {
      statusMessage = 'No account found for this email. Please sign up first.';
      notifyListeners();
      return false;
    }
    if (storedPassword != normalizedPassword) {
      statusMessage = 'Incorrect password. Please try again.';
      notifyListeners();
      return false;
    }

    await _completeLogin(normalizedEmail);
    return true;
  }

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    final validation = _validateCredentials(
      email: normalizedEmail,
      password: normalizedPassword,
    );
    if (validation != null) {
      statusMessage = validation;
      notifyListeners();
      return false;
    }

    if (_registeredUsers.containsKey(normalizedEmail)) {
      statusMessage = 'This email is already registered. Please login.';
      notifyListeners();
      return false;
    }

    _registeredUsers[normalizedEmail] = normalizedPassword;
    await _completeLogin(normalizedEmail);
    return true;
  }

  Future<void> _completeLogin(String email) async {
    isLoading = true;
    statusMessage = '';
    isSignedIn = true;
    currentEmail = email;
    userDisplayName = _displayNameFromEmail(email);
    fitPermissionGranted = true;
    runtimePermissionGranted = true;
    notifyListeners();

    await refreshData(notify: false);
    _startRefreshLoop();
    statusMessage = '';

    isLoading = false;
    notifyListeners();
  }

  Future<void> refreshData({bool notify = true}) async {
    if (!isSignedIn) {
      return;
    }

    final metrics = await _bridge.fetchLiveMetrics();
    permissionDenied = metrics.permissionDenied;

    if (metrics.permissionDenied) {
      statusMessage = metrics.message.isEmpty
          ? 'Google Fit data unavailable.'
          : metrics.message;
      if (notify) {
        notifyListeners();
      }
      return;
    }

    heartRate = metrics.heartRate;
    steps = metrics.steps;
    stressScore = StressCalculator.calculate(
      heartRate: heartRate,
      steps: steps,
    );
    sleepHours = _estimateSleepHours(stressScore: stressScore, steps: steps);
    lastUpdated = metrics.timestamp;

    _prependHistory(stressScore);
    _recommendations = _buildRecommendations();
    statusMessage = '';

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _bridge.signOut();
    _pollTimer?.cancel();
    _pollTimer = null;

    isSignedIn = false;
    fitPermissionGranted = false;
    runtimePermissionGranted = false;
    permissionDenied = false;
    userDisplayName = 'User';
    currentEmail = null;
    statusMessage = '';
    stressScore = 0;
    heartRate = 0;
    steps = 0;
    sleepHours = 0.0;
    lastUpdated = null;
    _recommendations = const [];
    _history = const [];

    resetSession();
    notifyListeners();
  }

  AnalyticsData analyticsDataFor(String range) {
    final points = _seriesFromHistory(range: range);
    final stress = points.map((value) => value.toDouble()).toList();
    final activityVsStress = points
        .map((value) => (100 - value).toDouble().clamp(0.0, 100.0))
        .toList();
    final sleepVsStress = points
        .map((value) => (20 + (value * 0.8)).toDouble().clamp(0.0, 100.0))
        .toList();

    return AnalyticsData(
      stressTrend: stress,
      activityVsStress: activityVsStress,
      sleepVsStress: sleepVsStress,
    );
  }

  void toggleRecommendationDone(String id) {
    _recommendations = _recommendations.map((item) {
      if (item.id == id) {
        return item.copyWith(isDone: !item.isDone);
      }
      return item;
    }).toList();
    notifyListeners();
  }

  void startSession() {
    if (isSessionRunning) {
      return;
    }
    isSessionRunning = true;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      activeDuration += const Duration(seconds: 1);
      notifyListeners();
    });
    notifyListeners();
  }

  void stopSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    isSessionRunning = false;
    notifyListeners();
  }

  void resetSession() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    isSessionRunning = false;
    activeDuration = Duration.zero;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }

  String? _validateCredentials({
    required String email,
    required String password,
  }) {
    if (email.isEmpty || password.isEmpty) {
      return 'Email and password are required.';
    }
    const emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    if (!RegExp(emailPattern).hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    return null;
  }

  String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'User';
    }
    final first = localPart[0].toUpperCase();
    if (localPart.length == 1) {
      return first;
    }
    return '$first${localPart.substring(1)}';
  }

  void _startRefreshLoop() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      refreshData();
    });
  }

  void _prependHistory(int score) {
    final level = StressCalculator.levelFor(score);
    final note = 'HR: $heartRate bpm | Steps: $steps';
    final entry = HistoryEntry(
      dayLabel: _todayLabel(),
      stressScore: score,
      level: level,
      note: note,
    );

    _history = [entry, ..._history];
    if (_history.length > 20) {
      _history = _history.take(20).toList();
    }
  }

  List<RecommendationItem> _buildRecommendations() {
    final doneMap = {for (final item in _recommendations) item.id: item.isDone};
    final List<RecommendationItem> items;

    if (stressScore >= 71) {
      items = const [
        RecommendationItem(
          id: 'r1',
          title: 'Try Deep Breathing',
          trigger: 'High stress',
        ),
        RecommendationItem(
          id: 'r2',
          title: 'Take a 10-minute walk',
          trigger: 'Low recovery movement',
        ),
        RecommendationItem(
          id: 'r3',
          title: 'Pause notifications for 30 minutes',
          trigger: 'Stress overload',
        ),
      ];
    } else if (stressScore >= 41) {
      items = const [
        RecommendationItem(
          id: 'r1',
          title: 'Hydration Break',
          trigger: 'Moderate stress',
        ),
        RecommendationItem(
          id: 'r2',
          title: 'Stretch break',
          trigger: 'Sustained sitting',
        ),
        RecommendationItem(
          id: 'r4',
          title: 'Short mindfulness exercise',
          trigger: 'Elevated heart rate',
        ),
      ];
    } else {
      items = const [
        RecommendationItem(
          id: 'r2',
          title: 'Maintain activity rhythm',
          trigger: 'Healthy pattern',
        ),
        RecommendationItem(
          id: 'r5',
          title: 'Keep current sleep schedule',
          trigger: 'Low stress state',
        ),
        RecommendationItem(
          id: 'r6',
          title: 'Review today accomplishments',
          trigger: 'Positive reinforcement',
        ),
      ];
    }

    return items
        .map((item) => item.copyWith(isDone: doneMap[item.id] ?? false))
        .toList();
  }

  List<int> _seriesFromHistory({required String range}) {
    final int desiredLength;
    if (range == 'day') {
      desiredLength = 7;
    } else if (range == 'week') {
      desiredLength = 7;
    } else {
      desiredLength = 7;
    }

    final source = _history
        .map((entry) => entry.stressScore)
        .take(desiredLength)
        .toList();
    final seed = stressScore;
    while (source.length < desiredLength) {
      source.add(seed);
    }
    return source.reversed.toList();
  }

  double _estimateSleepHours({required int stressScore, required int steps}) {
    final recovery = (steps / 10000).clamp(0.0, 1.0);
    final stressPenalty = (stressScore / 100).clamp(0.0, 1.0);
    final hours = 5.0 + (recovery * 3.0) - (stressPenalty * 1.2);
    return double.parse(hours.clamp(4.0, 8.5).toStringAsFixed(1));
  }

  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}';
  }
}
