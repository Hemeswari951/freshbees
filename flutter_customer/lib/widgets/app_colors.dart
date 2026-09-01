import 'package:flutter/material.dart';

class AppColors {
  // ==========================================================
  // Backgrounds
  // ==========================================================
  // static const Color cream = Color(0xFFFBF8F4);       // App background
  // static const Color white = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF3EBE0);
  static const Color sidebarBg = Color(0xFFFFFFFF);
  static const Color headerBg = Color(0xFFFFFFFF);

  // ==========================================================
  // Primary Brand (Brown)
  // ==========================================================
  // static const Color black = Color(0xFF000000);
  static const Color brown = Color(0xFF4A2C1D);
  static const Color brownDark = Color(0xFF2E1B12);
  static const Color brownLight = Color(0xFFF5EEE8);
  static const Color accentBrown = Color(
    0xFF9E5A38,
  ); // NEW - icons, links, accents

  // ==========================================================
  // Text
  // ==========================================================
  static const Color textDark = Color(0xFF2B241D);
  static const Color textGrey = Color(0xFF8A8178);
  static const Color textLight = Color(0xFFB6ADA4);
  static const Color textMuted = textGrey; // NEW - alias, subtext use pannuறோம்

  // ==========================================================
  // Borders / Dividers
  // ==========================================================
  static const Color border = Color(0xFFF0E9E3);
  static const Color surface = Colors.white;
  // ==========================================================
  // Navigation
  // ==========================================================
  static const Color activeNav = brown;
  static const Color activeNavBg = Color(0xFFF5EEE8);
  static const Color inactiveNav = Color(0xFF5E4B3D);

  // ==========================================================
  // Icon Background
  // ==========================================================
  static const Color iconBg = Color(0xFFF7EEE4);

  // ==========================================================
  // Success
  // ==========================================================
  // static const Color green = Color(0xFF2F8A4C);
  static const Color greenLight = Color(0xFFEAF7EC);
  static const Color greenTagBg = greenLight; // NEW - "New" status badge
  static const Color greenTagText = green; // NEW

  // ==========================================================
  // Error
  // ==========================================================
  // static const Color red = Color(0xFFC84E4E);
  static const Color redLight = Color(0xFFFCEEEE);

  // ==========================================================
  // Warning
  // ==========================================================
  static const Color warning = Color(0xFFB52A2A);
  static const Color warningBg = Color(0xFFFDF1F2);
  static const Color alertBgPink = warningBg; // NEW - low stock banner
  static const Color alertTextRed = warning; // NEW

  // ==========================================================
  // Amber / Pending status
  // ==========================================================
  static const Color amberTagBg = Color(
    0xFFFFF4E0,
  ); // NEW - "Shipped/Pending" badge
  static const Color amberTagText = Color(0xFFB57A00); // NEW

  // ==========================================================
  // Payout Card
  // ==========================================================
  static const Color payout = Color(0xFF4A2C1D);
  static const Color payoutButton = Color(0xFFFFFFFF);

  // ==========================================================
  // Shadows
  // ==========================================================
  static const Color shadow = Color(0x14000000);

  // ---------------------

  static const Color cream = Color(0xFFFAF4EA);
  static const Color blush = Color(0xFFFDF3E9);
  static const Color ink = Color(0xFF2B241D);
  static const Color inkSoft = Color(0xFF6B6055);
  static const Color line = Color(0xFFE9DFCF);
  static const Color terracotta = Color(0xFFC6754A);
  static const Color terracottaSoft = Color(0xFFF0DCC9);
  static const Color black = Color(0xFF211C17);
  static const Color green = Color(0xFF4C8C6B);
  static const Color greenSoft = Color(0xFFE3EEE6);
  static const Color red = Color(0xFFB85C4D);
  static const Color redSoft = Color(0xFFF4E2DD);
  static const Color gold = Color(0xFFC79A3C);
  static const Color white = Color(0xFFFFFFFF);

  static const Color blueSoft = Color(0xFFDDE6F5);
  static const Color blue = Color(0xFF3A5C9C);
  static const Color amberSoft = Color(0xFFFBEBD2);
  static const Color amber = Color(0xFF966A1B);

  // ==========================================================
  // Navigation
  // ==========================================================

  /// -------------------------- START OF NEW CHANGES ------------------------------------------

  /// Scaffold Background
  static const Color background = Color(0xFFF9F7F4);

  /// Cards
  static const Color section = Color(0xFFF5F1EA);

  /// Primary Theme
  static const Color primary = Color(0xFFB8956A);
  static const Color primaryLight = Color(0xFFF0EAE2);

  /// Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);

  /// Rating
  static const Color star = Color(0xFFB8956A);

  /// Success
  static const Color success = Color(0xFF2E7D32);

  /// Error
  static const Color danger = Color(0xFFD32F2F);

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
  static const TextStyle body = TextStyle(fontSize: 13, color: textSecondary);

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
        borderSide: const BorderSide(color: primary, width: 1.2),
      ),
    );
  }
}
