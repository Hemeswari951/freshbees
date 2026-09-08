import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  // ---------------------------------------------------------------------------
  // COLORS
  // ---------------------------------------------------------------------------

  static const Color _bg = Color(0xFFF6F6F7);
  static const Color _surface = Colors.white;
  static const Color _ink = Color(0xFF1A1A1D);
  static const Color _muted = Color(0xFF8A8A8E);
  static const Color _line = Color(0xFFE7E7E9);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _accentSoft = Color(0xFFF2ECE4);

  // ---------------------------------------------------------------------------
  // STATIC CONTENT
  // ---------------------------------------------------------------------------

  static const String appName = 'THIRAA';

  static const String tagline = 'Fresh picks, delivered with care.';

  static const String story =
      'THIRAA started with a simple idea — connect local shops and sellers '
      'with customers who want quality products, fair prices, and a smooth '
      'shopping experience. From everyday essentials to curated finds, we '
      'bring a whole marketplace of trusted shop owners onto one platform, '
      'so you can discover, compare, and order everything in one place.';

  static const List<_Feature> features = [
    _Feature(
      Icons.storefront_outlined,
      'Multiple Shops, One App',
      'Browse products from many verified shop owners without switching apps.',
    ),
    _Feature(
      Icons.verified_outlined,
      'Quality You Can Trust',
      'Every shop and product listing is reviewed before it goes live.',
    ),
    _Feature(
      Icons.local_shipping_outlined,
      'Reliable Delivery',
      'Track your order from shop to doorstep, every step of the way.',
    ),
    _Feature(
      Icons.support_agent_outlined,
      'Support That Listens',
      'Our team is here to help with orders, returns, and questions.',
    ),
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

  // ---------------------------------------------------------------------------
  // OPEN LINK
  // ---------------------------------------------------------------------------

  Future<void> _openLink(String? url) async {
    if (url == null || url.trim().isEmpty) {
      return;
    }

    final normalized =
        url.startsWith('http') ||
            url.startsWith('mailto:') ||
            url.startsWith('tel:')
        ? url
        : 'https://$url';

    final uri = Uri.tryParse(normalized);

    if (uri == null) {
      return;
    }

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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 24),

            _buildStory(),

            const SizedBox(height: 24),

            _buildWhyThiraa(),

            const SizedBox(height: 24),

            _buildContact(),

            if (_hasAnySocial) ...[const SizedBox(height: 8), _buildSocials()],

            const SizedBox(height: 22),

            Text(
              copyrightText,
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: _accentSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.eco_outlined, size: 29, color: _accent),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  tagline,
                  style: TextStyle(
                    fontSize: 13,
                    color: _muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STORY
  // ---------------------------------------------------------------------------

  Widget _buildStory() {
    return _contentCard(
      title: 'Our Story',
      child: const Text(
        story,
        style: TextStyle(fontSize: 13.5, height: 1.6, color: _muted),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // WHY THIRAA
  // ---------------------------------------------------------------------------

  Widget _buildWhyThiraa() {
    return _contentCard(
      title: 'Why THIRAA',
      child: Column(
        children: [...features.map((feature) => _featureRow(feature))],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTACT
  // ---------------------------------------------------------------------------

  Widget _buildContact() {
    return _contentCard(
      title: 'Get in Touch',
      child: Column(
        children: [
          _infoRow(Icons.location_on_outlined, 'Address', officeAddress),

          _infoRow(
            Icons.email_outlined,
            'Email',
            contactEmail,
            onTap: () => _openLink('mailto:$contactEmail'),
          ),

          _infoRow(
            Icons.call_outlined,
            'Phone',
            contactPhone,
            onTap: () => _openLink('tel:$contactPhone'),
          ),

          _infoRow(
            Icons.chat_outlined,
            'WhatsApp',
            whatsappNumber,
            onTap: () => _openLink('https://wa.me/$whatsappNumber'),
          ),

          _infoRow(
            Icons.language_outlined,
            'Website',
            websiteUrl,
            onTap: () => _openLink(websiteUrl),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SOCIALS
  // ---------------------------------------------------------------------------

  Widget _buildSocials() {
    return _contentCard(
      title: 'Follow Us',
      child: Row(
        children: [
          if ((facebookUrl ?? '').isNotEmpty)
            _socialIcon(Icons.facebook, () => _openLink(facebookUrl)),

          if ((instagramUrl ?? '').isNotEmpty)
            _socialIcon(
              Icons.camera_alt_outlined,
              () => _openLink(instagramUrl),
            ),

          if ((twitterUrl ?? '').isNotEmpty)
            _socialIcon(Icons.alternate_email, () => _openLink(twitterUrl)),

          if ((youtubeUrl ?? '').isNotEmpty)
            _socialIcon(Icons.play_circle_outline, () => _openLink(youtubeUrl)),

          if ((linkedinUrl ?? '').isNotEmpty)
            _socialIcon(
              Icons.business_center_outlined,
              () => _openLink(linkedinUrl),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONTENT CARD
  // ---------------------------------------------------------------------------

  Widget _contentCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),

          const SizedBox(height: 14),

          child,
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FEATURE
  // ---------------------------------------------------------------------------

  Widget _featureRow(_Feature feature) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(feature.icon, size: 19, color: _accent),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  feature.subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INFO ROW
  // ---------------------------------------------------------------------------

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: _muted),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      color: onTap != null ? _accent : _ink,
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

  // ---------------------------------------------------------------------------
  // SOCIAL ICON
  // ---------------------------------------------------------------------------

  Widget _socialIcon(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: _accentSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: _accent),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FEATURE MODEL
// -----------------------------------------------------------------------------

class _Feature {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Feature(this.icon, this.title, this.subtitle);
}
