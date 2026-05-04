import 'package:flutter/services.dart';

class LiveMetrics {
  const LiveMetrics({
    required this.heartRate,
    required this.steps,
    required this.timestamp,
    required this.permissionDenied,
    required this.message,
  });

  final int heartRate;
  final int steps;
  final DateTime timestamp;
  final bool permissionDenied;
  final String message;

  factory LiveMetrics.fromMap(Map<dynamic, dynamic> raw) {
    return LiveMetrics(
      heartRate: (raw['heartRate'] as num?)?.round() ?? 0,
      steps: (raw['steps'] as num?)?.round() ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (raw['timestamp'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch,
      ),
      permissionDenied: raw['permissionDenied'] == true,
      message: (raw['message'] ?? '').toString(),
    );
  }
}

class GoogleFitBridgeService {
  static const MethodChannel _channel = MethodChannel(
    'stress_sense/google_fit',
  );

  Future<LiveMetrics> fetchLiveMetrics() async {
    final response = await _invokeMap('fetchLiveMetrics');
    return LiveMetrics.fromMap(response);
  }

  Future<void> signOut() async {
    try {
      await _channel.invokeMethod('signOut');
    } on MissingPluginException {
      // Ignore on platforms where the native channel is not available.
    } on PlatformException {
      // Ignore native sign-out failures; Google Sign-In plugin sign-out is primary.
    }
  }

  Future<Map<dynamic, dynamic>> _invokeMap(String method) async {
    try {
      final value = await _channel.invokeMethod(method);
      if (value is Map) {
        return value;
      }
      return <dynamic, dynamic>{};
    } on PlatformException catch (error) {
      return <dynamic, dynamic>{
        'permissionDenied': true,
        'message': error.message ?? 'Native call failed for $method',
      };
    } on MissingPluginException {
      return <dynamic, dynamic>{
        'permissionDenied': true,
        'message': 'Google Fit native bridge is unavailable on this platform.',
      };
    }
  }
}
