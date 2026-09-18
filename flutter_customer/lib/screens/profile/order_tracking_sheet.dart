import 'package:flutter/material.dart';

import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../widgets/app_colors.dart';

/// Opens the "Track item" bottom sheet — a dedicated tracking screen for
/// one order item, in the same spirit as Myntra's Track Item popup:
/// a vertical timeline of Order Placed -> Packed -> Shipped -> Delivered,
/// with the current stage highlighted and the rest greyed out.
Future<void> showOrderTrackingSheet(
  BuildContext context, {
  required OrderItemModel item,
  required DateTime? placedAt,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _TrackingSheet(item: item, placedAt: placedAt),
  );
}

class _TrackStep {
  final String status; // matches item_status
  final String title;
  final String subtitleDone;
  final IconData icon;

  const _TrackStep({
    required this.status,
    required this.title,
    required this.subtitleDone,
    required this.icon,
  });
}

const List<_TrackStep> _steps = [
  _TrackStep(
    status: 'Pending',
    title: 'Order Placed',
    subtitleDone: 'Your order has been placed',
    icon: Icons.receipt_long_rounded,
  ),
  _TrackStep(
    status: 'Processing',
    title: 'Order Confirmed',
    subtitleDone: 'Your order has been confirmed by the shop',
    icon: Icons.task_alt_rounded,
  ),
  _TrackStep(
    status: 'Packed',
    title: 'Packed',
    subtitleDone: 'Your item has been packed by the seller',
    icon: Icons.inventory_2_rounded,
  ),
  _TrackStep(
    status: 'Shipped',
    title: 'Shipped',
    subtitleDone: 'Your item is on the way',
    icon: Icons.local_shipping_rounded,
  ),
  _TrackStep(
    status: 'Delivered',
    title: 'Delivered',
    subtitleDone: 'Your item has been delivered',
    icon: Icons.home_rounded,
  ),
];

class _TrackingSheet extends StatelessWidget {
  final OrderItemModel item;
  final DateTime? placedAt;

  const _TrackingSheet({required this.item, required this.placedAt});

  bool get _isCancelled => item.itemStatus.toLowerCase() == 'cancelled';

  int get _currentIndex {
    final idx = _steps.indexWhere(
      (s) => s.status.toLowerCase() == item.itemStatus.toLowerCase(),
    );
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiService.imageUrl(item.productImage);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Track item',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
              const Divider(height: 1, color: AppColors.line),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  children: [
                    // Item summary strip
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 66,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.line),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image_outlined,
                                    color: AppColors.textLight,
                                  ),
                                )
                              : const Icon(
                                  Icons.image_outlined,
                                  color: AppColors.textLight,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName ?? 'Product',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: AppColors.ink,
                                ),
                              ),
                              if (item.shopName != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  item.shopName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.inkSoft,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    if (_isCancelled)
                      _buildCancelledCard()
                    else
                      ..._buildTimeline(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCancelledCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel_rounded, color: AppColors.red),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order cancelled',
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.red),
                ),
                SizedBox(height: 4),
                Text(
                  'This item was cancelled as per your request.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTimeline() {
    return List.generate(_steps.length, (i) {
      final step = _steps[i];
      final isDone = i <= _currentIndex;
      final isCurrent = i == _currentIndex;
      final isLast = i == _steps.length - 1;

      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // dot + connector
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? AppColors.terracotta : AppColors.white,
                    border: Border.all(
                      color: isDone ? AppColors.terracotta : AppColors.line,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isDone ? Icons.check_rounded : step.icon,
                    size: 17,
                    color: isDone ? AppColors.white : AppColors.textLight,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: i < _currentIndex ? AppColors.terracotta : AppColors.line,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 26, top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: isDone ? AppColors.ink : AppColors.textLight,
                            ),
                          ),
                        ),
                        if (step.status == 'Pending' && isDone && placedAt != null)
                          Text(
                            _formatTime(placedAt!),
                            style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isDone
                          ? step.subtitleDone
                          : 'Pending',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDone ? AppColors.inkSoft : AppColors.textLight,
                      ),
                    ),
                    if (step.status == 'Pending' && isDone && placedAt != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        _formatDateTime(placedAt!),
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textLight),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  static String _formatTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }

  static String _formatDateTime(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · $hour:$minute $ampm';
  }
}