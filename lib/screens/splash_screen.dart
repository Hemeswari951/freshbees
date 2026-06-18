import 'package:flutter/material.dart';
import 'main_scaffold.dart';
import 'home_screen.dart';

/// Curtain/mirror reveal splash: the logo is revealed top to bottom,
/// like a curtain rising, with a thin highlight line tracking the
/// reveal edge as it sweeps down.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  // Adjust these to match your logo's actual rendered width/height if needed.
  static const double _logoWidth = 240;
  static const double _logoHeight = 240;

  late AnimationController _controller;
  late Animation<double> _reveal;
  late Animation<double> _lineFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _reveal = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    // The highlight line fades out right as the reveal finishes.
    _lineFade = CurvedAnimation(parent: _controller, curve: const Interval(0.8, 1.0, curve: Curves.easeOut));

    _controller.forward();

    // Total time on screen before moving to home.
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const MainScaffold(currentIndex: 0, body: HomeScreen()),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final revealedHeight = _reveal.value * _logoHeight;
            return SizedBox(
              width: _logoWidth,
              height: _logoHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Logo clipped from the top down to the current reveal height.
                  ClipRect(
                    clipper: _TopDownClipper(revealedHeight),
                    child: Image.asset('assets/images/thiraa_logo.png', width: _logoWidth),
                  ),

                  // Thin highlight line sitting right at the reveal edge,
                  // fading out as the reveal completes.
                  Positioned(
                    top: revealedHeight - 1,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: (1.0 - _lineFade.value).clamp(0.0, 1.0),
                      child: Container(height: 2, color: const Color(0xFF1A1A1A).withOpacity(0.6)),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Clips a rectangle from the top of the image down to [revealedHeight],
/// hiding everything below it - this is what creates the curtain effect.
class _TopDownClipper extends CustomClipper<Rect> {
  final double revealedHeight;
  _TopDownClipper(this.revealedHeight);

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, revealedHeight);

  @override
  bool shouldReclip(covariant _TopDownClipper oldClipper) => oldClipper.revealedHeight != revealedHeight;
}
