import 'package:flutter/material.dart';

/// Deterministic color per shop — same shop always gets the same color,
/// different shops (mostly) get different colors. Used wherever a
/// logo/banner placeholder is shown (Profile screen + Shop details screen),
/// so both stay visually consistent for the same shop.
class ShopColors {
  static const List<Color> _palette = [
    Color(0xFF0E5B45), // deep green
    Color(0xFFB9791F), // amber
    Color(0xFF6E56D9), // violet
    Color(0xFF2E7FC1), // blue
    Color(0xFFB1467A), // rose
    Color(0xFF1E8A5F), // emerald
    Color(0xFF8A4FD1), // purple
    Color(0xFFC1562E), // burnt orange
    Color(0xFF2E9E6B), // teal
    Color(0xFF5B54D6), // indigo
  ];

  /// Pass a stable per-shop value as seed — ideally the shop's id.
  /// If your ShopProfile has an `id` field, prefer
  /// `ShopColors.forSeed(p.id.toString())` over shopName, so the color
  /// doesn't change if the shop is renamed.
  static Color forSeed(String seed) {
    if (seed.isEmpty) return _palette.first;
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return _palette[hash % _palette.length];
  }
}
