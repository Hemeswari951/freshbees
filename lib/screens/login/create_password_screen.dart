import 'package:flutter/material.dart';
import 'dart:ui';

class CreatePasswordScreen extends StatefulWidget {
  const CreatePasswordScreen({super.key});

  @override
  State<CreatePasswordScreen> createState() => _CreatePasswordScreenState();
}

class _CreatePasswordScreenState extends State<CreatePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _showPassword = false;
  bool _showConfirm = false;

  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasSymbol =>
      _passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _passwordsMatch =>
      _passwordController.text == _confirmController.text &&
      _confirmController.text.isNotEmpty;

  bool get _allRequirementsMet =>
      _hasMinLength && _hasUppercase && _hasSymbol && _passwordsMatch;

  void _onContinue() {
    if (!_hasMinLength || !_hasUppercase || !_hasSymbol) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 8 characters, include a capital letter and a symbol.',
          ),
        ),
      );
      return;
    }
    if (!_passwordsMatch) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully! Welcome to Thiraa.'),
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── background4.jpg — same as login & verification ──
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        left: 8,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFF1A1A1A),
                            size: 20,
                          ),
                        ),
                      ),
                      const Center(child: _LogoSection()),
                    ],
                  ),
                ),
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
                    'Create Password',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: -0.5,
                      fontFamily: 'Georgia',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Choose a strong password',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4A4A4A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildPasswordField(
                    controller: _passwordController,
                    hint: 'Create Password',
                    show: _showPassword,
                    onToggle: () =>
                        setState(() => _showPassword = !_showPassword),
                  ),
                  const SizedBox(height: 14),

                  _buildPasswordField(
                    controller: _confirmController,
                    hint: 'Confirm Password',
                    show: _showConfirm,
                    onToggle: () =>
                        setState(() => _showConfirm = !_showConfirm),
                  ),
                  const SizedBox(height: 24),

                  // CONTINUE button — black → green when all requirements met
                  GestureDetector(
                    onTap: _onContinue,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        color: _allRequirementsMet
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_allRequirementsMet) ...[
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Text(
                            'CONTINUE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Requirements card — same frosted glass style
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Password requirements',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF333333),
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildRequirement(
                              'At least 8 characters',
                              _hasMinLength,
                            ),
                            const SizedBox(height: 6),
                            _buildRequirement(
                              'One capital letter',
                              _hasUppercase,
                            ),
                            const SizedBox(height: 6),
                            _buildRequirement(
                              'One symbol (!@#\$...)',
                              _hasSymbol,
                            ),
                            const SizedBox(height: 6),
                            _buildRequirement(
                              'Passwords match',
                              _passwordsMatch,
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
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool show,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.8)),
      ),
      child: TextField(
        controller: controller,
        obscureText: !show,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 15),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Color(0xFF888888),
            size: 20,
          ),
          suffixIcon: IconButton(
            onPressed: onToggle,
            icon: Icon(
              show ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: const Color(0xFF888888),
              size: 20,
            ),
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

  Widget _buildRequirement(String text, bool met) {
    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            key: ValueKey(met),
            size: 16,
            color: met ? const Color(0xFF2E7D32) : const Color(0xFFAAAAAA),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            color: met ? const Color(0xFF2E7D32) : const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}

class _LogoSection extends StatelessWidget {
  const _LogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipOval(
          child: Image.asset(
            'assets/images/thiraa_logo.png',
            height: 100,
            width: 100,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              height: 100,
              width: 100,
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

        const SizedBox(height: 10),
        const Text(
          'Thiraa',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: Color(0xFF1A1A1A),
            letterSpacing: 5,
            fontFamily: 'Georgia',
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'VIRTUAL TRIALS, REAL YOU',
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 2.8,
            color: Color(0xFF555555),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
