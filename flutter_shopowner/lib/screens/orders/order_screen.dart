import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_colors.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

// Tab label -> backend item_status. "New Orders" shows Pending items —
// the ones the shop owner still needs to Confirm/Cancel.
const Map<String, String> _tabs = {
  'New Orders': 'Pending',
  'Processing': 'Processing',
  'Packed': 'Packed',
  'Shipped': 'Shipped',
  'Delivered': 'Delivered',
  'Cancelled': 'Cancelled',
};

class _OrdersScreenState extends State<OrdersScreen> {
  String _activeTab = 'New Orders';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final orders = await OrderService.getOrders(status: _tabs[_activeTab]);
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

  void _selectTab(String tab) {
    if (tab == _activeTab) return;
    setState(() => _activeTab = tab);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            children: [
              const Text(
                'Orders',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textDark),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.accentBrown),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildTabs(),
        const SizedBox(height: 16),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildTabs() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final tab = _tabs.keys.elementAt(i);
          final active = tab == _activeTab;
          return InkWell(
            onTap: () => _selectTab(tab),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? AppColors.brown : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: active ? AppColors.brown : AppColors.border),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: active ? AppColors.white : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brown));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.warning),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 14),
              OutlinedButton(onPressed: _load, child: const Text('RETRY')),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 46, color: AppColors.textLight),
            const SizedBox(height: 12),
            Text('No orders in "$_activeTab"', style: const TextStyle(color: AppColors.textGrey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, i) => _OrderCard(order: _orders[i]),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final image = order['product_image'] as String?;
    final orderId = order['order_id'];
    final productName = order['product_name'] ?? 'Product';
    final size = order['variant_size'];
    final color = order['color_name'];
    final quantity = order['quantity'] ?? 1;
    final price = double.tryParse(order['price']?.toString() ?? '0') ?? 0;
    final stock = order['stock_quantity'];
    final status = order['item_status'] ?? 'Pending';
    final createdAt = DateTime.tryParse(order['item_created_at']?.toString() ?? '');
    final city = order['delivery_city'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Order #$orderId',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.textDark),
              ),
              const Spacer(),
              _StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 76,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                  color: AppColors.brownLight,
                ),
                clipBehavior: Clip.antiAlias,
                child: (image != null && image.isNotEmpty)
                    ? Image.network(
                        ProductService.fullImageUrl(image),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: AppColors.textLight),
                      )
                    : const Icon(Icons.image_outlined, color: AppColors.textLight),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      children: [
                        if (size != null) _label('Size: $size'),
                        if (color != null) _label(color.toString()),
                        _label('Qty: $quantity'),
                        if (stock != null) _label('Stock: $stock'),
                      ],
                    ),
                    if (city != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textLight),
                          const SizedBox(width: 3),
                          Text(city.toString(), style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
                        ],
                      ),
                    ],
                    if (createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(_formatDateTime(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/orders/$orderId'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brown,
                side: const BorderSide(color: AppColors.brown),
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
              ),
              child: const Text('VIEW DETAILS', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, letterSpacing: 0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey));

  static String _formatDateTime(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $hour:$minute $ampm';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (status) {
      case 'Pending':
        bg = AppColors.amberTagBg;
        fg = AppColors.amberTagText;
        break;
      case 'Processing':
        bg = AppColors.blueSoft;
        fg = AppColors.blue;
        break;
      case 'Packed':
        bg = AppColors.terracottaSoft;
        fg = AppColors.terracotta;
        break;
      case 'Shipped':
        bg = AppColors.blueSoft;
        fg = AppColors.blue;
        break;
      case 'Delivered':
        bg = AppColors.greenTagBg;
        fg = AppColors.greenTagText;
        break;
      case 'Cancelled':
        bg = AppColors.redLight;
        fg = AppColors.warning;
        break;
      default:
        bg = AppColors.amberTagBg;
        fg = AppColors.amberTagText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 11)),
    );
  }
}
