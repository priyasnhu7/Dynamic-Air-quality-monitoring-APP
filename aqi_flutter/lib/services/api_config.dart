import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String prefKey = 'custom_server_base_url';
  
  // Live 24/7 Cloud Backend deployed on Render
  static const String liveCloudUrl = 'https://https-breathepure-aqi-backend-onrender.onrender.com';
  static const String defaultLocalIp = liveCloudUrl;
  static const String emulatorIp = 'http://10.0.2.2:5000';
  static const String localhostIp = 'http://127.0.0.1:5000';

  static String _baseUrl = liveCloudUrl;
  static bool _initialized = false;

  static String get baseUrl => _baseUrl;

  // Initialize from SharedPreferences
  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefKey);
      if (saved != null && saved.trim().isNotEmpty) {
        _baseUrl = saved.trim();
      } else {
        _baseUrl = defaultLocalIp;
      }
    } catch (_) {}
    _initialized = true;
  }

  // Update and persist new server URL
  static Future<void> setBaseUrl(String newUrl) async {
    var formatted = newUrl.trim();
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    _baseUrl = formatted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, formatted);
    } catch (_) {}
  }

  // Quick test if server is online
  static Future<bool> testConnection([String? urlToTest]) async {
    final target = (urlToTest != null && urlToTest.trim().isNotEmpty)
        ? urlToTest.trim()
        : _baseUrl;
    var formatted = target;
    if (!formatted.startsWith('http://') && !formatted.startsWith('https://')) {
      formatted = 'http://$formatted';
    }
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    try {
      final uri = Uri.parse('$formatted/api/iot/status');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 2500));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Device key for ESP8266 identification
  static const String deviceKey = 'esp8266_breathepure_key';
}
