import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_thiraa/widgets/app_colors.dart';
import '../home/home_screen.dart';
import 'password_screen.dart';
import 'create_password_screen.dart';
import '../../services/auth_service.dart';

class OTPVerifyScreen extends StatefulWidget {
  final String identifier;
  final String purpose;
  final bool showUsePassword;

  const OTPVerifyScreen({
    super.key,
    required this.identifier,
    this.purpose = 'auth',
    this.showUsePassword = false,
  });

  @override
  State<OTPVerifyScreen> createState() => _OTPVerifyScreenState();
}

class _OTPVerifyScreenState extends State<OTPVerifyScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    String otp = _controllers.map((c) => c.text).join();
    if (otp.length == 6 && !_isLoading) {
      _verifyOTP(otp);
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    final response = await AuthService.sendOtp(
      identifier: widget.identifier,
      purpose: widget.purpose,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("New OTP sent successfully!"),
          backgroundColor: AppColors.green,
        ),
      );
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _verifyOTP(String otp) async {
    TextInput.finishAutofillContext();
    setState(() => _isLoading = true);

    final response = await AuthService.verifyOtp(
      identifier: widget.identifier,
      otp: otp,
      purpose: widget.purpose,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      if (widget.purpose == 'forgot_password') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordScreen(
              identifier: widget.identifier,
              isResetMode: true,
            ),
          ),
        );
        return;
      }

      if (response.isNewUser == true || !widget.showUsePassword) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreatePasswordScreen(identifier: widget.identifier),
          ),
          (route) => false,
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (response.customer != null) {
        final customer = response.customer!;
        String fullName =
            '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'
                .trim();
        await prefs.setString(
          'user_name',
          fullName.isNotEmpty ? fullName : 'User',
        );
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message), backgroundColor: AppColors.red),
      );
      for (var c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/fashion_bg.png",
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: AppColors.cream),
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
                          color: AppColors.gold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 32,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cream.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.white.withOpacity(0.6),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Verify OTP',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter the 6-digit code sent to\n${widget.identifier}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 25),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: List.generate(6, (index) {
                                    return SizedBox(
                                      width: 42,
                                      height: 50,
                                      child: TextField(
                                        controller: _controllers[index],
                                        focusNode: _focusNodes[index],
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        maxLength: 1,
                                        // Added OTP Autofill Hint
                                        autofillHints: const [
                                          AutofillHints.oneTimeCode,
                                        ],
                                        decoration: InputDecoration(
                                          counterText: "",
                                          filled: true,
                                          fillColor: AppColors.white.withOpacity(
                                            0.95,
                                          ),
                                          contentPadding: EdgeInsets.zero,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.line,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppColors.gold,
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                        onChanged: (v) {
                                          if (v.isEmpty && index > 0) {
                                            _focusNodes[index - 1]
                                                .requestFocus();
                                          } else {
                                            _onOtpChanged(v, index);
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 20),
                                if (_isLoading || _isResending)
                                  const CircularProgressIndicator(
                                    color: AppColors.gold,
                                  ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Didn't receive code? ",
                                      style: TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    _canResend
                                        ? GestureDetector(
                                            onTap: _resendOTP,
                                            child: const Text(
                                              "Resend OTP",
                                              style: TextStyle(
                                                color: AppColors.gold,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            "Resend in ${_secondsRemaining}s",
                                            style: const TextStyle(
                                              color: AppColors.textDark,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                  ],
                                ),
                                if (widget.showUsePassword &&
                                    widget.purpose != 'forgot_password') ...[
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PasswordScreen(
                                            identifier: widget.identifier,
                                            isResetMode: false,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Use Password Instead',
                                      style: TextStyle(
                                        color: AppColors.terracotta,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
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
