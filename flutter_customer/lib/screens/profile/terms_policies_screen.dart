import 'package:flutter/material.dart';

class TermsPoliciesScreen extends StatelessWidget {
  const TermsPoliciesScreen({super.key});

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

  static const List<_PolicySection> _sections = [
    _PolicySection(
      icon: Icons.description_outlined,
      title: 'Terms & Conditions',
      body:
          'By using the THIRAA application, you agree to comply with '
          'these terms and conditions. Please read them carefully before '
          'creating an account, browsing products or placing an order.\n\n'
          'You are responsible for providing accurate information when '
          'creating and using your account. THIRAA reserves the right to '
          'update, modify or discontinue services when necessary.',
    ),

    _PolicySection(
      icon: Icons.copyright_outlined,
      title: 'License',
      body:
          'All content available through the THIRAA application, including '
          'software, branding, product information, graphics, images, '
          'logos and other materials, belongs to THIRAA or its respective '
          'content owners.\n\n'
          'You may not reproduce, distribute, modify or commercially use '
          'our content without appropriate authorization.',
    ),

    _PolicySection(
      icon: Icons.lock_outline,
      title: 'Privacy Policy',
      body:
          'We respect your privacy and collect only the information required '
          'to provide our services, process orders, improve your shopping '
          'experience and communicate important updates.\n\n'
          'We take reasonable measures to protect your information and do '
          'not sell your personal information to third parties. Please '
          'review the applicable privacy information for complete details.',
    ),

    _PolicySection(
      icon: Icons.assignment_return_outlined,
      title: 'Returns & Refunds',
      body:
          'Products may be eligible for return within the applicable return '
          'period shown by THIRAA or the respective product listing.\n\n'
          'Returned products should generally be unused, in their original '
          'condition and with applicable tags or packaging intact. Refunds '
          'are processed according to the applicable return and refund '
          'conditions and are generally sent to the original payment method.',
    ),

    _PolicySection(
      icon: Icons.payment_outlined,
      title: 'Payments',
      body:
          'Payments are processed through supported payment providers and '
          'available payment methods may vary depending on your order and '
          'delivery location.\n\n'
          'THIRAA does not store complete card information or CVV details '
          'on its own application servers.',
    ),

    _PolicySection(
      icon: Icons.security_outlined,
      title: 'Account & Security',
      body:
          'You are responsible for maintaining the confidentiality of your '
          'account credentials and for activity performed through your account.\n\n'
          'If you believe that your account has been accessed without '
          'authorization, contact THIRAA support as soon as possible.',
    ),
  ];

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

            const SizedBox(height: 20),

            ..._sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildSection(section),
              ),
            ),

            const SizedBox(height: 6),

            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Policies',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Important information about using THIRAA.',
          style: TextStyle(fontSize: 13, color: _muted),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION
  // ---------------------------------------------------------------------------

  Widget _buildSection(_PolicySection section) {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon, size: 19, color: _accent),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          const Divider(height: 1, color: _line),

          const SizedBox(height: 14),

          Text(
            section.body,
            style: const TextStyle(fontSize: 13, color: _muted, height: 1.65),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER
  // ---------------------------------------------------------------------------

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 19, color: _accent),

          SizedBox(width: 11),

          Expanded(
            child: Text(
              'These policies may be updated from time to time. '
              'Please check this section periodically for the latest information.',
              style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// POLICY MODEL
// -----------------------------------------------------------------------------

class _PolicySection {
  final IconData icon;
  final String title;
  final String body;

  const _PolicySection({
    required this.icon,
    required this.title,
    required this.body,
  });
}
