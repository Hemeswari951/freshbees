import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ===========================
  // COLORS
  // ===========================

  /// Scaffold Background
  static const Color background = Color(0xFFF9F7F4);

  /// Cards
  static const Color card = Colors.white;
  static const Color section = Color(0xFFF5F1EA);

  /// Primary Theme
  static const Color primary = Color(0xFFB8956A);
  static const Color primaryLight = Color(0xFFF0EAE2);

  /// Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// Borders
  static const Color border = Color(0xFFE8E4DE);

  /// Rating
  static const Color star = Color(0xFFB8956A);

  /// Success
  static const Color success = Color(0xFF2E7D32);

  /// Error
  static const Color danger = Color(0xFFD32F2F);

  /// White
  static const Color white = Colors.white;

  /// Black
  static const Color black = Colors.black;

  /// Transparent
  static const Color transparent = Colors.transparent;

  // ===========================
  // BORDER RADIUS
  // ===========================

  static const double radiusXS = 8;
  static const double radiusSM = 12;
  static const double radiusMD = 16;
  static const double radiusLG = 20;
  static const double radiusXL = 24;

  // ===========================
  // PADDING
  // ===========================

  static const double paddingXS = 8;
  static const double paddingSM = 12;
  static const double paddingMD = 16;
  static const double paddingLG = 20;
  static const double paddingXL = 24;

  // ===========================
  // SPACING
  // ===========================

  static const double spaceXS = 6;
  static const double spaceSM = 10;
  static const double spaceMD = 16;
  static const double spaceLG = 24;
  static const double spaceXL = 32;

  // ===========================
  // ICON SIZE
  // ===========================

  static const double iconSM = 18;
  static const double iconMD = 22;
  static const double iconLG = 28;

  // ===========================
  // TEXT STYLES
  // ===========================

  /// App Name
  static const TextStyle appTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    fontFamily: 'Serif',
  );

  /// Screen Title
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Section Heading
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Product Name
  static const TextStyle productTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  /// Price
  static const TextStyle price = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Normal Body
  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: textSecondary,
  );

  /// Small Caption
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    color: textSecondary,
  );

  /// Button
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: white,
  );

  // ===========================
  // BOX SHADOWS
  // ===========================

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // ===========================
  // INPUT DECORATION
  // ===========================

  static InputDecoration searchDecoration({
    String hint = "Search...",
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: body,
      filled: true,
      fillColor: white,

      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: paddingMD,
        vertical: 14,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSM),
        borderSide: const BorderSide(color: border),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSM),
        borderSide: const BorderSide(color: border),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSM),
        borderSide: const BorderSide(
          color: primary,
          width: 1.2,
        ),
      ),
    );
  }
}