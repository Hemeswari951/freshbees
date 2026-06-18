import 'package:flutter/material.dart';
import 'app_footer.dart';

/// All theme colors live here - change a value and it updates
/// everywhere it's used across the app (screens import this file
/// to use AppColors.xxx).
class AppColors {
  static const Color background = Color(0xFFFBF4ED); // warm cream page background
  static const Color card = Color(0xFFFFFFFF);        // white cards (search bar, product cards, footer)
  static const Color textPrimary = Color(0xFF1F1B16); // near-black text
  static const Color textSecondary = Color(0xFF8A8077); // muted gray-brown for hints/labels
  static const Color accent = Color(0xFF1A1A1A);       // black accent for selected tab / active icon
  static const Color border = Color(0xFFEFE6DB);       // subtle borders/dividers
  static const Color banner = Color(0xFF3A2C20);       // dark brown profile header banner
  static const Color cta = Color(0xFFE8537A);          // coral pink for primary CTA buttons (Login/Signup)
}

/// Reusable template - wraps any page's content with the standard
/// background + footer, so Home/Offers/Wishlist/Bag don't repeat
/// Scaffold/background/footer code each time.
///
/// No routes table here anymore - the footer constructs and pushes
/// MainScaffold directly with the target page's content as body.
class MainScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex; // which footer tab to highlight: 0-Home, 1-Offers, 2-Wishlist, 3-Bag

  const MainScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        color: AppColors.background,
        child: SafeArea(child: body),
      ),
      bottomNavigationBar: AppFooter(currentIndex: currentIndex),
    );
  }
}