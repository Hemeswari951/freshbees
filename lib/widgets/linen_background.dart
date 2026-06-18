import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Linen fabric texture background - matches Thiraa UI design
/// No image file needed - generated purely in code
class LinenBackground extends StatelessWidget {
  const LinenBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LinenTexturePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _LinenTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(42); // fixed seed for consistent texture

    // ── Base warm cream gradient ──────────────────────────────────────────
    final bgPaint = Paint();
    final bgRect = Rect.fromLTWH(0, 0, size.width, size.height);

    bgPaint.shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFFEDE3D5), // warm light cream top-left
        Color(0xFFE0D3C0), // slightly deeper mid
        Color(0xFFD8C9B4), // warm tan bottom-right
        Color(0xFFE4D7C8), // back to cream
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    ).createShader(bgRect);

    canvas.drawRect(bgRect, bgPaint);

    // ── Fabric fold light zones (soft light patches like draped cloth) ────
    final foldPaint = Paint()..style = PaintingStyle.fill;

    // Top-left bright highlight
    foldPaint.shader = RadialGradient(
      center: const Alignment(-0.6, -0.5),
      radius: 0.7,
      colors: [const Color(0xFFF5EDE0).withOpacity(0.6), Colors.transparent],
    ).createShader(bgRect);
    canvas.drawRect(bgRect, foldPaint);

    // Center-right highlight (fabric fold peak)
    foldPaint.shader = RadialGradient(
      center: const Alignment(0.5, 0.1),
      radius: 0.55,
      colors: [const Color(0xFFF0E6D6).withOpacity(0.45), Colors.transparent],
    ).createShader(bgRect);
    canvas.drawRect(bgRect, foldPaint);

    // Bottom-left shadow fold
    foldPaint.shader = RadialGradient(
      center: const Alignment(-0.8, 0.9),
      radius: 0.5,
      colors: [const Color(0xFFC8B89A).withOpacity(0.35), Colors.transparent],
    ).createShader(bgRect);
    canvas.drawRect(bgRect, foldPaint);

    // ── Horizontal weft threads (the fabric weave going left-right) ───────
    final weftPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const weftSpacing = 3.0;
    int weftRow = 0;
    for (double y = 0; y < size.height; y += weftSpacing) {
      weftRow++;
      // Vary opacity slightly per row to simulate weave shading
      final opacity = 0.04 + (rand.nextDouble() * 0.06);
      final isDark = weftRow % 2 == 0;

      weftPaint.color = isDark
          ? Color(0xFFB8A890).withOpacity(opacity)
          : Color(0xFFD4C5B0).withOpacity(opacity * 0.5);
      weftPaint.strokeWidth = isDark ? 0.8 : 0.4;

      // Slight wave to simulate natural fabric drape
      final path = Path();
      path.moveTo(0, y);
      double x = 0;
      while (x < size.width) {
        final wave =
            math.sin((x / size.width) * math.pi * 6 + weftRow * 0.3) *
            (rand.nextDouble() * 0.4);
        path.lineTo(x, y + wave);
        x += 2;
      }
      canvas.drawPath(path, weftPaint);
    }

    // ── Vertical warp threads (the fabric weave going top-bottom) ─────────
    final warpPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const warpSpacing = 3.5;
    int warpCol = 0;
    for (double x = 0; x < size.width; x += warpSpacing) {
      warpCol++;
      final opacity = 0.03 + (rand.nextDouble() * 0.04);
      final isDark = warpCol % 3 == 0;

      warpPaint.color = isDark
          ? Color(0xFFA89880).withOpacity(opacity)
          : Color(0xFFCCBEAA).withOpacity(opacity * 0.4);
      warpPaint.strokeWidth = isDark ? 0.7 : 0.3;

      final path = Path();
      path.moveTo(x, 0);
      double y = 0;
      while (y < size.height) {
        final wave =
            math.sin((y / size.height) * math.pi * 8 + warpCol * 0.5) *
            (rand.nextDouble() * 0.3);
        path.lineTo(x + wave, y);
        y += 2;
      }
      canvas.drawPath(path, warpPaint);
    }

    // ── Fabric knot/texture dots (linen has small irregular nodes) ────────
    final knotPaint = Paint()..style = PaintingStyle.fill;
    final knotRand = math.Random(17);

    for (int i = 0; i < 300; i++) {
      final kx = knotRand.nextDouble() * size.width;
      final ky = knotRand.nextDouble() * size.height;
      final kr = 0.5 + knotRand.nextDouble() * 1.2;
      final ko = 0.03 + knotRand.nextDouble() * 0.07;

      knotPaint.color =
          (knotRand.nextBool()
                  ? const Color(0xFF9A8870)
                  : const Color(0xFFD0C0A8))
              .withOpacity(ko);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(kx, ky),
          width: kr * 2,
          height: kr * 1.3,
        ),
        knotPaint,
      );
    }

    // ── Subtle diagonal light sheen (like light hitting draped fabric) ────
    final sheenPaint = Paint()..style = PaintingStyle.fill;
    sheenPaint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.08),
        Colors.transparent,
        Colors.white.withOpacity(0.05),
        Colors.transparent,
        const Color(0xFFC8B89A).withOpacity(0.08),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    ).createShader(bgRect);
    canvas.drawRect(bgRect, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
