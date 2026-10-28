import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'login_page.dart';
import 'dashboard_page.dart';

import 'services/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();
  final loggedIn = await AuthService.isLoggedIn();
  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BreathePure IoT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121418),
      ),
      home: isLoggedIn ? const DashboardPage() : const AQILoginScreen(),
    );
  }
}