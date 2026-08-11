import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_thiraa/widgets/app_colors.dart';
import '../home/home_screen.dart';
import 'otp_verify_screen.dart';
import '../../services/auth_service.dart';

class PasswordScreen extends StatefulWidget {
  final String identifier;
  final bool isResetMode;

  const PasswordScreen({
    super.key,
    required this.identifier,
    this.isResetMode = false,
  });

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty) {
      _showSnackBar("Please enter your password", isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters", isError: true);
      return;
    }

    if (widget.isResetMode && password != confirmPassword) {
      _showSnackBar("Passwords do not match", isError: true);
      return;
    }

    TextInput.finishAutofillContext();

    setState(() => _isLoading = true);

    if (widget.isResetMode) {
      final response = await AuthService.resetPassword(
        identifier: widget.identifier,
        newPassword: password,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('loginIdentifier', widget.identifier);

        if (response.customer != null) {
          final customer = response.customer!;

          String nameFromApi = '';
          if (customer['name'] != null &&
              customer['name'].toString().trim().isNotEmpty) {
            nameFromApi = customer['name'].toString().trim();
          } else {
            String fname =
                customer['first_name'] ?? customer['firstName'] ?? '';
            String lname = customer['last_name'] ?? customer['lastName'] ?? '';
            nameFromApi = '$fname $lname'.trim();
          }

          if (nameFromApi.isEmpty) {
            nameFromApi = widget.identifier.contains('@')
                ? widget.identifier.split('@')[0]
                : widget.identifier;
          }

          await prefs.setString('userName', nameFromApi);
          await prefs.setString('user_name', nameFromApi);
        }

        _showSnackBar("Password updated successfully! Welcome back.");

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showSnackBar(response.message, isError: true);
      }
    } else {
      final response = await AuthService.loginWithPassword(
        identifier: widget.identifier,
        password: password,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (response.success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('loginIdentifier', widget.identifier);

        if (response.customer != null) {
          final customer = response.customer!;

          String nameFromApi = '';
          if (customer['name'] != null &&
              customer['name'].toString().trim().isNotEmpty) {
            nameFromApi = customer['name'].toString().trim();
          } else {
            String fname =
                customer['first_name'] ?? customer['firstName'] ?? '';
            String lname = customer['last_name'] ?? customer['lastName'] ?? '';
            nameFromApi = '$fname $lname'.trim();
          }

          if (nameFromApi.isEmpty) {
            nameFromApi = widget.identifier.contains('@')
                ? widget.identifier.split('@')[0]
                : widget.identifier;
          }

          await prefs.setString('userName', nameFromApi);
          await prefs.setString('user_name', nameFromApi);
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        _showSnackBar(response.message, isError: true);
      }
    }
  }

  void _handleForgotPassword() async {
    setState(() => _isLoading = true);
    final response = await AuthService.sendOtp(
      identifier: widget.identifier,
      purpose: 'forgot_password',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OTPVerifyScreen(
            identifier: widget.identifier,
            purpose: 'forgot_password',
            showUsePassword: false,
          ),
        ),
      );
    } else {
      _showSnackBar(response.message, isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.red : AppColors.green,
      ),
    );
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
                      const SizedBox(height: 8),
                      const Text(
                        'VIRTUAL TRIALS, REAL YOU',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3.0,
                          color: AppColors.inkSoft,
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
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
                                Text(
                                  widget.isResetMode
                                      ? 'Reset Password'
                                      : 'Enter Password',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.isResetMode
                                      ? 'Set your new secure password'
                                      : 'Welcome back! Enter your password to continue.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  autofillHints: [
                                    widget.isResetMode
                                        ? AutofillHints.newPassword
                                        : AutofillHints.password,
                                  ],
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: widget.isResetMode
                                        ? 'New Password'
                                        : 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: AppColors.accentBrown,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.textGrey,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: AppColors.white.withOpacity(0.95),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                if (widget.isResetMode) ...[
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    autofillHints: const [
                                      AutofillHints.newPassword,
                                    ],
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Confirm Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_reset,
                                        color: AppColors.accentBrown,
                                        size: 20,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: AppColors.textGrey,
                                          size: 18,
                                        ),
                                        onPressed: () => setState(
                                          () => _obscureConfirmPassword =
                                              !_obscureConfirmPassword,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: AppColors.white.withOpacity(
                                        0.95,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleSubmit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.black,
                                      foregroundColor: AppColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: AppColors.white,
                                          )
                                        : Text(
                                            widget.isResetMode
                                                ? 'Reset Password'
                                                : 'Continue',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                if (!widget.isResetMode) ...[
                                  const SizedBox(height: 14),
                                  TextButton(
                                    onPressed: _handleForgotPassword,
                                    child: const Text(
                                      'Forgot / Reset Password?',
                                      style: TextStyle(
                                        color: AppColors.accentBrown,
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
