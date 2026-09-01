import 'package:flutter/material.dart';

import '../../widgets/app_colors.dart';

/// Static content — the text below is hardcoded, NOT fetched from the
/// backend. Edit the strings in [_sections] directly whenever your
/// terms/policy text changes; no API wiring needed for this screen.
///
/// NOTE: this widget has NO Scaffold/AppBar of its own — it's meant to be
/// embedded inside another screen that already provides one (e.g.
/// ProfileDetailsScreen). This avoids the "double header" you get when a
/// Scaffold is nested inside another Scaffold's body.
class TermsPoliciesScreen extends StatelessWidget {
  const TermsPoliciesScreen({super.key});

  static const List<MapEntry<String, String>> _sections = [
    MapEntry(
      'Terms & Conditions',
      'By using this app, you agree to be bound by these terms and '
          'conditions. Please read them carefully before placing an order '
          'or creating an account.\n\n'
          // TODO: replace with your actual terms text.
          'This is placeholder content — update it with your real terms.',
    ),
    MapEntry(
      'License',
      'All content, trademarks, and data on this app, including but not '
          'limited to software, product names, and images, are the '
          'property of the company and protected by applicable '
          'intellectual property laws.',
    ),
    MapEntry(
      'Privacy Policy',
      'We respect your privacy. Personal information collected through '
          'this app is used solely to process orders, improve your '
          'shopping experience, and communicate important updates.',
    ),
    MapEntry(
      'Returns & Refunds',
      'Items may be returned within the applicable return window as '
          'specified on the product page. Refunds are processed to the '
          'original payment method within the stated timeframe.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _sections.map((entry) => _section(entry.key, entry.value)).toList(),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text(body, style: TextStyle(fontSize: 13, color: AppColors.ink.withOpacity(0.75), height: 1.6)),
        ],
      ),
    );
  }
}