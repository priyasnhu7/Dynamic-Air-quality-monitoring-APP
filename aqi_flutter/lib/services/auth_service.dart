import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService {
  static const String _tokenKey = 'auth_jwt_token';
  static const String _userKey  = 'auth_user_json';
  static const String _offlineUsersKey = 'offline_registered_users_map';

  static Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    await ApiConfig.init();
    final cleanId = identifier.trim().toLowerCase();

    // 1. Try reaching remote backend server
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': cleanId,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        await prefs.setString(_userKey, jsonEncode(data['user']));
        await _saveLocalUser(data['user'], password);
        return {'success': true, 'user': data['user'], 'isOffline': false};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Login failed'};
      }
    } catch (_) {
      // 2. Server unreachable -> check offline registered accounts
      final localMatch = await _verifyLocalUser(cleanId, password);
      if (localMatch != null) {
        final prefs = await SharedPreferences.getInstance();
        final localToken = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_tokenKey, localToken);
        await prefs.setString(_userKey, jsonEncode(localMatch));
        return {
          'success': true,
          'user': localMatch,
          'isOffline': true,
          'message': 'Logged in via Standalone Mode'
        };
      }

      // Check default demo credentials
      if ((cleanId == 'arjun@breathepure.io' || cleanId == '9876543210' || cleanId == 'demo') &&
          (password == 'password123' || password == 'demo123')) {
        final demoUser = {
          'id': 'usr_demo_1',
          'name': 'Arjun Sharma',
          'email': 'arjun@breathepure.io',
          'mobile': '9876543210',
          'createdAt': DateTime.now().toIso8601String(),
          'mode': 'Demo Account'
        };
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, 'offline_demo_token');
        await prefs.setString(_userKey, jsonEncode(demoUser));
        return {'success': true, 'user': demoUser, 'isOffline': true};
      }

      return {
        'success': false,
        'message': 'Cannot reach server at ${ApiConfig.baseUrl}. Please check server IP or Sign Up to use offline mode.'
      };
    }
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String mobile,
    required String password,
  }) async {
    await ApiConfig.init();
    final cleanEmail = email.trim().toLowerCase();
    final cleanMobile = mobile.trim();
    final cleanName = name.trim();

    // 1. Try reaching remote backend server
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/signup');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': cleanName,
              'email': cleanEmail,
              'mobile': cleanMobile,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['token']);
        await prefs.setString(_userKey, jsonEncode(data['user']));
        await _saveLocalUser(data['user'], password);
        return {'success': true, 'user': data['user'], 'isOffline': false};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Registration failed'};
      }
    } catch (_) {
      // 2. Server unreachable -> Automatically create Standalone/Offline account!
      // This ensures when someone installs the APK on another phone, they can sign up immediately!
      final localUser = {
        'id': 'usr_local_${DateTime.now().millisecondsSinceEpoch}',
        'name': cleanName.isNotEmpty ? cleanName : 'BreathePure User',
        'email': cleanEmail,
        'mobile': cleanMobile,
        'createdAt': DateTime.now().toIso8601String(),
        'mode': 'Standalone Mode'
      };
      final localToken = 'offline_token_${DateTime.now().millisecondsSinceEpoch}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, localToken);
      await prefs.setString(_userKey, jsonEncode(localUser));
      await _saveLocalUser(localUser, password);

      return {
        'success': true,
        'user': localUser,
        'isOffline': true,
        'message': 'Account created successfully in Standalone Mode!'
      };
    }
  }

  // Quick 1-tap Guest Mode login
  static Future<Map<String, dynamic>> loginAsGuest() async {
    final guestUser = {
      'id': 'usr_guest_${DateTime.now().millisecondsSinceEpoch}',
      'name': 'Guest User',
      'email': 'guest@breathepure.io',
      'mobile': '+91 98765 00000',
      'createdAt': DateTime.now().toIso8601String(),
      'mode': 'Guest Mode'
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, 'offline_guest_token');
    await prefs.setString(_userKey, jsonEncode(guestUser));
    return {'success': true, 'user': guestUser, 'isOffline': true};
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String identifier,
  }) async {
    await ApiConfig.init();
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/forgot-password');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier.trim()}),
      ).timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Reset instructions sent'};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Request failed'};
      }
    } catch (_) {
      return {
        'success': true,
        'message': 'Password reset link simulated for standalone mode. You can log in directly!'
      };
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      try {
        return jsonDecode(userStr);
      } catch (_) {}
    }
    return null;
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null && !token.startsWith('offline_')) {
        final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/logout');
        await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 2));
      }
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // --- Local Offline Storage Helpers ---
  static Future<void> _saveLocalUser(Map<String, dynamic> user, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(_offlineUsersKey);
      Map<String, dynamic> usersMap = {};
      if (existingStr != null) {
        usersMap = jsonDecode(existingStr) as Map<String, dynamic>;
      }
      final emailKey = (user['email'] as String? ?? '').toLowerCase();
      final mobileKey = (user['mobile'] as String? ?? '');
      
      final entry = {
        'user': user,
        'password': password,
      };

      if (emailKey.isNotEmpty) usersMap[emailKey] = entry;
      if (mobileKey.isNotEmpty) usersMap[mobileKey] = entry;

      await prefs.setString(_offlineUsersKey, jsonEncode(usersMap));
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> _verifyLocalUser(String identifier, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingStr = prefs.getString(_offlineUsersKey);
      if (existingStr == null) return null;

      final usersMap = jsonDecode(existingStr) as Map<String, dynamic>;
      final entry = usersMap[identifier.toLowerCase()];
      if (entry != null && entry is Map<String, dynamic>) {
        if (entry['password'] == password) {
          return entry['user'] as Map<String, dynamic>?;
        }
      }
    } catch (_) {}
    return null;
  }
}
