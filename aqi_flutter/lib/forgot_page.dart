import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'login_page.dart';

class AQIForgotPasswordScreen extends StatefulWidget {
  const AQIForgotPasswordScreen({super.key});

  @override
  State<AQIForgotPasswordScreen> createState() => _AQIForgotPasswordScreenState();
}

class _AQIForgotPasswordScreenState extends State<AQIForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitted = false;

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final result = await AuthService.forgotPassword(
        identifier: _identifierController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        setState(() {
          _isSubmitted = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to send reset link'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121418),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AQILoginScreen()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: _isSubmitted ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  // --- FORM VIEW (BEFORE SUBMITTING) ---
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 42,
              color: Colors.greenAccent,
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Forgot Password?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your registered Gmail or mobile number. We will send you instructions to reset your password.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 36),

          // Identifier Input
          TextFormField(
            controller: _identifierController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Email or Mobile Number',
              hintText: 'user@gmail.com or 9876543210',
              prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.greenAccent),
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
                final gmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$', caseSensitive: false);
                if (!gmailRegex.hasMatch(input)) {
                  return 'Please enter a valid @gmail.com address';
                }
              }

              return null;
            },
          ),
          const SizedBox(height: 28),

          // Send Button
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
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
                      'SEND RESET LINK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // Back to Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Remembered your password? ',
                style: TextStyle(color: Colors.grey),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const AQILoginScreen()),
                  );
                },
                child: const Text(
                  'Log In',
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
    );
  }

  // --- SUCCESS CONFIRMATION VIEW ---
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.greenAccent,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 42,
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Check Your Inbox',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We have sent password reset instructions to:\n${_identifierController.text.trim()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 36),

        // Back to Login Button
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const AQILoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'RETURN TO LOGIN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}