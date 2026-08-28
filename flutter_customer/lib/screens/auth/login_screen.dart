import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_verify_screen.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final String? redirectRoute;
  const LoginScreen({super.key, this.redirectRoute});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleSendOTP() async {
    if (_isLoading) return;
    String input = _inputController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter mobile number or email"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Autofill Context Finish
    TextInput.finishAutofillContext();

    setState(() => _isLoading = true);

    bool isSuccess = false;
    bool isExisting = false;
    String message = '';

    try {
      final response = await AuthService.sendOtp(
        identifier: input,
        purpose: 'auth',
      );

      isSuccess = response.success;
      message = response.message;

      if (response.isNewUser != null) {
        isExisting = !response.isNewUser!;
      }
    } catch (e) {
      isSuccess = false;
      message = 'Cannot connect to Server';
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (isSuccess) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mark_email_read_outlined,
                size: 50,
                color: Color(0xFFB8956A),
              ),
              const SizedBox(height: 16),
              const Text(
                'OTP Sent',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'OTP sent to\n"$input"',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OTPVerifyScreen(
                          identifier: input,
                          purpose: isExisting ? 'login' : 'registration',
                          showUsePassword: isExisting,
                          redirectRoute: widget.redirectRoute,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.isNotEmpty ? message : 'Failed to send OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/fashion_bg.png",
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) =>
                Container(color: const Color(0xFFF5F5F5)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AutofillGroup(
                  // Added AutofillGroup
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/logo.png",
                        height: 70,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.diamond,
                          size: 50,
                          color: Color(0xFFB8956A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'VIRTUAL TRIALS, REAL YOU',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3.0,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EAE2).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Sign In / Register',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _inputController,
                                  keyboardType: TextInputType.emailAddress,
                                  // Added Autofill Hints
                                  autofillHints: const [
                                    AutofillHints.telephoneNumber,
                                    AutofillHints.email,
                                    AutofillHints.username,
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Phone Number or Email',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: Color(0xFF8B7355),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.95),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleSendOTP,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : const Text(
                                            'Continue',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
