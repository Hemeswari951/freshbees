import 'package:flutter/material.dart';

/// One line item's display details for the Order Success screen —
/// shop name, product name, size, color. Built from the cart/buy-now
/// items at checkout time and carried through Payment -> Order Success.
class OrderSuccessItem {
  final String? shopName;
  final String productName;
  final String? size;
  final String? color;

  const OrderSuccessItem({
    this.shopName,
    required this.productName,
    this.size,
    this.color,
  });
}

/// Step 4 / final screen of checkout: order confirmation. Reached by
/// replacing the whole Cart → Address → Payment stack, so the back button
/// here goes straight to Home instead of back through checkout.
class OrderSuccessScreen extends StatelessWidget {
  final int orderId;
  final double subtotal;
  final String paymentMethod;
  final List<OrderSuccessItem> items;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.subtotal,
    required this.paymentMethod,
    this.items = const [],
  });

  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _cardBorder = Color(0xFFEAEAEA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Order Placed Successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Thank you for shopping with us. We'll notify you\nas soon as your order ships.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < items.length; i++) ...[
                            if (i > 0) const Divider(height: 20),
                            _itemDetails(items[i]),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _cardBorder),
                    ),
                    child: Column(
                      children: [
                        _summaryRow('Order ID', '#$orderId'),
                        const SizedBox(height: 10),
                        _summaryRow('Payment Method', paymentMethod),
                        const SizedBox(height: 10),
                        _summaryRow('Amount Paid', '₹${subtotal.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'CONTINUE SHOPPING',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemDetails(OrderSuccessItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.shopName != null && item.shopName!.isNotEmpty) ...[
          Text(
            item.shopName!,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _accent,
            ),
          ),
          const SizedBox(height: 2),
        ],
        Text(
          item.productName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        if (item.size != null || item.color != null) ...[
          const SizedBox(height: 4),
          Text(
            [
              if (item.size != null) 'Size: ${item.size}',
              if (item.color != null) 'Color: ${item.color}',
            ].join('  |  '),
            style: const TextStyle(fontSize: 12.5, color: Colors.black54),
          ),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }
}