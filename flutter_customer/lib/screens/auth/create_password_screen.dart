import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_thiraa/widgets/t_colors.dart';
import '../home/home_screen.dart';
import '../../services/auth_service.dart';

class CreatePasswordScreen extends StatefulWidget {
  final String identifier;

  const CreatePasswordScreen({super.key, required this.identifier});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    String name = _nameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty) {
      _showSnackBar("Please enter your name", isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters", isError: true);
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match", isError: true);
      return;
    }

    // Save Password Prompt-க்காக Context-ஐ முடிக்க வேண்டும்
    TextInput.finishAutofillContext();

    setState(() => _isLoading = true);

    final response = await AuthService.createAccountWithPassword(
      identifier: widget.identifier,
      name: name,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('loginIdentifier', widget.identifier);
      await prefs.setString('userName', name);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } else {
      _showSnackBar(response.message, isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? TColors.red : TColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/fashion_bg.png",
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: TColors.cream),
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
                          color: TColors.gold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'VIRTUAL TRIALS, REAL YOU',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 3.0,
                          color: TColors.inkSoft,
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
                              color: TColors.cardBg.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: TColors.white.withOpacity(0.6),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: TColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Set up your details & password to secure account',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: TColors.textGrey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.name,
                                  autofillHints: const [
                                    AutofillHints.name,
                                    AutofillHints.givenName,
                                  ],
                                  style: const TextStyle(
                                    color: TColors.ink,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Full Name',
                                    prefixIcon: const Icon(
                                      Icons.person_outline,
                                      color: TColors.accentBrown,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: TColors.white.withOpacity(0.95),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  style: const TextStyle(
                                    color: TColors.ink,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline,
                                      color: TColors.accentBrown,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: TColors.textGrey,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: TColors.white.withOpacity(0.95),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  style: const TextStyle(
                                    color: TColors.ink,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Confirm Password',
                                    prefixIcon: const Icon(
                                      Icons.lock_reset,
                                      color: TColors.accentBrown,
                                      size: 20,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: TColors.textGrey,
                                        size: 18,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: TColors.white.withOpacity(0.95),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _handleCreateAccount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: TColors.black,
                                      foregroundColor: TColors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            color: TColors.white,
                                          )
                                        : const Text(
                                            'Create Account & Login',
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
