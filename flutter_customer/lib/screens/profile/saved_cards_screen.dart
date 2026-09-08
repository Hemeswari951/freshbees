import 'package:flutter/material.dart';

class SavedCardsScreen extends StatelessWidget {
  const SavedCardsScreen({super.key});

  static const Color _bg = Color(0xFFF6F6F7);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFE7E7E9);
  static const Color _ink = Color(0xFF1A1A1D);
  static const Color _muted = Color(0xFF8A8A8E);
  static const Color _softBg = Color(0xFFF2ECE4);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),

          const SizedBox(height: 20),

          _buildEmptyState(),

          const SizedBox(height: 20),

          _buildSecurityInfo(),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Cards',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),

        SizedBox(height: 5),

        Text(
          'Manage your saved payment methods',
          style: TextStyle(fontSize: 13, color: _muted),
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: _softBg,
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
              color: _ink,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Save a payment method during checkout '
            'for faster and easier payments.',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 13, height: 1.5),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Payment gateway integration
                // can be connected here.
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('ADD PAYMENT METHOD'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ============================================================
  // SECURITY
  // ============================================================

  Widget _buildSecurityInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _softBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 20, color: _accent),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Your card details are securely handled '
              'by our payment provider. THIRAA does not '
              'store your full card number or CVV.',
              style: TextStyle(fontSize: 12, color: _muted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
