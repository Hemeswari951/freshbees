import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'create_password_screen.dart';

// ── Dummy correct OTP for demo — replace with real backend check ──
const String _kCorrectOtp = '123456';

class VerificationScreen extends StatefulWidget {
  final String contact;
  final bool isEmail;

  const VerificationScreen({
    super.key,
    required this.contact,
    required this.isEmail,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendSeconds = 45;
  bool _canResend = false;
  bool _isVerifying = false;

  // null = idle, true = correct, false = wrong
  bool? _otpResult;

  late final AnimationController _shakeController;
  late final AnimationController _lockController;
  late final Animation<double> _shakeAnim;
  late final Animation<double> _lockAnim;

  bool get _isAllFilled => _otpControllers.every((c) => c.text.isNotEmpty);

  Color get _accentColor {
    if (_otpResult == false) return const Color(0xFFD32F2F);
    if (_otpResult == true || _isAllFilled) return const Color(0xFF2E7D32);
    return const Color(0xFF1A1A1A);
  }

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );

    _lockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _lockAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _lockController, curve: Curves.easeOutBack),
    );

    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      if (_resendSeconds > 0) {
        setState(() => _resendSeconds--);
        _startResendTimer();
      } else {
        setState(() => _canResend = true);
      }
    });
  }

  String get _maskedContact {
    if (widget.isEmail) {
      final parts = widget.contact.split('@');
      if (parts.length == 2) {
        final name = parts[0];
        return name.length > 2
            ? '${name.substring(0, 2)}***@${parts[1]}'
            : '$name***@${parts[1]}';
      }
      return widget.contact;
    } else {
      final last4 = widget.contact.length >= 4
          ? widget.contact.substring(widget.contact.length - 4)
          : widget.contact;
      return '******$last4';
    }
  }

  Future<void> _onVerify() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the complete 6-digit OTP')),
      );
      return;
    }

    setState(() => _isVerifying = true);
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;

    if (otp == _kCorrectOtp) {
      setState(() {
        _otpResult = true;
        _isVerifying = false;
      });
      await _lockController.forward();
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreatePasswordScreen()),
      );
    } else {
      setState(() {
        _otpResult = false;
        _isVerifying = false;
      });
      _shakeController.forward(from: 0);
      HapticFeedback.vibrate();
    }
  }

  void _onFieldChanged(String value, int index) {
    // Reset error state on new input
    if (_otpResult == false) setState(() => _otpResult = null);
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyEvent(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _otpControllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _lockController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
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
                      Center(
                        child: _LockIconSection(
                          result: _otpResult,
                          lockAnim: _lockAnim,
                        ),
                      ),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.30),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: _accentColor.withOpacity(
                    _otpResult == null && !_isAllFilled ? 0.55 : 0.45),
                width: 1.2,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Verification',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: _otpResult == false
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _otpResult == false
                      ? const Text(
                          'Invalid OTP. Please try again.',
                          key: ValueKey('wrong'),
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFD32F2F),
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : RichText(
                          key: const ValueKey('normal'),
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4A4A4A),
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: widget.isEmail
                                    ? 'Code sent to your email\n'
                                    : 'OTP sent to your mobile\n',
                              ),
                              TextSpan(
                                text: _maskedContact,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // OTP boxes with shake
                AnimatedBuilder(
                  animation: _shakeAnim,
                  builder: (context, child) {
                    final double offset = _shakeController.isAnimating
                        ? math.sin(_shakeAnim.value * math.pi * 6) * 8
                        : 0;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        List.generate(6, (i) => _buildOtpBox(i)),
                  ),
                ),
                const SizedBox(height: 24),

                // Verify button
                GestureDetector(
                  onTap: _isVerifying ? null : _onVerify,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_otpResult == true) ...[
                                const Icon(Icons.lock_open_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                              ] else if (_otpResult == false) ...[
                                const Icon(Icons.lock_outlined,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                              ] else if (_isAllFilled) ...[
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _otpResult == false ? 'TRY AGAIN' : 'VERIFY',
                                style: const TextStyle(
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

                // Resend
                Center(
                  child: _canResend
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _resendSeconds = 45;
                              _canResend = false;
                              _otpResult = null;
                              for (final c in _otpControllers) c.clear();
                            });
                            _startResendTimer();
                            _focusNodes[0].requestFocus();
                          },
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        )
                      : Text(
                          'Resend code in ${_resendSeconds}s',
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    final bool isFilled = _otpControllers[index].text.isNotEmpty;
    Color boxColor;
    Color borderColor;
    Color textColor;

    if (_otpResult == false) {
      boxColor = const Color(0xFFD32F2F).withOpacity(0.08);
      borderColor = const Color(0xFFD32F2F).withOpacity(0.6);
      textColor = const Color(0xFFD32F2F);
    } else if (_otpResult == true) {
      boxColor = const Color(0xFF2E7D32).withOpacity(0.10);
      borderColor = const Color(0xFF2E7D32).withOpacity(0.5);
      textColor = const Color(0xFF2E7D32);
    } else if (isFilled && _isAllFilled) {
      boxColor = const Color(0xFF2E7D32).withOpacity(0.10);
      borderColor = const Color(0xFF2E7D32).withOpacity(0.5);
      textColor = const Color(0xFF2E7D32);
    } else {
      boxColor = isFilled
          ? Colors.white.withOpacity(0.85)
          : Colors.white.withOpacity(0.45);
      borderColor = isFilled
          ? const Color(0xFF1A1A1A).withOpacity(0.4)
          : Colors.white.withOpacity(0.6);
      textColor = const Color(0xFF1A1A1A);
    }

    return SizedBox(
      width: 46,
      height: 56,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onKeyEvent(event, index),
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: boxColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _accentColor, width: 1.8),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) => _onFieldChanged(value, index),
        ),
      ),
    );
  }
}

/// Animated lock icon — locked → unlocked on correct OTP
class _LockIconSection extends StatelessWidget {
  final bool? result; // null=idle, true=correct, false=wrong
  final Animation<double> lockAnim;

  const _LockIconSection({required this.result, required this.lockAnim});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: lockAnim,
          builder: (context, _) {
            final bool isUnlocked = result == true && lockAnim.value > 0.5;
            final Color circleColor = result == false
                ? const Color(0xFFD32F2F)
                : result == true
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF1A1A1A);

            return Transform.scale(
              scale: result == true
                  ? 1.0 + (math.sin(lockAnim.value * math.pi) * 0.12)
                  : 1.0,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: circleColor.withOpacity(0.08),
                  border: Border.all(
                    color: circleColor.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: child,
                  ),
                  child: Icon(
                    result == false
                        ? Icons.lock_outlined
                        : isUnlocked
                            ? Icons.lock_open_rounded
                            : Icons.lock_outline_rounded,
                    key: ValueKey(result == false
                        ? 'red'
                        : isUnlocked
                            ? 'open'
                            : 'locked'),
                    size: 40,
                    color: circleColor,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        // thiraa logo text — larger, serif style
        const Text(
          'Thiraa',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w300,
            color: Color(0xFF1A1A1A),
            letterSpacing: 4,
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