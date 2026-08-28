import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/app_colors.dart';

/// About Us — STATIC content for now (Dinesh, 27 Aug).
/// TODO: hook this back up to app_settings API later (see old dynamic
/// version) once admin panel content is finalized. For now all copy,
/// contact info, and social links below are placeholders — update with
/// real THIRAA / Freshbees details before going live.
///
/// NOTE: this widget has NO Scaffold/AppBar of its own — it's meant to be
/// embedded inside another screen that already provides one (e.g.
/// ProfileDetailsScreen). This avoids the "double header" you get when a
/// Scaffold is nested inside another Scaffold's body.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // ---- STATIC CONTENT — edit here ----
  static const String appName = 'THIRAA';
  static const String tagline = 'Fresh picks, delivered with care.';
  static const String story =
      'THIRAA started with a simple idea — connect local shops and sellers '
      'with customers who want quality products, fair prices, and a smooth '
      'shopping experience. From everyday essentials to curated finds, we '
      'bring a whole marketplace of trusted shop owners onto one platform, '
      'so you can discover, compare, and order everything in one place.';

  static const List<_Feature> features = [
    _Feature(Icons.storefront_outlined, 'Multiple Shops, One App',
        'Browse products from many verified shop owners without switching apps.'),
    _Feature(Icons.verified_outlined, 'Quality You Can Trust',
        'Every shop and product listing is reviewed before it goes live.'),
    _Feature(Icons.local_shipping_outlined, 'Reliable Delivery',
        'Track your order from shop to doorstep, every step of the way.'),
    _Feature(Icons.support_agent_outlined, 'Support That Listens',
        'Our team is here to help with orders, returns, and questions.'),
  ];

  static const String officeAddress =
      'THIRAA Technologies, Salem, Tamil Nadu, India';
  static const String contactEmail = 'support@thiraa.com';
  static const String contactPhone = '+91 90000 00000';
  static const String whatsappNumber = '919000000000';
  static const String websiteUrl = 'https://www.thiraa.com';

  static const String? facebookUrl = 'https://facebook.com/thiraa';
  static const String? instagramUrl = 'https://instagram.com/thiraa';
  static const String? twitterUrl = 'https://twitter.com/thiraa';
  static const String? youtubeUrl = null;
  static const String? linkedinUrl = null;

  static const String copyrightText = '© 2026 THIRAA. All rights reserved.';
  // ---- end static content ----

  Future<void> _openLink(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    final normalized = url.startsWith('http') ||
            url.startsWith('mailto:') ||
            url.startsWith('tel:')
        ? url
        : 'https://$url';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool get _hasAnySocial =>
      (facebookUrl ?? '').isNotEmpty ||
      (instagramUrl ?? '').isNotEmpty ||
      (twitterUrl ?? '').isNotEmpty ||
      (youtubeUrl ?? '').isNotEmpty ||
      (linkedinUrl ?? '').isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand header
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.blush,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_outlined,
                      size: 34, color: AppColors.terracotta),
                ),
                const SizedBox(height: 14),
                const Text(
                  appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tagline,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.ink.withOpacity(0.55),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Our story
          const Text(
            'Our Story',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            story,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.ink.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 28),

          // Why THIRAA
          const Text(
            'Why THIRAA',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          ...features.map(_featureRow),
          const SizedBox(height: 14),

          // Contact
          const Text(
            'Get in Touch',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          _infoRow(Icons.location_on_outlined, 'Address', officeAddress),
          _infoRow(Icons.email_outlined, 'Email', contactEmail,
              onTap: () => _openLink('mailto:$contactEmail')),
          _infoRow(Icons.call_outlined, 'Phone', contactPhone,
              onTap: () => _openLink('tel:$contactPhone')),
          _infoRow(Icons.chat_outlined, 'WhatsApp', whatsappNumber,
              onTap: () => _openLink('https://wa.me/$whatsappNumber')),
          _infoRow(Icons.language_outlined, 'Website', websiteUrl,
              onTap: () => _openLink(websiteUrl)),

          const SizedBox(height: 8),
          if (_hasAnySocial) ...[
            const Text(
              'Follow us',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if ((facebookUrl ?? '').isNotEmpty)
                  _socialIcon(Icons.facebook, () => _openLink(facebookUrl)),
                if ((instagramUrl ?? '').isNotEmpty)
                  _socialIcon(Icons.camera_alt_outlined,
                      () => _openLink(instagramUrl)),
                if ((twitterUrl ?? '').isNotEmpty)
                  _socialIcon(
                      Icons.alternate_email, () => _openLink(twitterUrl)),
                if ((youtubeUrl ?? '').isNotEmpty)
                  _socialIcon(Icons.play_circle_outline,
                      () => _openLink(youtubeUrl)),
                if ((linkedinUrl ?? '').isNotEmpty)
                  _socialIcon(Icons.business_center_outlined,
                      () => _openLink(linkedinUrl)),
              ],
            ),
            const SizedBox(height: 24),
          ],

          Text(
            copyrightText,
            style: TextStyle(fontSize: 12, color: AppColors.ink.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(_Feature f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(f.icon, size: 18, color: AppColors.terracotta),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  f.subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.ink.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.ink.withOpacity(0.5)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.ink.withOpacity(0.45),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: onTap != null ? AppColors.terracotta : AppColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.blush,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;
  const _Feature(this.icon, this.title, this.subtitle);
}