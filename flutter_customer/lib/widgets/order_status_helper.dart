import 'package:flutter/material.dart';
import 'app_colors.dart';

/// The 4 real tracking stages an order_item moves through.
/// Index matches progress position in the tracker UI.
/// (Cancelled is a terminal state handled separately, not on this track.)
const List<String> kOrderStages = ['Processing', 'Packing', 'Shipping', 'Delivered'];

class OrderStatusInfo {
  final String label;
  final Color color;
  final Color bg;
  final IconData icon;
  final int stageIndex; // -1 for Cancelled
  final bool isCancelled;
  final bool isDelivered;

  const OrderStatusInfo({
    required this.label,
    required this.color,
    required this.bg,
    required this.icon,
    required this.stageIndex,
    required this.isCancelled,
    required this.isDelivered,
  });
}

OrderStatusInfo resolveOrderStatus(String? rawStatus) {
  final status = (rawStatus ?? 'Processing').trim();

  switch (status.toLowerCase()) {
    case 'processing':
      return const OrderStatusInfo(
        label: 'Processing',
        color: AppColors.amber,
        bg: AppColors.amberSoft,
        icon: Icons.receipt_long_outlined,
        stageIndex: 0,
        isCancelled: false,
        isDelivered: false,
      );

    case 'packing':
      return const OrderStatusInfo(
        label: 'Packing',
        color: AppColors.amber,
        bg: AppColors.amberSoft,
        icon: Icons.inventory_2_outlined,
        stageIndex: 1,
        isCancelled: false,
        isDelivered: false,
      );

    case 'shipping':
    case 'shipped':
      return const OrderStatusInfo(
        label: 'Shipping',
        color: AppColors.blue,
        bg: AppColors.blueSoft,
        icon: Icons.local_shipping_outlined,
        stageIndex: 2,
        isCancelled: false,
        isDelivered: false,
      );

    case 'delivered':
      return const OrderStatusInfo(
        label: 'Delivered',
        color: AppColors.green,
        bg: AppColors.greenSoft,
        icon: Icons.check_circle_outline,
        stageIndex: 3,
        isCancelled: false,
        isDelivered: true,
      );

    case 'cancelled':
      return const OrderStatusInfo(
        label: 'Cancelled',
        color: AppColors.red,
        bg: AppColors.redSoft,
        icon: Icons.cancel_outlined,
        stageIndex: -1,
        isCancelled: true,
        isDelivered: false,
      );

    default:
      return const OrderStatusInfo(
        label: 'Processing',
        color: AppColors.amber,
        bg: AppColors.amberSoft,
        icon: Icons.receipt_long_outlined,
        stageIndex: 0,
        isCancelled: false,
        isDelivered: false,
      );
  }
}

String formatOrderDate(DateTime? date) {
  if (date == null) return '';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final local = date.toLocal();

  return '${months[local.month - 1]} ${local.day.toString().padLeft(2, '0')}, ${local.year}';
}

String formatOrderTime(DateTime? date) {
  if (date == null) return '';

  final local = date.toLocal();
  final hour24 = local.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = hour24 >= 12 ? 'PM' : 'AM';

  return '$hour12:$minute $period';
}