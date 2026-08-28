import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/order_model.dart';
import '../../services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  String? _error;

  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final orders = await OrderService.getMyOrders();

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),

              Text(
                _error!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _loadOrders,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 24),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          return _OrderCard(
            order: _orders[index],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),

          const SizedBox(height: 16),

          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Your orders will appear here',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFE7E7E9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------------------------------------------------
          // ORDER HEADER
          // --------------------------------------------------

          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              _StatusBadge(
                status: order.orderStatus ?? 'Pending',
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            _formatDate(order.createdAt),
            style: const TextStyle(
              color: Color(0xFF8A8A8E),
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 16),

          // --------------------------------------------------
          // PRODUCTS
          // --------------------------------------------------

          ...order.items.map(
            (item) => _OrderItemRow(item: item),
          ),

          const SizedBox(height: 14),

          const Divider(
            height: 1,
            color: Color(0xFFE7E7E9),
          ),

          const SizedBox(height: 14),

          // --------------------------------------------------
          // TOTAL
          // --------------------------------------------------

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Color(0xFF8A8A8E),
                  fontSize: 13,
                ),
              ),

              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.push(
      '/profile/details/orders/${order.orderId}',
    );
              },
              child: const Text(
                'VIEW ORDER',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItemModel item;

  const _OrderItemRow({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: 68,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF6F6F7),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.productImage != null &&
                    item.productImage!.isNotEmpty
                ? Image.network(
                    item.productImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                      );
                    },
                  )
                : const Icon(
                    Icons.image_outlined,
                    color: Colors.grey,
                  ),
          ),

          const SizedBox(width: 12),

          // Product details
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
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 5),

                if (item.shopName != null)
                  Text(
                    item.shopName!,
                    style: const TextStyle(
                      color: Color(0xFF8A8A8E),
                      fontSize: 12,
                    ),
                  ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    if (item.size != null)
                      Text(
                        'Size: ${item.size}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF55555A),
                        ),
                      ),

                    if (item.size != null &&
                        item.colorName != null)
                      const SizedBox(width: 10),

                    if (item.colorName != null)
                      Text(
                        item.colorName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF55555A),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 5),

                Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8A8E),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '₹${item.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    switch (status.toLowerCase()) {
      case 'delivered':
        background = const Color(0xFFE4F7EE);
        foreground = const Color(0xFF168A5A);
        break;

      case 'shipped':
        background = const Color(0xFFEAF2FF);
        foreground = const Color(0xFF3567B8);
        break;

      case 'cancelled':
        background = const Color(0xFFFFEEEE);
        foreground = const Color(0xFFC0392B);
        break;

      default:
        background = const Color(0xFFFFF4E5);
        foreground = const Color(0xFF9A6418);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}