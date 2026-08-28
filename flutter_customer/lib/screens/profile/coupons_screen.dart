import 'package:flutter/material.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  static const Color _background = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _text = Color(0xFF242424);
  static const Color _muted = Color(0xFF777777);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFE8E1D8);

  // ----------------------------------------------------------
  // TEMPORARY HARDCODED COUPONS
  // Later this can come from your backend API.
  // ----------------------------------------------------------

  final List<Map<String, dynamic>> _coupons = [
    {
      'code': 'THIRAA10',
      'title': '10% OFF',
      'description': 'Get 10% off on your first order.',
      'minimum': 'Minimum order value ₹999',
      'validity': 'Valid until 30 Sep 2026',
      'type': 'NEW USER',
    },
    {
      'code': 'FASHION200',
      'title': '₹200 OFF',
      'description': 'Flat ₹200 off on selected fashion products.',
      'minimum': 'Minimum order value ₹1,499',
      'validity': 'Valid until 15 Oct 2026',
      'type': 'FASHION',
    },
    {
      'code': 'STYLE15',
      'title': '15% OFF',
      'description': 'Save 15% on your next purchase.',
      'minimum': 'Minimum order value ₹1,999',
      'validity': 'Valid until 31 Oct 2026',
      'type': 'LIMITED',
    },
  ];

  final Set<String> _copiedCoupons = {};

  void _copyCoupon(String code) {
    // UI-only for now.
    // Later you can use Clipboard.setData().
    setState(() {
      _copiedCoupons.add(code);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$code copied'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: _background,

      // appBar: AppBar(
      //   backgroundColor: _background,
      //   surfaceTintColor: _background,
      //   elevation: 0,

      //   title: const Text(
      //     'Coupons',
      //     style: TextStyle(
      //       color: _text,
      //       fontSize: 19,
      //       fontWeight: FontWeight.w700,
      //     ),
      //   ),

      //   // Since your Profile/Overview navigation already provides
      //   // the back navigation, remove this if this screen is opened
      //   // inside your existing profile navigation structure.
      //   leading: IconButton(
      //     icon: const Icon(
      //       Icons.arrow_back,
      //       color: _text,
      //     ),
      //     onPressed: () {
      //       Navigator.of(context).pop();
      //     },
      //   ),
      // ),

      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 760 : double.infinity,
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              32,
            ),
            children: [
              _buildHeader(),
              const SizedBox(height: 18),

              ..._coupons.map(
                (coupon) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _buildCouponCard(coupon),
                ),
              ),

              const SizedBox(height: 10),

              _buildTerms(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // HEADER
  // ----------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF2ECE4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: _accent,
              size: 24,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Coupons',
                  style: TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Save more on your fashion purchases.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // COUPON CARD
  // ----------------------------------------------------------

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final String code = coupon['code'];
    final bool copied = _copiedCoupons.contains(code);

    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // TOP SECTION
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _discountBadge(coupon['title']),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2ECE4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              coupon['type'],
                              style: const TextStyle(
                                color: _accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        coupon['description'],
                        style: const TextStyle(
                          color: _text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        coupon['minimum'],
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        coupon['validity'],
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // DIVIDER
          Container(
            height: 1,
            color: _border,
          ),

          // COUPON CODE SECTION
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _border,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          size: 18,
                          color: _accent,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          code,
                          style: const TextStyle(
                            color: _text,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: () => _copyCoupon(code),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          copied ? Colors.grey : _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      copied ? 'COPIED' : 'COPY',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // DISCOUNT BADGE
  // ----------------------------------------------------------

  Widget _discountBadge(String title) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: _accent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_offer,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // TERMS
  // ----------------------------------------------------------

  Widget _buildTerms() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECE4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coupon Terms',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),

          SizedBox(height: 8),

          Text(
            '• Only one coupon can be used per order.\n'
            '• Coupons are subject to minimum order values.\n'
            '• Offers may vary by shop and product.\n'
            '• Coupon availability may change without notice.',
            style: TextStyle(
              color: _muted,
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}