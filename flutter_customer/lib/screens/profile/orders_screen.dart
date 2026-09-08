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
  // Only text/line/icon colors remain — no fixed background or card-fill
  // colors, so this screen always shows the parent's (profile screen's)
  // default background/card color.
  static const Color _ink = Color(0xFF1A1A1D);
  static const Color _muted = Color(0xFF8A8A8E);
  static const Color _line = Color(0xFFE7E7E9);
  static const Color _accent = Color(0xFF8B7355);

  bool _loading = true;
  String? _error;

  List<OrderModel> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // ============================================================
  // LOAD ORDERS
  // ============================================================

  Future<void> _loadOrders() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

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
        _orders = [];
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // No Container color here — background stays whatever the
    // profile screen already set.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildHeader(), const SizedBox(height: 20), _buildBody()],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    // Just the order count + refresh button — the section title
    // ("Orders") is already shown by the shared header in
    // ProfileDetailsScreen (mobile top bar / desktop card heading).
    return Row(
      children: [
        Expanded(
          child: Text(
            _orders.isEmpty
                ? 'View and track your orders'
                : '${_orders.length} order${_orders.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 13, color: _muted),
          ),
        ),

        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _loadOrders,
          icon: const Icon(Icons.refresh, color: _accent),
        ),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (_error != null) {
      return _buildError();
    }

    if (_orders.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return _OrderCard(order: _orders[index]);
      },
    );
  }

  // ============================================================
  // ERROR — border only, no fill
  // ============================================================

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 42, color: Colors.black26),

          const SizedBox(height: 12),

          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 13),
          ),

          const SizedBox(height: 16),

          OutlinedButton(onPressed: _loadOrders, child: const Text('RETRY')),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY — border only, no fill
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 45, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _line),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 38,
              color: _accent,
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Your orders will appear here',
            style: TextStyle(fontSize: 13, color: _muted),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ORDER CARD — border only, no fill
// ============================================================================

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  static const Color _ink = Color(0xFF1A1A1D);
  static const Color _muted = Color(0xFF8A8A8E);
  static const Color _line = Color(0xFFE7E7E9);
  static const Color _accent = Color(0xFF8B7355);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),

              _StatusBadge(status: order.orderStatus ?? 'Pending'),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            _formatDate(order.createdAt),
            style: const TextStyle(color: _muted, fontSize: 12),
          ),

          const SizedBox(height: 16),

          ...order.items.map((item) => _OrderItemRow(item: item)),

          const SizedBox(height: 6),

          const Divider(height: 1, color: _line),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: _muted, fontSize: 13),
              ),

              Text(
                '₹${order.totalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: _ink,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.push('/profile/details/orders/${order.orderId}');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: const BorderSide(color: _accent),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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

// ============================================================================
// ORDER ITEM
// ============================================================================

class _OrderItemRow extends StatelessWidget {
  final OrderItemModel item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE7E7E9)),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.productImage != null && item.productImage!.isNotEmpty
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
                : const Icon(Icons.image_outlined, color: Colors.grey),
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
                    fontSize: 14,
                  ),
                ),

                if (item.shopName != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    item.shopName!,
                    style: const TextStyle(
                      color: Color(0xFF8A8A8E),
                      fontSize: 12,
                    ),
                  ),
                ],

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

                    if (item.size != null && item.colorName != null)
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
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// STATUS BADGE
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

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

      case 'confirmed':
        background = const Color(0xFFEAF2FF);
        foreground = const Color(0xFF3567B8);
        break;

      default:
        background = const Color(0xFFFFF4E5);
        foreground = const Color(0xFF9A6418);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
