// ============================================================================
//  screens/profile/faq_screen.dart
//  Static FAQ content — drop into ProfileDetailsScreen._buildContent()
//
//  Usage:
//    case ProfileSection.faqs:
//      return const FaqScreen();
// ============================================================================

import 'package:flutter/material.dart';

// ── Palette — matches profile_details_screen.dart exactly ───────────────────
const _ink       = Color(0xFF1A1A1D);
const _surface   = Colors.white;
const _canvas    = Color(0xFFF6F6F7);
const _muted     = Color(0xFF8A8A8E);
const _line      = Color(0xFFE7E7E9);
const _accent    = Color(0xFF17B978);
const _accentSoft= Color(0xFFE4F7EE);

// ── FAQ data model ───────────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

class _FaqCategory {
  final String title;
  final IconData icon;
  final List<_FaqItem> items;
  const _FaqCategory({required this.title, required this.icon, required this.items});
}

// ── Static FAQ content ───────────────────────────────────────────────────────

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
        'Standard delivery takes 3–5 business days. Express delivery (available at checkout) '
        'delivers within 1–2 business days. Delivery times may vary during sale seasons or '
        'public holidays.',
      ),
      _FaqItem(
        'Can I change my delivery address after placing an order?',
        'You can change the delivery address within 1 hour of placing the order by contacting '
        'our support team. Once the order is dispatched, address changes are not possible.',
      ),
      _FaqItem(
        'What if I am not available at the time of delivery?',
        'Our delivery partner will attempt delivery up to 3 times. After 3 failed attempts, '
        'the order will be returned to us. You can contact support to reschedule or get a refund.',
      ),
      _FaqItem(
        'Do you deliver outside India?',
        'Currently Thiraa delivers only within India. International shipping will be available soon. '
        'Stay tuned for updates.',
      ),
    ],
  ),
  _FaqCategory(
    title: 'Returns & Refunds',
    icon: Icons.assignment_return_outlined,
    items: [
      _FaqItem(
        'What is your return policy?',
        'We accept returns within 7 days of delivery. The product must be unused, unwashed, '
        'with original tags attached and in original packaging. Items marked as "Final Sale" '
        'cannot be returned.',
      ),
      _FaqItem(
        'How do I initiate a return?',
        'Go to My Account → Orders → select the order → tap "Return Item". Choose the reason, '
        'upload a photo if required, and submit. Our team will review and schedule a pickup '
        'within 48 hours.',
      ),
      _FaqItem(
        'When will I receive my refund?',
        'Once we receive and inspect the returned item (usually 2–3 business days after pickup), '
        'the refund is processed within 5–7 business days to your original payment method. '
        'UPI and wallet refunds may be faster.',
      ),
      _FaqItem(
        'Can I exchange a product instead of returning it?',
        'Yes! During the return process, select "Exchange" instead of "Refund". You can exchange '
        'for a different size or colour of the same product, subject to availability.',
      ),
    ],
  ),
  _FaqCategory(
    title: 'Payments',
    icon: Icons.payment_outlined,
    items: [
      _FaqItem(
        'What payment methods do you accept?',
        'We accept UPI (GPay, PhonePe, Paytm), Credit/Debit cards (Visa, Mastercard, RuPay), '
        'Net Banking, and Cash on Delivery (COD) for orders up to ₹5,000.',
      ),
      _FaqItem(
        'Is my payment information secure?',
        'Yes. We use 256-bit SSL encryption for all transactions. We do not store your card '
        'details on our servers. All payments are processed through PCI-DSS compliant gateways.',
      ),
      _FaqItem(
        'What should I do if my payment failed but amount was deducted?',
        'Failed payments are automatically reversed within 5–7 business days by your bank. '
        'If the amount is not reversed, contact your bank with the transaction reference number, '
        'or reach out to our support team with the order ID.',
      ),
      _FaqItem(
        'Can I pay using Cash on Delivery?',
        'COD is available for orders up to ₹5,000 in select pin codes. At checkout, '
        'if COD is available for your address, it will appear as a payment option.',
      ),
    ],
  ),
  _FaqCategory(
    title: 'Products & Sizing',
    icon: Icons.checkroom_outlined,
    items: [
      _FaqItem(
        'How do I find the right size?',
        'Each product page has a "Size Guide" button. Tap it to see measurements in centimetres. '
        'If you are between sizes, we recommend sizing up for a comfortable fit. '
        'You can also use the Live Chat to ask our style team.',
      ),
      _FaqItem(
        'Are the product colours accurate in photos?',
        'We do our best to display accurate colours. However, colours may appear slightly '
        'different depending on your phone screen settings. The product description mentions '
        'any significant colour variations.',
      ),
      _FaqItem(
        'How do I care for my Thiraa clothing?',
        'Care instructions are printed on the garment label and also mentioned on the product page '
        'under the "Care" tab. Most items are machine-washable in cold water unless stated otherwise.',
      ),
      _FaqItem(
        'A product I want is out of stock. What can I do?',
        'Tap the "Notify Me" button on the product page and enter your email. We will alert you '
        'as soon as the item is back in stock. You can also check back in a few days as we '
        'restock popular items frequently.',
      ),
    ],
  ),
  _FaqCategory(
    title: 'Coupons & Offers',
    icon: Icons.local_offer_outlined,
    items: [
      _FaqItem(
        'How do I apply a coupon code?',
        'At checkout, you will see a "Have a coupon?" field. Enter your code and tap Apply. '
        'The discount will be deducted from your order total before payment.',
      ),
      _FaqItem(
        'Why is my coupon not working?',
        'Coupons may not work if: the code has expired, the order total is below the minimum '
        'required amount, the coupon is not applicable to sale items, or it has already been used. '
        'Check the coupon terms or contact support for help.',
      ),
      _FaqItem(
        'Can I use multiple coupons on one order?',
        'Only one coupon can be applied per order. However, a coupon can be combined with '
        'bank offers (e.g. 10% off on HDFC cards) if both conditions are met.',
      ),
    ],
  ),
  _FaqCategory(
    title: 'Account & Privacy',
    icon: Icons.person_outline,
    items: [
      _FaqItem(
        'How do I change my password?',
        'Go to My Account → Profile → tap "Change Password". Enter your current password, '
        'then set a new one. You can also use "Forgot Password" on the login screen '
        'to reset it via OTP.',
      ),
      _FaqItem(
        'Can I have multiple delivery addresses saved?',
        'Yes. Go to My Account → Saved Addresses → tap "Add New Address". You can save '
        'up to 5 addresses and select one at checkout.',
      ),
      _FaqItem(
        'How do I delete my account?',
        'Go to My Account → Profile → scroll to the bottom → tap "Delete Account". '
        'Note: this action is permanent and will cancel any active orders. '
        'Contact support before deleting if you have pending orders or refunds.',
      ),
      _FaqItem(
        'Is my personal data safe?',
        'Yes. We collect only the data needed to process your orders and improve your experience. '
        'We do not sell your data to third parties. Read our full Privacy Policy for details.',
      ),
    ],
  ),
];

// ── FAQ Screen Widget ────────────────────────────────────────────────────────

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchCtrl  = TextEditingController();
  String _query      = '';

  // Track which item is expanded: 'categoryIndex-itemIndex'
  String? _expanded;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Filter categories and items based on search query
  List<_FaqCategory> get _filtered {
    if (_query.trim().isEmpty) return _categories;
    final q = _query.toLowerCase();
    return _categories
        .map((cat) => _FaqCategory(
              title: cat.title,
              icon: cat.icon,
              items: cat.items
                  .where((item) =>
                      item.question.toLowerCase().contains(q) ||
                      item.answer.toLowerCase().contains(q))
                  .toList(),
            ))
        .where((cat) => cat.items.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page title
          const Text(
            'Frequently asked questions',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _ink),
          ),
          const SizedBox(height: 4),
          const Text(
            'Find quick answers to the most common questions.',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
          const SizedBox(height: 18),

          // Search bar
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 14, color: _ink),
            decoration: InputDecoration(
              hintText: 'Search questions…',
              hintStyle: const TextStyle(fontSize: 14, color: _muted),
              prefixIcon: const Icon(Icons.search, size: 20, color: _muted),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18, color: _muted),
                      onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); },
                    )
                  : null,
              filled: true,
              fillColor: _surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _line, width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _line, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _accent, width: 1),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Empty state when search returns nothing
          if (filtered.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 40, color: _muted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  const Text('No results found',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 4),
                  Text('Try different keywords or contact support',
                      style: TextStyle(fontSize: 13, color: _muted.withOpacity(0.8))),
                ],
              ),
            )
          else
            // FAQ categories
            ...List.generate(filtered.length, (ci) {
              final cat = filtered[ci];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CategoryCard(
                  category: cat,
                  categoryIndex: ci,
                  expandedKey: _expanded,
                  onToggle: (key) => setState(() => _expanded = _expanded == key ? null : key),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Still have questions — contact support card
          _ContactSupportCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.categoryIndex,
    required this.expandedKey,
    required this.onToggle,
  });

  final _FaqCategory category;
  final int          categoryIndex;
  final String?      expandedKey;
  final void Function(String key) onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: _accentSoft, borderRadius: BorderRadius.circular(8)),
                child: Icon(category.icon, size: 17, color: _accent),
              ),
              const SizedBox(width: 10),
              Text(
                category.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink),
              ),
            ]),
          ),
          const Divider(height: 0.5, thickness: 0.5, color: _line),

          // FAQ items
          ...List.generate(category.items.length, (ii) {
            final item = category.items[ii];
            final key  = '$categoryIndex-$ii';
            final isExpanded = expandedKey == key;
            final isLast     = ii == category.items.length - 1;

            return Column(
              children: [
                InkWell(
                  onTap: () => onToggle(key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.question,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
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

                // Animated answer
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accentSoft.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
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

                if (!isLast) const Divider(height: 0.5, thickness: 0.5, color: _line, indent: 16, endIndent: 16),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Contact support card ──────────────────────────────────────────────────────

class _ContactSupportCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.25), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.headset_mic_outlined, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text(
              'Still have questions?',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _ink),
            ),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Our support team is available Mon–Sat, 9 AM – 6 PM IST. '
            'We typically respond within 2 hours.',
            style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},   // TODO: open live chat
                icon: const Icon(Icons.chat_bubble_outline, size: 15),
                label: const Text('Live chat', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _accent,
                  side: const BorderSide(color: _accent, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},   // TODO: open email / raise ticket
                icon: const Icon(Icons.mail_outline, size: 15),
                label: const Text('Email us', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}