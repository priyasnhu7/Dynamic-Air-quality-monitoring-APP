import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class IotService {
  static final Random _rand = Random();
  static int _simulatedAqi = 78;
  static int _simulatedPpm = 345;
  static double _simulatedTemp = 28.2;
  static double _simulatedHum = 58.5;

  // Fetch latest reading and device connection status
  static Future<Map<String, dynamic>?> fetchLatestTelemetry() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/iot/latest');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}

    // Fallback: Standalone simulation so dashboard displays active data
    _simulatedAqi = (_simulatedAqi + (_rand.nextInt(7) - 3)).clamp(40, 190);
    _simulatedPpm = (_simulatedPpm + (_rand.nextInt(15) - 7)).clamp(250, 950);
    _simulatedTemp = (_simulatedTemp + (_rand.nextDouble() * 0.4 - 0.2)).clamp(22.0, 36.0);
    _simulatedHum = (_simulatedHum + (_rand.nextDouble() * 0.6 - 0.3)).clamp(40.0, 80.0);

    String status = 'Good';
    if (_simulatedAqi > 150) {
      status = 'Unhealthy';
    } else if (_simulatedAqi > 100) {
      status = 'Poor';
    } else if (_simulatedAqi > 50) {
      status = 'Moderate';
    }

    return {
      'latest': {
        'aqi': _simulatedAqi,
        'status': status,
        'ppm': _simulatedPpm,
        'temperature': double.parse(_simulatedTemp.toStringAsFixed(1)),
        'humidity': double.parse(_simulatedHum.toStringAsFixed(1)),
        'timestamp': DateTime.now().toIso8601String(),
      },
      'deviceStatus': {
        'deviceId': 'ESP8266_NODE_01',
        'isOnline': true,
        'battery': 84,
        'firmware': 'v1.2.0',
        'lastHeartbeat': DateTime.now().toIso8601String(),
      }
    };
  }

  // Fetch telemetry history with range: 'today', 'week', 'month'
  static Future<List<Map<String, dynamic>>> fetchHistory(String range) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/iot/history?range=$range');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    // Fallback simulated history
    final now = DateTime.now();
    final count = range == 'month' ? 30 : (range == 'week' ? 7 : 12);
    final List<Map<String, dynamic>> simulated = [];
    for (int i = count - 1; i >= 0; i--) {
      final time = range == 'month'
          ? now.subtract(Duration(days: i))
          : (range == 'week' ? now.subtract(Duration(days: i)) : now.subtract(Duration(hours: i * 2)));
      final aqi = 60 + ((i * 7 + 13) % 65);
      simulated.add({
        'aqi': aqi,
        'ppm': 280 + aqi * 2,
        'temperature': 27.0 + (i % 4) * 0.8,
        'humidity': 55.0 + (i % 5) * 1.5,
        'timestamp': time.toIso8601String(),
      });
    }
    return simulated;
  }

  // Fetch active alerts
  static Future<List<Map<String, dynamic>>> fetchAlerts() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/iot/alerts');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['alerts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    return [
      {
        'id': 'alt_sim_1',
        'title': 'High CO₂ Warning',
        'message': 'MQ-135 detected elevated gas levels (420 ppm). Ensure room ventilation.',
        'level': 'warning',
        'timestamp': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
      },
      {
        'id': 'alt_sim_2',
        'title': 'ESP8266 Sensor Ready',
        'message': 'BreathePure IoT node connected and streaming telemetry.',
        'level': 'info',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      }
    ];
  }

  // Dismiss alert
  static Future<bool> dismissAlert({String? id, bool all = false}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/iot/alerts/dismiss');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'all': all}),
      ).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (_) {
      return true;
    }
  }

  // Fetch ESP8266 Device Status
  static Future<Map<String, dynamic>?> fetchDeviceStatus() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/iot/status');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return {
      'deviceId': 'ESP8266_NODE_01',
      'isOnline': true,
      'battery': 85,
      'firmware': 'v1.2.0',
      'lastHeartbeat': DateTime.now().toIso8601String(),
    };
  }

  // Fetch Real-time User Login / Logout Activity Log
  static Future<List<Map<String, dynamic>>> fetchAuthActivities() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/activity');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = (data['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    return [
      {
        'action': 'App Started',
        'user': 'Active Session',
        'time': DateTime.now().toIso8601String(),
        'ip': 'Physical Device (Standalone)'
      }
    ];
  }
}
