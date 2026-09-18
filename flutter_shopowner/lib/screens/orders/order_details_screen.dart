import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_colors.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';

/// Order Details for the shop owner — shows every one of THIS shop's items
/// within [orderId] (a multi-vendor order may have other shops' items too,
/// those never reach this screen). Each item card carries its own status
/// timeline + the action button(s) valid for its current status, since
/// item_status is tracked independently per item (spec section 10).
class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  // orderItemId currently mid-action, to disable its buttons while a
  // request is in flight (prevents double taps double-firing an update).
  int? _busyItemId;

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
      final items = await OrderService.getOrderById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _runAction(int orderItemId, Future<void> Function() action) async {
    setState(() => _busyItemId = orderItemId);
    try {
      await action();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyItemId = null);
    }
  }

  Future<void> _confirm(int orderItemId) =>
      _runAction(orderItemId, () => OrderService.confirmOrder(orderItemId));

  Future<void> _markPacked(int orderItemId) =>
      _runAction(orderItemId, () => OrderService.markPacked(orderItemId));

  Future<void> _markShipped(int orderItemId) =>
      _runAction(orderItemId, () => OrderService.markShipped(orderItemId));

  Future<void> _markDelivered(int orderItemId) =>
      _runAction(orderItemId, () => OrderService.markDelivered(orderItemId));

  Future<void> _cancel(int orderItemId) async {
    final result = await showDialog<_CancelResult>(
      context: context,
      builder: (_) => const _CancelReasonDialog(),
    );
    if (result == null) return;

    await _runAction(
      orderItemId,
      () => OrderService.cancelOrder(
        orderItemId,
        reason: result.reason,
        customReason: result.customReason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.canPop() ? context.pop() : context.go('/orders'),
        ),
        title: Text(
          'Order #${widget.orderId}',
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: _buildBody(),
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
              const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.warning),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.brown, foregroundColor: AppColors.white),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(child: Text('No items for your shop in this order', style: TextStyle(color: AppColors.textGrey)));
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brown,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: _items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _ItemDetailCard(
                    item: item,
                    busy: _busyItemId == item['order_item_id'],
                    onConfirm: () => _confirm(item['order_item_id']),
                    onCancel: () => _cancel(item['order_item_id']),
                    onPacked: () => _markPacked(item['order_item_id']),
                    onShipped: () => _markShipped(item['order_item_id']),
                    onDelivered: () => _markDelivered(item['order_item_id']),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ============================================================================
// ITEM DETAIL CARD
// ============================================================================

class _ItemDetailCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onPacked;
  final VoidCallback onShipped;
  final VoidCallback onDelivered;

  const _ItemDetailCard({
    required this.item,
    required this.busy,
    required this.onConfirm,
    required this.onCancel,
    required this.onPacked,
    required this.onShipped,
    required this.onDelivered,
  });

  String get _status => item['item_status'] ?? 'Pending';

  @override
  Widget build(BuildContext context) {
    final image = item['product_image'] as String?;
    final productName = item['product_name'] ?? 'Product';
    final size = item['variant_size'];
    final color = item['color_name'];
    final quantity = item['quantity'] ?? 1;
    final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0;
    final stock = item['stock_quantity'];
    final paymentStatus = item['payment_status'];
    final deliveryName = item['delivery_name'];
    final deliveryPhone = item['delivery_phone'];
    final addressLines = [
      item['address_line1'],
      item['address_line2'],
      [item['delivery_city'], item['delivery_state'], item['delivery_pincode']]
          .where((e) => e != null && e.toString().isNotEmpty)
          .join(', '),
    ].where((e) => e != null && e.toString().isNotEmpty).toList();

    return Container(
      width: double.infinity,
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
          // Product row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 86,
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
                    Text(productName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      children: [
                        if (size != null) _kvText('Size: $size'),
                        if (color != null) _kvText(color.toString()),
                        _kvText('Qty: $quantity'),
                        if (stock != null) _kvText('Stock: $stock'),
                      ],
                    ),
                  ],
                ),
              ),
              Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          _OrderStatusTimeline(status: _status),

          if (_status == 'Cancelled' && item['cancellation_reason'] != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.redLight, borderRadius: BorderRadius.circular(10)),
              child: Text(
                'Cancelled: ${item['cancellation_reason']}',
                style: const TextStyle(color: AppColors.warning, fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),

          if (paymentStatus != null) _kvRow('Payment Status', paymentStatus.toString()),
          if (deliveryName != null) _kvRow('Delivery to', deliveryName.toString()),
          if (deliveryPhone != null) _kvRow('Phone', deliveryPhone.toString()),
          if (addressLines.isNotEmpty) _kvRow('Address', addressLines.join(', ')),

          const SizedBox(height: 14),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _kvText(String text) => Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textGrey));

  Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: AppColors.textGrey, fontSize: 12))),
          Expanded(child: Text(v, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildActions() {
    Widget primaryBtn(String label, VoidCallback onTap, {Color? bg}) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: busy ? null : onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: bg ?? AppColors.brown,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
          child: busy
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
              : Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      );
    }

    switch (_status) {
      case 'Pending':
        return Row(
          children: [
            Expanded(child: primaryBtn('CONFIRM ORDER', onConfirm)),
            const SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: busy ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warning,
                    side: const BorderSide(color: AppColors.warning),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                  ),
                  child: const Text('CANCEL ORDER', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                ),
              ),
            ),
          ],
        );
      case 'Processing':
        return primaryBtn('MARK AS PACKED', onPacked);
      case 'Packed':
        return primaryBtn('MARK AS SHIPPED', onShipped);
      case 'Shipped':
        return primaryBtn('MARK AS DELIVERED', onDelivered);
      case 'Delivered':
      case 'Cancelled':
      default:
        return const SizedBox.shrink();
    }
  }
}

// ============================================================================
// STATUS TIMELINE — Processing -> Packed -> Shipped -> Delivered
// (Pending is "before" this timeline — it's the Confirm/Cancel decision
// point, shown via the action buttons instead of a step.)
// ============================================================================

class _OrderStatusTimeline extends StatelessWidget {
  final String status;
  const _OrderStatusTimeline({required this.status});

  static const _steps = ['Processing', 'Packed', 'Shipped', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    if (status == 'Cancelled') {
      return Row(
        children: const [
          Icon(Icons.cancel_rounded, size: 18, color: AppColors.warning),
          SizedBox(width: 8),
          Text('Order cancelled', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      );
    }

    if (status == 'Pending') {
      return Row(
        children: const [
          Icon(Icons.hourglass_empty_rounded, size: 18, color: AppColors.amberTagText),
          SizedBox(width: 8),
          Text('Awaiting your confirmation', style: TextStyle(color: AppColors.amberTagText, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      );
    }

    final currentIndex = _steps.indexOf(status);

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final done = (i - 1) ~/ 2 < currentIndex;
          return Expanded(child: Container(height: 2, color: done ? AppColors.brown : AppColors.border));
        }
        final stepIdx = i ~/ 2;
        final done = stepIdx <= currentIndex;
        return Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.brown : AppColors.white,
                border: Border.all(color: done ? AppColors.brown : AppColors.border, width: 2),
              ),
              child: done ? const Icon(Icons.check, size: 12, color: AppColors.white) : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 58,
              child: Text(
                _steps[stepIdx],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: done ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ============================================================================
// CANCEL REASON DIALOG
// ============================================================================

class _CancelResult {
  final String reason;
  final String? customReason;
  _CancelResult(this.reason, this.customReason);
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog();

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  String? _reason;
  final _customController = TextEditingController();

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOther = _reason == 'Other';
    final canConfirm = _reason != null && (!isOther || _customController.text.trim().isNotEmpty);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Cancel this order?'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a reason', style: TextStyle(color: AppColors.textGrey, fontSize: 12.5)),
            const SizedBox(height: 8),
            ...cancellationReasons.map(
              (r) => RadioListTile<String>(
                value: r,
                groupValue: _reason,
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.brown,
                title: Text(r, style: const TextStyle(fontSize: 13.5)),
                onChanged: (v) => setState(() => _reason = v),
              ),
            ),
            if (isOther) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _customController,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter cancellation reason',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back', style: TextStyle(color: AppColors.textGrey)),
        ),
        ElevatedButton(
          onPressed: canConfirm
              ? () => Navigator.of(context).pop(
                    _CancelResult(_reason!, isOther ? _customController.text.trim() : null),
                  )
              : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning, foregroundColor: AppColors.white),
          child: const Text('CONFIRM CANCELLATION'),
        ),
      ],
    );
  }
}
