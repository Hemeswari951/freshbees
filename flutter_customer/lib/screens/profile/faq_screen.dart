import 'package:flutter/material.dart';

const _ink = Color(0xFF1A1A1D);
const _surface = Colors.white;
const _canvas = Color(0xFFF6F6F7);
const _muted = Color(0xFF8A8A8E);
const _line = Color(0xFFE7E7E9);
const _accent = Color(0xFF8B7355);
const _accentSoft = Color(0xFFF2ECE4);

// -----------------------------------------------------------------------------
// FAQ MODEL
// -----------------------------------------------------------------------------

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem(this.question, this.answer);
}

class _FaqCategory {
  final String title;
  final IconData icon;
  final List<_FaqItem> items;

  const _FaqCategory({
    required this.title,
    required this.icon,
    required this.items,
  });
}

// -----------------------------------------------------------------------------
// FAQ DATA
// -----------------------------------------------------------------------------

const _categories = [
  _FaqCategory(
    title: 'Orders & Delivery',
    icon: Icons.local_shipping_outlined,
    items: [
      _FaqItem(
        'How do I track my order?',
        'Once your order is shipped, you will receive an SMS and email with the tracking number. '
            'You can also go to My Account → Orders → tap on any order to see real-time delivery status.',
      ),
      _FaqItem(
        'How long does delivery take?',
        'Standard delivery takes 3–5 business days. Express delivery, where available, '
            'delivers within 1–2 business days. Delivery times may vary during sale seasons '
            'or public holidays.',
      ),
      _FaqItem(
        'Can I change my delivery address after placing an order?',
        'You can change the delivery address within 1 hour of placing the order by contacting '
            'our support team. Once the order is dispatched, address changes are not possible.',
      ),
      _FaqItem(
        'What if I am not available at the time of delivery?',
        'Our delivery partner will attempt delivery up to 3 times. After 3 failed attempts, '
            'the order may be returned to us. Contact support if you need assistance.',
      ),
      _FaqItem(
        'Do you deliver outside India?',
        'Currently THIRAA delivers only within India. International shipping may be available '
            'in the future.',
      ),
    ],
  ),

  _FaqCategory(
    title: 'Returns & Refunds',
    icon: Icons.assignment_return_outlined,
    items: [
      _FaqItem(
        'What is your return policy?',
        'We accept returns within the applicable return period. The product must be unused, '
            'unwashed, with original tags attached and in original packaging. Items marked as '
            'Final Sale may not be eligible for return.',
      ),
      _FaqItem(
        'How do I initiate a return?',
        'Go to My Account → Orders → select the order → tap Return Item. Choose the reason '
            'and submit the request. Our team will review the request and arrange the next steps.',
      ),
      _FaqItem(
        'When will I receive my refund?',
        'Once the returned item is received and inspected, the refund will be processed '
            'to your original payment method. The exact time depends on your payment provider '
            'or bank.',
      ),
      _FaqItem(
        'Can I exchange a product instead of returning it?',
        'Exchange availability depends on the product, size, colour and stock availability. '
            'If exchange is supported, the option will be shown during the return process.',
      ),
    ],
  ),

  _FaqCategory(
    title: 'Payments',
    icon: Icons.payment_outlined,
    items: [
      _FaqItem(
        'What payment methods do you accept?',
        'We support available payment methods such as UPI, Credit/Debit Cards, Net Banking '
            'and Cash on Delivery where supported for your order and delivery location.',
      ),
      _FaqItem(
        'Is my payment information secure?',
        'Yes. Payments are processed through secure payment providers. THIRAA does not store '
            'your complete card number or CVV on its own servers.',
      ),
      _FaqItem(
        'What should I do if my payment failed but amount was deducted?',
        'In most cases, failed transactions are automatically reversed by your bank or payment '
            'provider. If the amount is not reversed within the expected timeframe, contact your '
            'bank or THIRAA support with the transaction reference.',
      ),
      _FaqItem(
        'Can I pay using Cash on Delivery?',
        'Cash on Delivery is available only for eligible products, orders and delivery '
            'locations. If available, it will appear as a payment option during checkout.',
      ),
    ],
  ),

  _FaqCategory(
    title: 'Products & Sizing',
    icon: Icons.checkroom_outlined,
    items: [
      _FaqItem(
        'How do I find the right size?',
        'Check the Size Guide available on the product page for measurements. If you are '
            'between sizes, review the product-specific fit information before ordering.',
      ),
      _FaqItem(
        'Are the product colours accurate in photos?',
        'We do our best to display accurate colours. However, colours can look slightly '
            'different depending on your device display settings.',
      ),
      _FaqItem(
        'How do I care for my THIRAA clothing?',
        'Care instructions are provided on the garment label and, where available, on the '
            'product page. Always follow the care instructions provided for the specific item.',
      ),
      _FaqItem(
        'A product I want is out of stock. What can I do?',
        'If a Notify Me option is available, use it to receive an update when the product '
            'is back in stock. You can also check the product page again later.',
      ),
    ],
  ),

  _FaqCategory(
    title: 'Coupons & Offers',
    icon: Icons.local_offer_outlined,
    items: [
      _FaqItem(
        'How do I apply a coupon code?',
        'At checkout, enter your coupon code in the coupon section and tap Apply. '
            'If the coupon is valid, the discount will be reflected in your order total.',
      ),
      _FaqItem(
        'Why is my coupon not working?',
        'Coupons may not work if they are expired, the minimum order value is not met, '
            'the products are not eligible, or the coupon has already been used. Check the '
            'coupon terms for details.',
      ),
      _FaqItem(
        'Can I use multiple coupons on one order?',
        'Generally, only one coupon can be applied per order. Other promotional or bank '
            'offers may be combined when their terms allow it.',
      ),
    ],
  ),

  _FaqCategory(
    title: 'Account & Privacy',
    icon: Icons.person_outline,
    items: [
      _FaqItem(
        'How do I change my password?',
        'Go to My Account → Profile → Change Password. You can also use Forgot Password '
            'from the login screen to reset your password using the available verification method.',
      ),
      _FaqItem(
        'Can I have multiple delivery addresses saved?',
        'Yes. You can save multiple delivery addresses from My Account → Saved Addresses '
            'and select your preferred address during checkout.',
      ),
      _FaqItem(
        'How do I delete my account?',
        'Go to My Account → Profile and use the Delete Account option if available. '
            'Account deletion is permanent, so make sure you do not have any pending orders '
            'or refunds before proceeding.',
      ),
      _FaqItem(
        'Is my personal data safe?',
        'We use your information to provide and improve our services, process orders and '
            'communicate important updates. Please refer to our Privacy Policy for more details.',
      ),
    ],
  ),
];

// -----------------------------------------------------------------------------
// FAQ SCREEN
// -----------------------------------------------------------------------------

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  String _query = '';
  String? _expanded;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<_FaqCategory> get _filtered {
    if (_query.trim().isEmpty) {
      return _categories;
    }

    final q = _query.toLowerCase().trim();

    return _categories
        .map(
          (category) => _FaqCategory(
            title: category.title,
            icon: category.icon,
            items: category.items
                .where(
                  (item) =>
                      item.question.toLowerCase().contains(q) ||
                      item.answer.toLowerCase().contains(q),
                )
                .toList(),
          ),
        )
        .where((category) => category.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Container(
      color: _canvas,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),

            const SizedBox(height: 20),

            _buildSearch(),

            const SizedBox(height: 20),

            if (filtered.isEmpty)
              _buildNoResults()
            else
              ...List.generate(filtered.length, (index) {
                final category = filtered[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _CategoryCard(
                    category: category,
                    categoryIndex: index,
                    expandedKey: _expanded,
                    onToggle: (key) {
                      setState(() {
                        _expanded = _expanded == key ? null : key;
                      });
                    },
                  ),
                );
              }),

            const SizedBox(height: 10),

            const _ContactSupportCard(),
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
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Find quick answers to the most common questions.',
          style: TextStyle(fontSize: 13, color: _muted),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------------

  Widget _buildSearch() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (value) {
        setState(() {
          _query = value;
        });
      },
      style: const TextStyle(fontSize: 14, color: _ink),
      decoration: InputDecoration(
        hintText: 'Search questions...',
        hintStyle: const TextStyle(fontSize: 14, color: _muted),
        prefixIcon: const Icon(Icons.search, size: 20, color: _muted),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18, color: _muted),
                onPressed: () {
                  _searchCtrl.clear();

                  setState(() {
                    _query = '';
                    _expanded = null;
                  });
                },
              )
            : null,
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NO RESULTS
  // ---------------------------------------------------------------------------

  Widget _buildNoResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 42, color: _muted.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Try different keywords or contact support.',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CATEGORY CARD
// -----------------------------------------------------------------------------

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.categoryIndex,
    required this.expandedKey,
    required this.onToggle,
  });

  final _FaqCategory category;
  final int categoryIndex;
  final String? expandedKey;
  final void Function(String key) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accentSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(category.icon, size: 19, color: _accent),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    category.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: _line),

          ...List.generate(category.items.length, (index) {
            final item = category.items[index];

            final key = '$categoryIndex-$index';

            final isExpanded = expandedKey == key;

            final isLast = index == category.items.length - 1;

            return Column(
              children: [
                InkWell(
                  onTap: () => onToggle(key),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.question,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isExpanded
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isExpanded ? _accent : _ink,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            size: 20,
                            color: isExpanded ? _accent : _muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accentSoft.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        item.answer,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _ink,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),

                if (!isLast)
                  const Divider(
                    height: 1,
                    color: _line,
                    indent: 16,
                    endIndent: 16,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CONTACT SUPPORT
// -----------------------------------------------------------------------------

class _ContactSupportCard extends StatelessWidget {
  const _ContactSupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _accent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.headset_mic_outlined,
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 11),
              const Text(
                'Still have questions?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          const Text(
            'Our support team is available to help with orders, '
            'returns and other questions.',
            style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Open live chat
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 15),
                  label: const Text(
                    'Live chat',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: _accent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Open email / support ticket
                  },
                  icon: const Icon(Icons.mail_outline, size: 15),
                  label: const Text('Email us', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
