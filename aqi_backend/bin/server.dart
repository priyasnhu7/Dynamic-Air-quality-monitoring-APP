import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';

const int serverPort = 5000;
const String defaultDeviceKey = 'esp8266_breathepure_key';

void main() async {
  await AqiBackendServer.start(port: serverPort);
  print('========================================================');
  print(' BreathePure IoT Backend Server Started');
  print(' Listening on: http://0.0.0.0:$serverPort');
  print(' Localhost:    http://localhost:$serverPort');
  print(' Device Key:   $defaultDeviceKey');
  print('========================================================');
}

class AqiBackendServer {
  final int port;
  late final HttpServer _httpServer;
  final File _dbFile = File('server_data.json');

  // In-memory state persisted to _dbFile
  Map<String, dynamic> _db = {
    'users': <dynamic>[],
    'tokens': <String, dynamic>{},
    'authActivity': <dynamic>[],
    'telemetry': <dynamic>[],
    'alerts': <dynamic>[],
    'deviceStatus': {
      'deviceId': 'ESP8266_NODE_01',
      'isOnline': true,
      'lastHeartbeat': DateTime.now().toIso8601String(),
      'battery': 85,
      'firmware': 'v1.2.0',
    },
  };

  bool _simulationEnabled = true;
  Timer? _simulationTimer;

  AqiBackendServer({required this.port});

  static Future<AqiBackendServer> start({int port = 5000}) async {
    final server = AqiBackendServer(port: port);
    await server._init();
    return server;
  }

  Future<void> _init() async {
    _loadDatabase();
    _seedDefaultDataIfEmpty();
    _startSimulationTimer();

    _httpServer = await HttpServer.bind(InternetAddress.
    anyIPv4, port);
    _httpServer.listen(_handleRequest);
  }

  void _loadDatabase() {
    try {
      if (_dbFile.existsSync()) {
        final content = _dbFile.readAsStringSync();
        final parsed = jsonDecode(content);
        if (parsed is Map<String, dynamic>) {
          _db = parsed;
        }
      }
    } catch (e) {
      print('[DB] Error loading database: $e. Starting with fresh state.');
    }
  }

  void _saveDatabase() {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      _dbFile.writeAsStringSync(encoder.convert(_db));
    } catch (e) {
      print('[DB] Error saving database: $e');
    }
  }

  void _seedDefaultDataIfEmpty() {
    final users = _db['users'] as List;
    if (users.isEmpty) {
      // Seed default user: arjun@breathepure.io / password123
      final salt = _generateSalt();
      final hashedPassword = _hashPassword('password123', salt);
      users.add({
        'id': 'usr_demo_1',
        'name': 'Arjun Sharma',
        'email': 'arjun@breathepure.io',
        'mobile': '9876543210',
        'salt': salt,
        'passwordHash': hashedPassword,
        'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      });
    }

    final telemetry = _db['telemetry'] as List;
    if (telemetry.isEmpty) {
      final now = DateTime.now();
      // Generate realistic telemetry for last 24 hours
      for (int i = 24; i >= 0; i--) {
        final time = now.subtract(Duration(hours: i));
        final aqi = 65 + (sin(i / 3) * 20).round() + Random().nextInt(15);
        final ppm = 300 + (aqi * 1.2).round() + Random().nextInt(20);
        final temp = 27.0 + (sin(i / 4) * 5) + (Random().nextDouble() * 1.5);
        final humidity = 55.0 + (cos(i / 4) * 8) + (Random().nextDouble() * 2.0);

        telemetry.add({
          'id': 'tel_${time.millisecondsSinceEpoch}',
          'timestamp': time.toIso8601String(),
          'deviceId': 'ESP8266_NODE_01',
          'mq135_raw': (ppm * 1.1).round(),
          'ppm': ppm,
          'aqi': aqi,
          'status': _getAqiCategory(aqi),
          'temperature': double.parse(temp.toStringAsFixed(1)),
          'humidity': double.parse(humidity.toStringAsFixed(1)),
          'battery': 75,
        });
      }
    }

    final alerts = _db['alerts'] as List;
    if (alerts.isEmpty) {
      alerts.addAll([
        {
          'id': 'alt_1',
          'title': 'High CO₂ Detected',
          'message': 'CO₂ reading reached 1240 ppm. Ventilate room immediately.',
          'time': '10 min ago',
          'severity': 'high',
          'icon': 'co2',
          'dismissed': false,
          'createdAt': DateTime.now().subtract(const Duration(minutes: 10)).toIso8601String(),
        },
        {
          'id': 'alt_2',
          'title': 'AQI Spike Alert',
          'message': 'AQI jumped to 115 in your area. Sensitive groups should stay indoors.',
          'time': '45 min ago',
          'severity': 'high',
          'icon': 'air',
          'dismissed': false,
          'createdAt': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
        },
        {
          'id': 'alt_3',
          'title': 'MQ135 Reading Elevated',
          'message': 'Air contaminants approaching moderate-high threshold (380 ppm).',
          'time': '2 hr ago',
          'severity': 'medium',
          'icon': 'sensors',
          'dismissed': false,
          'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'id': 'alt_4',
          'title': 'ESP8266 Online',
          'message': 'Hardware connected to Wi-Fi successfully.',
          'time': '4 hr ago',
          'severity': 'low',
          'icon': 'wifi',
          'dismissed': false,
          'createdAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        },
      ]);
    }

    _saveDatabase();
  }

  void _startSimulationTimer() {
    _simulationTimer?.cancel();
    // Every 5 seconds, simulate realistic IoT fluctuation if no physical packet recently
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_simulationEnabled) return;
      _injectSimulatedReading();
    });
  }

  void _injectSimulatedReading() {
    final telemetry = _db['telemetry'] as List;
    final lastReading = telemetry.isNotEmpty ? telemetry.last as Map<String, dynamic> : null;

    final baseAqi = lastReading != null ? (lastReading['aqi'] as num).toInt() : 80;
    final deltaAqi = (Random().nextInt(7) - 3); // -3 to +3
    final newAqi = (baseAqi + deltaAqi).clamp(40, 160);

    final basePpm = 300 + (newAqi * 1.15).round() + (Random().nextInt(10) - 5);
    final temp = 28.5 + (Random().nextDouble() * 0.8 - 0.4);
    final humidity = 60.0 + (Random().nextDouble() * 1.2 - 0.6);

    final reading = {
      'id': 'tel_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'deviceId': 'ESP8266_NODE_01',
      'mq135_raw': (basePpm * 1.1).round(),
      'ppm': basePpm,
      'aqi': newAqi,
      'status': _getAqiCategory(newAqi),
      'temperature': double.parse(temp.toStringAsFixed(1)),
      'humidity': double.parse(humidity.toStringAsFixed(1)),
      'battery': 72,
    };

    telemetry.add(reading);
    // Keep max 500 historical points in memory
    if (telemetry.length > 500) {
      telemetry.removeRange(0, telemetry.length - 500);
    }

    _db['deviceStatus'] = {
      'deviceId': 'ESP8266_NODE_01',
      'isOnline': true,
      'lastHeartbeat': DateTime.now().toIso8601String(),
      'battery': 72,
      'firmware': 'v1.2.0',
    };

    _saveDatabase();

    // Print live data update to running terminal
    final timeStr = DateTime.now().toIso8601String().substring(11, 19);
    print('[$timeStr] 📡 [LIVE TELEMETRY] AQI: $newAqi (${_getAqiCategory(newAqi)}) | PPM: $basePpm | Temp: ${reading['temperature']}°C | Hum: ${reading['humidity']}% | ESP8266: Online');
  }

  // -------------------------------------------------------------
  // Request Dispatcher
  // -------------------------------------------------------------
  Future<void> _handleRequest(HttpRequest request) async {
    // 1. Set global CORS headers
    _applyCorsHeaders(request);

    final path = request.uri.path;
    final method = request.method;
    final timeStr = DateTime.now().toIso8601String().substring(11, 19);

    if (path != '/api/health' && path != '/api/iot/latest' && path != '/api/auth/activity') {
      print('[$timeStr] 🌐 [$method] $path from ${request.connectionInfo?.remoteAddress.address ?? 'client'}');
    }

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    try {
      if (path == '/api/health' && method == 'GET') {
        _jsonResponse(request, {
          'status': 'healthy',
          'server': 'BreathePure IoT Dart Backend',
          'time': DateTime.now().toIso8601String(),
        });
      }
      // Auth Routes
      else if (path == '/api/auth/signup' && method == 'POST') {
        await _handleSignup(request);
      } else if (path == '/api/auth/login' && method == 'POST') {
        await _handleLogin(request);
      } else if (path == '/api/auth/forgot-password' && method == 'POST') {
        await _handleForgotPassword(request);
      } else if (path == '/api/auth/me' && method == 'GET') {
        await _handleGetMe(request);
      } else if (path == '/api/auth/logout' && method == 'POST') {
        await _handleLogout(request);
      } else if (path == '/api/auth/activity' && method == 'GET') {
        _handleGetAuthActivity(request);
      }
      // IoT Routes
      else if ((path == '/api/iot/telemetry' || path == '/data') && method == 'POST') {
        await _handleIngestTelemetry(request);
      } else if (path == '/api/iot/latest' && method == 'GET') {
        _handleGetLatestTelemetry(request);
      } else if (path == '/api/iot/history' && method == 'GET') {
        _handleGetTelemetryHistory(request);
      } else if (path == '/api/iot/alerts' && method == 'GET') {
        _handleGetAlerts(request);
      } else if (path == '/api/iot/alerts/dismiss' && method == 'POST') {
        await _handleDismissAlert(request);
      } else if (path == '/api/iot/status' && method == 'GET') {
        _handleGetDeviceStatus(request);
      } else if (path == '/api/iot/simulation/toggle' && method == 'POST') {
        _simulationEnabled = !_simulationEnabled;
        _jsonResponse(request, {
          'simulationEnabled': _simulationEnabled,
        });
      } else {
        _jsonResponse(request, {
          'error': 'Endpoint not found',
          'path': path,
        }, status: HttpStatus.notFound);
      }
    } catch (e, stack) {
      print('[SERVER ERROR] $e\n$stack');
      _jsonResponse(request, {
        'error': 'Internal server error',
        'details': e.toString(),
      }, status: HttpStatus.internalServerError);
    }
  }

  // -------------------------------------------------------------
  // Authentication Handlers
  // -------------------------------------------------------------
  Future<void> _handleSignup(HttpRequest request) async {
    final body = await _readJsonBody(request);
    if (body == null) {
      _jsonResponse(request, {'error': 'Invalid JSON body'}, status: HttpStatus.badRequest);
      return;
    }

    final name = (body['name'] as String?)?.trim() ?? '';
    final email = (body['email'] as String?)?.trim().toLowerCase() ?? '';
    final mobile = (body['mobile'] as String?)?.trim() ?? '';
    final password = (body['password'] as String?) ?? '';

    if (name.isEmpty || email.isEmpty || mobile.isEmpty || password.isEmpty) {
      _jsonResponse(request, {'error': 'All fields are required'}, status: HttpStatus.badRequest);
      return;
    }

    if (password.length < 6) {
      _jsonResponse(request, {'error': 'Password must be at least 6 characters'}, status: HttpStatus.badRequest);
      return;
    }

    final users = _db['users'] as List;
    final exists = users.any((u) => u['email'] == email || u['mobile'] == mobile);
    if (exists) {
      _jsonResponse(request, {'error': 'An account with this email or mobile number already exists'}, status: HttpStatus.conflict);
      return;
    }

    final salt = _generateSalt();
    final passwordHash = _hashPassword(password, salt);
    final userId = 'usr_${DateTime.now().millisecondsSinceEpoch}';

    final newUser = {
      'id': userId,
      'name': name,
      'email': email,
      'mobile': mobile,
      'salt': salt,
      'passwordHash': passwordHash,
      'createdAt': DateTime.now().toIso8601String(),
    };

    users.add(newUser);
    final token = _createSession(userId);
    _recordAuthActivity(
      type: 'SIGNUP',
      userName: name,
      userEmail: email,
      userId: userId,
      details: 'New user registered from mobile / web',
    );
    _saveDatabase();

    _jsonResponse(request, {
      'success': true,
      'token': token,
      'user': {
        'id': userId,
        'name': name,
        'email': email,
        'mobile': mobile,
      },
    }, status: HttpStatus.created);
  }

  Future<void> _handleLogin(HttpRequest request) async {
    final body = await _readJsonBody(request);
    if (body == null) {
      _jsonResponse(request, {'error': 'Invalid JSON body'}, status: HttpStatus.badRequest);
      return;
    }

    final identifier = (body['identifier'] as String?)?.trim().toLowerCase() ?? '';
    final password = (body['password'] as String?) ?? '';

    if (identifier.isEmpty || password.isEmpty) {
      _jsonResponse(request, {'error': 'Email/Phone and password are required'}, status: HttpStatus.badRequest);
      return;
    }

    final users = _db['users'] as List;
    Map<String, dynamic>? matchedUser;
    for (final u in users) {
      if (u['email'] == identifier || u['mobile'] == identifier) {
        matchedUser = u as Map<String, dynamic>;
        break;
      }
    }

    if (matchedUser == null) {
      print('[AUTH EVENT] ❌ FAILED LOGIN ATTEMPT for identifier: "$identifier" at ${DateTime.now().toIso8601String()}');
      _recordAuthActivity(
        type: 'LOGIN_FAILED',
        userName: 'Unknown',
        userEmail: identifier,
        userId: 'anonymous',
        details: 'Failed login attempt - user not found',
      );
      _jsonResponse(request, {'error': 'Invalid credentials. User not found.'}, status: HttpStatus.unauthorized);
      return;
    }

    final salt = matchedUser['salt'] as String;
    final expectedHash = matchedUser['passwordHash'] as String;
    final actualHash = _hashPassword(password, salt);

    if (expectedHash != actualHash) {
      print('[AUTH EVENT] ❌ FAILED LOGIN (WRONG PASSWORD) for: "${matchedUser['email']}" at ${DateTime.now().toIso8601String()}');
      _recordAuthActivity(
        type: 'LOGIN_FAILED',
        userName: matchedUser['name'] ?? 'User',
        userEmail: matchedUser['email'] ?? identifier,
        userId: matchedUser['id'] ?? 'unknown',
        details: 'Incorrect password entered',
      );
      _jsonResponse(request, {'error': 'Incorrect password.'}, status: HttpStatus.unauthorized);
      return;
    }

    final token = _createSession(matchedUser['id'] as String);
    _recordAuthActivity(
      type: 'LOGIN',
      userName: matchedUser['name'] ?? 'User',
      userEmail: matchedUser['email'] ?? identifier,
      userId: matchedUser['id'] as String,
      details: 'User logged in successfully',
    );
    _saveDatabase();

    _jsonResponse(request, {
      'success': true,
      'token': token,
      'user': {
        'id': matchedUser['id'],
        'name': matchedUser['name'],
        'email': matchedUser['email'],
        'mobile': matchedUser['mobile'],
      },
    });
  }

  Future<void> _handleForgotPassword(HttpRequest request) async {
    final body = await _readJsonBody(request);
    final identifier = (body?['identifier'] as String?)?.trim().toLowerCase() ?? '';

    if (identifier.isEmpty) {
      _jsonResponse(request, {'error': 'Please provide registered email or mobile'}, status: HttpStatus.badRequest);
      return;
    }

    final users = _db['users'] as List;
    final user = users.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u?['email'] == identifier || u?['mobile'] == identifier,
          orElse: () => null,
        );

    if (user == null) {
      _jsonResponse(request, {'error': 'No account found with this identifier'}, status: HttpStatus.notFound);
      return;
    }

    final resetOtp = (100000 + Random().nextInt(900000)).toString();
    print('[AUTH EVENT] 🔑 PASSWORD RESET REQUEST for: $identifier | OTP: $resetOtp at ${DateTime.now().toIso8601String()}');

    _jsonResponse(request, {
      'success': true,
      'message': 'Password reset verification code sent.',
      'otp': resetOtp, // Included for offline/development testing
    });
  }

  Future<void> _handleGetMe(HttpRequest request) async {
    final user = _authenticateRequest(request);
    if (user == null) {
      _jsonResponse(request, {'error': 'Unauthorized. Please login.'}, status: HttpStatus.unauthorized);
      return;
    }

    _jsonResponse(request, {
      'user': {
        'id': user['id'],
        'name': user['name'],
        'email': user['email'],
        'mobile': user['mobile'],
        'createdAt': user['createdAt'],
      },
    });
  }

  Future<void> _handleLogout(HttpRequest request) async {
    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
    String userName = 'User';
    String userEmail = '';
    String userId = '';

    if (authHeader != null && authHeader.startsWith('Bearer ')) {
      final token = authHeader.substring(7);
      final tokens = _db['tokens'] as Map<String, dynamic>;
      final session = tokens[token] as Map<String, dynamic>?;
      if (session != null) {
        userId = session['userId'] as String? ?? '';
        final users = _db['users'] as List;
        for (final u in users) {
          if (u['id'] == userId) {
            userName = u['name'] ?? 'User';
            userEmail = u['email'] ?? '';
            break;
          }
        }
      }
      tokens.remove(token);
      _saveDatabase();
    }

    _recordAuthActivity(
      type: 'LOGOUT',
      userName: userName,
      userEmail: userEmail,
      userId: userId,
      details: 'User logged out',
    );

    _jsonResponse(request, {'success': true, 'message': 'Logged out successfully'});
  }

  void _recordAuthActivity({
    required String type,
    required String userName,
    required String userEmail,
    required String userId,
    required String details,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final icon = type == 'LOGIN' ? '🟢' : (type == 'LOGOUT' ? '🔴' : (type == 'SIGNUP' ? '✨' : '⚠️'));
    print('');
    print('========================================================');
    print('[USER ACTIVITY] $icon $type: $userName ($userEmail)');
    print('  Time:    $timestamp');
    print('  Details: $details');
    print('========================================================');
    print('');

    if (_db['authActivity'] == null) {
      _db['authActivity'] = <dynamic>[];
    }
    final activityList = _db['authActivity'] as List;
    activityList.insert(0, {
      'id': 'act_${DateTime.now().millisecondsSinceEpoch}',
      'type': type,
      'userName': userName,
      'userEmail': userEmail,
      'userId': userId,
      'details': details,
      'timestamp': timestamp,
    });

    if (activityList.length > 200) {
      activityList.removeRange(200, activityList.length);
    }
    _saveDatabase();
  }

  void _handleGetAuthActivity(HttpRequest request) {
    final activityList = _db['authActivity'] as List? ?? [];
    final limit = int.tryParse(request.uri.queryParameters['limit'] ?? '50') ?? 50;
    _jsonResponse(request, {
      'activities': activityList.take(limit).toList(),
      'total': activityList.length,
    });
  }

  // -------------------------------------------------------------
  // IoT Telemetry Handlers
  // -------------------------------------------------------------
  Future<void> _handleIngestTelemetry(HttpRequest request) async {
    // Check device authorization key (optional for local sensor nodes)
    final deviceKey = request.headers.value('X-Device-Key') ?? request.uri.queryParameters['apiKey'];
    final body = await _readJsonBody(request);

    if (body == null) {
      _jsonResponse(request, {'error': 'Invalid JSON telemetry payload'}, status: HttpStatus.badRequest);
      return;
    }

    final passedKey = deviceKey ?? body['apiKey'];
    if (passedKey != null && passedKey != defaultDeviceKey) {
      _jsonResponse(request, {'error': 'Unauthorized device key'}, status: HttpStatus.forbidden);
      return;
    }

    final deviceId = body['deviceId']?.toString() ?? 'ESP8266_NODE_01';

    // Support both {"value": 450} and {"mq135_raw": 450, "ppm": 450, "aqi": 75}
    final rawVal = (body['value'] as num?)?.toDouble() ??
                   (body['mq135_raw'] as num?)?.toDouble() ??
                   (body['ppm'] as num?)?.toDouble() ?? 300.0;

    final mq135Raw = (body['mq135_raw'] as num?)?.toInt() ?? rawVal.round();

    // If PPM is given explicitly, use it; otherwise compute approximate PPM from analog raw (0-1023)
    final int ppm;
    if (body['ppm'] != null) {
      ppm = (body['ppm'] as num).toInt();
    } else if (rawVal > 0 && rawVal <= 1023) {
      // Clean air baseline ~76.63, curve approximation
      ppm = (250 + (rawVal * 0.95)).round();
    } else {
      ppm = rawVal.round();
    }

    final calculatedAqi = (body['aqi'] as num?)?.toInt() ?? _ppmToAqi(ppm);
    final temp = (body['temperature'] as num?)?.toDouble() ?? 28.0;
    final humidity = (body['humidity'] as num?)?.toDouble() ?? 60.0;
    final battery = (body['battery'] as num?)?.toInt() ?? 85;

    // Real hardware packet received: disable simulation so real sensor data takes over
    if (_simulationEnabled) {
      _simulationEnabled = false;
      print('[IoT] 🔌 Real ESP8266 hardware stream connected! Simulation paused.');
    }

    final reading = {
      'id': 'tel_${DateTime.now().millisecondsSinceEpoch}',
      'timestamp': DateTime.now().toIso8601String(),
      'deviceId': deviceId,
      'mq135_raw': mq135Raw,
      'ppm': ppm,
      'aqi': calculatedAqi,
      'status': _getAqiCategory(calculatedAqi),
      'temperature': temp,
      'humidity': humidity,
      'battery': battery,
    };

    final telemetry = _db['telemetry'] as List;
    telemetry.add(reading);
    if (telemetry.length > 500) {
      telemetry.removeRange(0, telemetry.length - 500);
    }

    _db['deviceStatus'] = {
      'deviceId': deviceId,
      'isOnline': true,
      'lastHeartbeat': DateTime.now().toIso8601String(),
      'battery': battery,
      'firmware': 'v1.2.0',
    };

    final timeStr = DateTime.now().toIso8601String().substring(11, 19);
    print('[$timeStr] 📡 [HARDWARE TELEMETRY] Raw: $mq135Raw | PPM: $ppm | AQI: $calculatedAqi (${_getAqiCategory(calculatedAqi)}) | Temp: ${temp}°C | Device: $deviceId');

    // Auto-create alert if threshold exceeded
    if (calculatedAqi > 120 || ppm > 800) {
      final alerts = _db['alerts'] as List;
      alerts.insert(0, {
        'id': 'alt_${DateTime.now().millisecondsSinceEpoch}',
        'title': calculatedAqi > 150 ? 'Hazardous AQI Alert' : 'Air Quality Warning',
        'message': 'Sensor detected AQI $calculatedAqi ($ppm ppm). Ensure air ventilation immediately.',
        'time': 'Just now',
        'severity': calculatedAqi > 150 ? 'high' : 'medium',
        'icon': 'air',
        'dismissed': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    _saveDatabase();

    _jsonResponse(request, {
      'success': true,
      'message': 'Telemetry stored',
      'reading': reading,
    }, status: HttpStatus.created);
  }

  void _handleGetLatestTelemetry(HttpRequest request) {
    final telemetry = _db['telemetry'] as List;
    final latest = telemetry.isNotEmpty ? telemetry.last : null;

    final deviceStatus = _db['deviceStatus'] as Map<String, dynamic>? ?? {};
    final lastHeartbeatStr = deviceStatus['lastHeartbeat'] as String?;
    bool isOnline = false;

    if (lastHeartbeatStr != null) {
      final lastHb = DateTime.tryParse(lastHeartbeatStr);
      if (lastHb != null && DateTime.now().difference(lastHb).inSeconds < 45) {
        isOnline = true;
      }
    }

    _jsonResponse(request, {
      'latest': latest,
      'deviceStatus': {
        ...deviceStatus,
        'isOnline': isOnline,
      },
    });
  }

  void _handleGetTelemetryHistory(HttpRequest request) {
    final range = request.uri.queryParameters['range'] ?? 'today';
    final telemetry = (_db['telemetry'] as List).cast<Map<String, dynamic>>();

    final now = DateTime.now();
    List<Map<String, dynamic>> filtered;

    if (range == 'today') {
      final startOfDay = DateTime(now.year, now.month, now.day);
      filtered = telemetry.where((r) {
        final t = DateTime.tryParse(r['timestamp'] ?? '');
        return t != null && t.isAfter(startOfDay);
      }).toList();
    } else if (range == 'week') {
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      filtered = telemetry.where((r) {
        final t = DateTime.tryParse(r['timestamp'] ?? '');
        return t != null && t.isAfter(sevenDaysAgo);
      }).toList();
    } else {
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));
      filtered = telemetry.where((r) {
        final t = DateTime.tryParse(r['timestamp'] ?? '');
        return t != null && t.isAfter(thirtyDaysAgo);
      }).toList();
    }

    // If empty for that range, return the most recent 10 readings
    if (filtered.isEmpty && telemetry.isNotEmpty) {
      filtered = telemetry.reversed.take(12).toList().reversed.toList();
    }

    _jsonResponse(request, {
      'range': range,
      'count': filtered.length,
      'data': filtered,
    });
  }

  void _handleGetAlerts(HttpRequest request) {
    final alerts = _db['alerts'] as List;
    _jsonResponse(request, {
      'alerts': alerts,
    });
  }

  Future<void> _handleDismissAlert(HttpRequest request) async {
    final body = await _readJsonBody(request);
    final alertId = body?['id'] as String?;
    final dismissAll = body?['all'] as bool? ?? false;

    final alerts = (_db['alerts'] as List).cast<Map<String, dynamic>>();
    if (dismissAll) {
      for (final a in alerts) {
        a['dismissed'] = true;
      }
    } else if (alertId != null) {
      for (final a in alerts) {
        if (a['id'] == alertId) {
          a['dismissed'] = true;
          break;
        }
      }
    }

    _saveDatabase();
    _jsonResponse(request, {'success': true, 'message': 'Alert(s) dismissed'});
  }

  void _handleGetDeviceStatus(HttpRequest request) {
    final deviceStatus = _db['deviceStatus'] as Map<String, dynamic>? ?? {};
    final lastHeartbeatStr = deviceStatus['lastHeartbeat'] as String?;
    bool isOnline = false;

    if (lastHeartbeatStr != null) {
      final lastHb = DateTime.tryParse(lastHeartbeatStr);
      if (lastHb != null && DateTime.now().difference(lastHb).inSeconds < 45) {
        isOnline = true;
      }
    }

    _jsonResponse(request, {
      'device': {
        ...deviceStatus,
        'isOnline': isOnline,
        'sensor': 'MQ135 Gas Sensor',
        'controller': 'ESP8266 Wi-Fi Microcontroller',
      },
    });
  }

  // -------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------
  Map<String, dynamic>? _authenticateRequest(HttpRequest request) {
    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    final token = authHeader.substring(7);
    final tokens = _db['tokens'] as Map<String, dynamic>;
    final session = tokens[token] as Map<String, dynamic>?;

    if (session == null) return null;

    final expiresAt = DateTime.tryParse(session['expiresAt'] ?? '');
    if (expiresAt == null || expiresAt.isBefore(DateTime.now())) {
      tokens.remove(token);
      return null;
    }

    final userId = session['userId'] as String;
    final users = _db['users'] as List;
    for (final u in users) {
      if (u['id'] == userId) return u as Map<String, dynamic>;
    }
    return null;
  }

  String _createSession(String userId) {
    final token = 'jwt_${_generateRandomString(32)}';
    final tokens = _db['tokens'] as Map<String, dynamic>;
    tokens[token] = {
      'userId': userId,
      'createdAt': DateTime.now().toIso8601String(),
      'expiresAt': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    };
    return token;
  }

  String _generateSalt([int length = 16]) => _generateRandomString(length);

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password::$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _getAqiCategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy (Sensitive)';
    if (aqi <= 200) return 'Unhealthy';
    return 'Very Unhealthy';
  }

  int _ppmToAqi(int ppm) {
    // Typical approximate conversion curve for indoor MQ135
    if (ppm <= 350) return ((ppm / 350) * 50).round();
    if (ppm <= 500) return (50 + ((ppm - 350) / 150) * 50).round();
    if (ppm <= 800) return (100 + ((ppm - 500) / 300) * 50).round();
    if (ppm <= 1200) return (150 + ((ppm - 800) / 400) * 50).round();
    return (200 + ((ppm - 1200) / 800) * 100).clamp(201, 500).round();
  }

  Future<Map<String, dynamic>?> _readJsonBody(HttpRequest request) async {
    try {
      final bodyStr = await utf8.decoder.bind(request).join();
      if (bodyStr.isEmpty) return null;
      final parsed = jsonDecode(bodyStr);
      return parsed is Map<String, dynamic> ? parsed : null;
    } catch (_) {
      return null;
    }
  }

  void _applyCorsHeaders(HttpRequest request) {
    request.response.headers
      ..set('Access-Control-Allow-Origin', '*')
      ..set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Origin, Content-Type, Authorization, X-Device-Key')
      ..set('Access-Control-Max-Age', '86400');
  }

  void _jsonResponse(HttpRequest request, Map<String, dynamic> data, {int status = HttpStatus.ok}) {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(data));
    request.response.close();
  }
}
