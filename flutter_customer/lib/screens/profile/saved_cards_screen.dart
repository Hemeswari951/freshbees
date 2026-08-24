import 'package:flutter/material.dart';

class SavedCardsScreen extends StatelessWidget {
  const SavedCardsScreen({super.key});

  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFEAE5DE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildEmptyState(),
                const SizedBox(height: 24),
                _buildSecurityInfo(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF2ECE4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.credit_card_outlined,
              size: 36,
              color: _accent,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'No saved cards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Save a payment method during checkout '
            'for faster and easier payments.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 14,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Payment gateway integration will be added later.
              },
              icon: const Icon(
                Icons.add,
                size: 20,
              ),
              label: const Text(
                'ADD PAYMENT METHOD',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(
                  color: _accent,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECE4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 20,
            color: _accent,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your card details are securely handled '
              'by our payment provider. THIRAA does not '
              'store your full card number or CVV.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}