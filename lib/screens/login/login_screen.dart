import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();
  bool _isUseEmail = false;

  void _onContinue() {
    final input = _mobileController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile number or email'),
        ),
      );
      return;
    }
    // Silent navigation — no "sending OTP" snackbar
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VerificationScreen(contact: input, isEmail: _isUseEmail),
      ),
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Expanded(flex: 4, child: _LogoSection()),
                Expanded(flex: 6, child: _buildFrostedCard()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrostedCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.30),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.55),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF4A4A4A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isUseEmail = !_isUseEmail);
                        _mobileController.clear();
                      },
                      child: Text(
                        _isUseEmail ? 'Use Mobile' : 'Use Email',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF333333),
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPrimaryButton(label: 'GET OTP', onTap: _onContinue),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: TextField(
        controller: _mobileController,
        keyboardType: _isUseEmail
            ? TextInputType.emailAddress
            : TextInputType.phone,
        inputFormatters: _isUseEmail
            ? []
            : [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: _isUseEmail ? 'Enter Email' : 'Enter Mobile Number',
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
          prefixIcon: Icon(
            _isUseEmail ? Icons.email_outlined : Icons.phone_outlined,
            color: const Color(0xFF888888),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/thiraa_logo.png',
              height: 90,
              width: 90,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 50,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          const Text(
            'Thiraa',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: Color(0xFF1A1A1A),
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'VIRTUAL TRIALS, REAL YOU',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2.5,
              color: Color(0xFF555555),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
