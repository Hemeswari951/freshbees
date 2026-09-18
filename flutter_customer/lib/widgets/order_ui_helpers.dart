import 'package:flutter/material.dart';

import 'app_colors.dart';

class OrderStatusStyle {
  final Color fg;
  final String helper;
  const OrderStatusStyle(this.fg, this.helper);
}

OrderStatusStyle resolveOrderItemStatusStyle(String status) {
  switch (status.toLowerCase()) {
    case 'delivered':
      return const OrderStatusStyle(AppColors.green, 'Your item has been delivered');
    case 'shipped':
      return const OrderStatusStyle(AppColors.blue, 'Your item is on the way');
    case 'packed':
      return const OrderStatusStyle(AppColors.gold, 'Your item has been packed');
    case 'cancelled':
      return const OrderStatusStyle(AppColors.red, 'Cancelled as per your request');
    case 'confirmed':
    case 'processing':
      return const OrderStatusStyle(AppColors.blue, 'Your order is confirmed');
    case 'pending':
      return const OrderStatusStyle(AppColors.amber, 'Waiting for the shop to confirm');
    default:
      return const OrderStatusStyle(AppColors.amber, 'Being prepared by the seller');
  }
}

/// Plain colored dot + bold status + grey helper line. Flipkart/Myntra
/// never wrap this in a filled background box — it's always just
/// colored text sitting directly on the page/card background.
class OrderStatusRow extends StatelessWidget {
  final String status;
  final bool alignEnd;

  const OrderStatusRow({super.key, required this.status, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    final s = resolveOrderItemStatusStyle(status);

    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: s.fg)),
            const SizedBox(width: 6),
            Text(status, style: TextStyle(color: s.fg, fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          s.helper,
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
          style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
        ),
      ],
    );
  }
}

/// Plain colored text + icon, no border/fill — the "Track Item" /
/// "Cancel Item" / "Rate & Review Product" link style Flipkart and
/// Myntra both use instead of bordered pill buttons.
class OrderLinkAction extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const OrderLinkAction({
    super.key,
    required this.icon,
    this.iconColor,
    required this.label,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  )
                : Icon(icon, size: 15, color: iconColor ?? color),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}