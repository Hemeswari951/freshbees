import 'package:flutter/material.dart';

class HelpCentreScreen extends StatelessWidget {
  const HelpCentreScreen({super.key});

  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _text = Color(0xFF252525);
  static const Color _muted = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,

      // appBar: AppBar(
      //   backgroundColor: _bg,
      //   elevation: 0,
      //   surfaceTintColor: Colors.transparent,

      //   leading: IconButton(
      //     icon: const Icon(
      //       Icons.arrow_back,
      //       color: _text,
      //     ),
      //     onPressed: () => Navigator.pop(context),
      //   ),

      //   title: const Text(
      //     'Help Centre',
      //     style: TextStyle(
      //       color: _text,
      //       fontWeight: FontWeight.w700,
      //       fontSize: 20,
      //     ),
      //   ),
      // ),

      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
          children: [
            _buildWelcomeCard(),

            const SizedBox(height: 22),

            _sectionTitle('QUICK HELP'),

            _quickHelpGrid(),

            const SizedBox(height: 24),

            _sectionTitle('FREQUENTLY ASKED QUESTIONS'),

            _faqItem(
              'How can I place an order?',
              'Browse the products available from nearby stores, select the product you want, add it to your bag and continue through checkout.',
            ),

            _faqItem(
              'How can I track my order?',
              'Open your Profile and go to Orders. Select the order you want to view its current status and details.',
            ),

            _faqItem(
              'Can I save multiple delivery addresses?',
              'Yes. You can add and manage multiple delivery addresses from the Address section in your profile.',
            ),

            _faqItem(
              'How does Virtual Try-On work?',
              'Create a Try-On Profile and add your details and photo. You can then select your profile while using the Virtual Try-On feature.',
            ),

            _faqItem(
              'Can I use Virtual Try-On for different people?',
              'Yes. You can create multiple Try-On Profiles, such as yourself or family members, and select the required profile when using Virtual Try-On.',
            ),

            _faqItem(
              'Where can I see my saved cards?',
              'Your Saved Cards section will show payment methods saved through the payment system once payment gateway support is enabled.',
            ),

            const SizedBox(height: 24),

            _sectionTitle('NEED MORE HELP?'),

            _buildContactCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.support_agent_outlined,
              color: _accent,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Find answers to common questions or get in touch with us.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: _muted,
        ),
      ),
    );
  }

  Widget _quickHelpGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.8,
      children: [
        _quickHelpItem(
          icon: Icons.shopping_bag_outlined,
          title: 'Orders',
        ),
        _quickHelpItem(
          icon: Icons.location_on_outlined,
          title: 'Delivery',
        ),
        _quickHelpItem(
          icon: Icons.payment_outlined,
          title: 'Payments',
        ),
        _quickHelpItem(
          icon: Icons.refresh_outlined,
          title: 'Returns',
        ),
      ],
    );
  }

  Widget _quickHelpItem({
    required IconData icon,
    required String title,
  }) {
    return InkWell(
      onTap: () {
        // UI only for now.
        // Later each category can open its own help section.
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.black.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _accent,
              size: 21,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  Widget _faqItem(
    String question,
    String answer,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          14,
          0,
          14,
          14,
        ),
        iconColor: _accent,
        collapsedIconColor: Colors.black45,
        title: Text(
          question,
          style: const TextStyle(
            color: _text,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                color: _muted,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            color: _accent,
            size: 28,
          ),

          const SizedBox(height: 10),

          const Text(
            'Still need help?',
            style: TextStyle(
              color: _text,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Our support team will be happy to help you.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // UI only for now.
                // Later connect this to support/contact backend.
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Text(
                'CONTACT SUPPORT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}