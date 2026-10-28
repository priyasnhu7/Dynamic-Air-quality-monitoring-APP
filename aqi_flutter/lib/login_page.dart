import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'services/server_config_dialog.dart';
import 'signup_page.dart';
import 'forgot_page.dart';
import 'dashboard_page.dart';

class AQILoginScreen extends StatefulWidget {
  const AQILoginScreen({super.key});

  @override
  State<AQILoginScreen> createState() => _AQILoginScreenState();
}

class _AQILoginScreenState extends State<AQILoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await AuthService.login(
        identifier: _identifierController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Login failed. Please check credentials.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleGuestLogin() async {
    setState(() => _isLoading = true);
    final result = await AuthService.loginAsGuest();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
  image: DecorationImage(
    image: const AssetImage('assets/bg.jpg'), // <--- Matches assets/bg.jpg
    fit: BoxFit.cover,
    colorFilter: ColorFilter.mode(
      Colors.black.withValues(alpha: 0.65),
      BlendMode.darken,
    ),
  ),
),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar with Server Config Button
                    Align(
                      alignment: Alignment.topRight,
                      child: TextButton.icon(
                        onPressed: () => ServerConfigDialog.show(context),
                        icon: const Icon(Icons.dns_rounded, size: 18, color: Colors.greenAccent),
                        label: const Text(
                          'Server Settings',
                          style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black26,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Logo / Icon Header
                    Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.greenAccent.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.air_rounded,
                        size: 40,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'BreathePure IoT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Monitor Air Quality in Real-Time',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 32),

                    // Gmail or Mobile Number Field
                    TextFormField(
                      controller: _identifierController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: 'Gmail or Mobile Number',
                        hintText: 'user@gmail.com or 9876543210',
                        icon: Icons.person_outline_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your Gmail or mobile number';
                        }

                        final input = value.trim();
                        final isNumeric = RegExp(r'^[0-9]+$').hasMatch(input);

                        if (isNumeric) {
                          if (input.length != 10) {
                            return 'Mobile number must be exactly 10 digits';
                          }
                        } else {
                          final emailRegex = RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                            caseSensitive: false,
                          );
                          if (!emailRegex.hasMatch(input)) {
                            return 'Enter a valid email address or 10-digit mobile number';
                          }
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        icon: Icons.lock_outline_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const AQIForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'LOG IN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Guest / Demo Start Button
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGuestLogin,
                        icon: const Icon(Icons.flash_on_rounded, color: Colors.greenAccent),
                        label: const Text(
                          'TRY GUEST / DEMO MODE',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.greenAccent.withValues(alpha: 0.6), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: Colors.grey),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const AQISignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(icon, color: Colors.greenAccent),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF1E222A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.greenAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}