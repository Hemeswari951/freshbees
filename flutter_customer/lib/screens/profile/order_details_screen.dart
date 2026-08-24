import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderDetailsScreen extends StatelessWidget {
  final int orderId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  static const Color bg = Color(0xFFF6F6F7);
  static const Color ink = Color(0xFF1A1A1D);
  static const Color muted = Color(0xFF8A8A8E);
  static const Color line = Color(0xFFE7E7E9);
  static const Color accent = Color(0xFF17B978);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,

        // IMPORTANT:
        // This returns to Orders screen.
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: ink,
          ),
          onPressed: () {
            context.pop();
          },
        ),

        title: const Text(
          'Order Details',
          style: TextStyle(
            color: ink,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --------------------------------------------------
            // ORDER HEADER
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'Order #$orderId',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Order details',
                    style: TextStyle(
                      fontSize: 13,
                      color: muted,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Status',
                        style: TextStyle(
                          color: muted,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Processing',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // PRODUCT SECTION
            // --------------------------------------------------

            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: const Text(
                'Order item details will appear here.',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --------------------------------------------------
            // PAYMENT
            // --------------------------------------------------

            const Text(
              'Payment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: line),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Payment Method',
                    style: TextStyle(
                      color: muted,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Cash on Delivery',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w600,
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
}