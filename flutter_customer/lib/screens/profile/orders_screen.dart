import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/order_model.dart';
import '../../models/review_model.dart';
import '../../services/order_service.dart';
import '../../services/api_service.dart';
import '../../services/review_service.dart';
import '../../widgets/app_colors.dart';
import '../../widgets/order_ui_helpers.dart';
import '../../widgets/reviews_section.dart';
import 'order_tracking_sheet.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _loading = true;
  String? _error;

  List<OrderModel> _orders = [];

  // orderItemId currently being cancelled, if any.
  int? _cancelling;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

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

  Future<void> _cancelItem(OrderItemModel item) async {
    final result = await showModalBottomSheet<_CancelReasonResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CancelReasonSheet(productName: item.productName ?? 'This item'),
    );

    if (result == null) return;

    setState(() => _cancelling = item.orderItemId);

    try {
      await OrderService.cancelOrderItem(
        item.orderItemId,
        reason: result.reason,
        customReason: result.customReason,
      );
      await _loadOrders();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _cancelling = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildHeader(), const SizedBox(height: 18), _buildBody()],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            _orders.isEmpty
                ? 'View and track your orders'
                : '${_orders.length} order${_orders.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, fontWeight: FontWeight.w500),
          ),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _loading ? null : _loadOrders,
          icon: const Icon(Icons.refresh_rounded, color: AppColors.terracotta),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator(color: AppColors.terracotta)),
      );
    }

    if (_error != null) return _buildError();
    if (_orders.isEmpty) return _buildEmptyState();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _OrderCard(
          order: _orders[index],
          cancellingItemId: _cancelling,
          onCancel: _cancelItem,
        );
      },
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.red),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadOrders,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              foregroundColor: AppColors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 56, color: AppColors.textLight),
          const SizedBox(height: 18),
          const Text(
            'No orders yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          const Text(
            'Everything you order will show up here',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ORDER CARD — one order, may contain items from several shops
// Whole card is tappable and opens Order Details (price breakdown lives
// there now), so there's no separate "VIEW FULL ORDER" footer button.
// ============================================================================

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final int? cancellingItemId;
  final void Function(OrderItemModel item) onCancel;

  const _OrderCard({
    required this.order,
    required this.cancellingItemId,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/profile/details/orders/${order.orderId}'),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---- flat order strip: id · date on the left, total + chevron on the right ----
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Order #${order.orderId}  ',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                          ),
                          TextSpan(
                            text: '·  ${_formatDate(order.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '₹${order.activeTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textGrey),
                ],
              ),
            ),

            // ---- items, each its own flat row with a divider between ----
            for (int i = 0; i < order.items.length; i++) ...[
              if (i != 0) const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(14),
                child: _OrderItemCard(
                  item: order.items[i],
                  order: order,
                  cancelling: cancellingItemId == order.items[i].orderItemId,
                  onCancel: () => onCancel(order.items[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ============================================================================
// ORDER ITEM — image + name/shop/size/price + status + inline actions
// ============================================================================

class _OrderItemCard extends StatelessWidget {
  final OrderItemModel item;
  final OrderModel order;
  final bool cancelling;
  final VoidCallback onCancel;

  const _OrderItemCard({
    required this.item,
    required this.order,
    required this.cancelling,
    required this.onCancel,
  });

  String get _status => item.itemStatus;

  bool get _isCancellable => _status.toLowerCase() == 'pending';
  bool get _isDelivered => _status.toLowerCase() == 'delivered';
  bool get _isCancelled => _status.toLowerCase() == 'cancelled';

  static String _formatDeliveredDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Opens the write/edit review sheet directly from the orders list —
  // skips navigating to the product page first. Fetches eligibility
  // (so an already-reviewed item opens in edit mode) then shows the
  // same WriteReviewSheet the product page uses.
  Future<void> _openReviewSheet(BuildContext context) async {
    final productId = item.productId;
    if (productId == null) return;

    final token = ApiService.getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to write a review')),
      );
      return;
    }

    ReviewEligibilityModel? eligibility;
    try {
      eligibility = await ReviewService.getEligibility(productId);
    } catch (_) {
      eligibility = null; // fall back to "write new" if this fails
    }
    if (!context.mounted) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => WriteReviewSheet(
        productId: productId,
        existingReview: eligibility?.existingReview,
      ),
    );

    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks for your review!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiService.imageUrl(item.productImage);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 560;

        final thumb = Container(
          width: isWide ? 72 : 64,
          height: isWide ? 84 : 74,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            color: AppColors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: AppColors.textLight),
                )
              : const Icon(Icons.image_outlined, color: AppColors.textLight),
        );

        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.productName ?? 'Product',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textDark),
            ),
            if (item.shopName != null) ...[
              const SizedBox(height: 3),
              Text(
                item.shopName!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 3),
            Wrap(
              spacing: 10,
              children: [
                if (item.colorName != null)
                  Text(item.colorName!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                if (item.size != null)
                  Text('Size: ${item.size}', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ],
        );

        final priceAndStatus = Column(
          crossAxisAlignment: isWide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Align(
              alignment: isWide ? Alignment.topRight : Alignment.topLeft,
              child: Text(
                '₹${item.price.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 8),
            OrderStatusRow(status: _status, alignEnd: isWide),
            if (_isDelivered && item.itemUpdatedAt != null) ...[
              const SizedBox(height: 2),
              Text(
                'Delivered on ${_formatDeliveredDate(item.itemUpdatedAt!)}',
                textAlign: isWide ? TextAlign.right : TextAlign.left,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey),
              ),
            ],
          ],
        );

        final row = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  thumb,
                  const SizedBox(width: 14),
                  Expanded(flex: 3, child: details),
                  const SizedBox(width: 14),
                  SizedBox(width: 190, child: priceAndStatus),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      thumb,
                      const SizedBox(width: 12),
                      Expanded(child: details),
                    ],
                  ),
                  const SizedBox(height: 10),
                  priceAndStatus,
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row,
            if (_isCancelled && (item.cancellationReason ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Reason: ${item.cancellationReason}',
                style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ],
            const SizedBox(height: 10),
            _buildActions(context),
          ],
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    if (_isCancelled) return const SizedBox.shrink();

    if (_isDelivered) {
      return OrderLinkAction(
        icon: Icons.star_rounded,
        iconColor: AppColors.gold,
        label: 'Rate & Review Product',
        color: AppColors.blue,
        onTap: () => _openReviewSheet(context),
      );
    }

    return Wrap(
      spacing: 18,
      runSpacing: 6,
      children: [
        OrderLinkAction(
          icon: Icons.location_on_outlined,
          label: 'Track Item',
          color: AppColors.blue,
          onTap: () => showOrderTrackingSheet(context, item: item, placedAt: order.createdAt),
        ),
        if (_isCancellable)
          OrderLinkAction(
            icon: Icons.close_rounded,
            label: cancelling ? 'Cancelling…' : 'Cancel Item',
            color: AppColors.red,
            loading: cancelling,
            onTap: cancelling ? null : onCancel,
          ),
      ],
    );
  }
}

// =============================================================================
// CANCEL REASON SHEET
// =============================================================================
//
// The "why are you cancelling" bottom sheet, Flipkart/Myntra-style: a list
// of preset reasons as radio rows, the last one ("Other") revealing a text
// field for a custom reason. The Submit button stays disabled until a
// reason is actually chosen (and, for "Other", some text is typed).

class _CancelReasonResult {
  final String reason;
  final String? customReason;
  const _CancelReasonResult({required this.reason, this.customReason});
}

class _CancelReasonSheet extends StatefulWidget {
  final String productName;
  const _CancelReasonSheet({required this.productName});

  @override
  State<_CancelReasonSheet> createState() => __CancelReasonSheetState();
}

class __CancelReasonSheetState extends State<_CancelReasonSheet> {
  List<String>? _reasons;
  String? _error;
  String? _selected;
  final TextEditingController _customController = TextEditingController();

  bool get _isOther => _selected == 'Other';

  bool get _canSubmit {
    if (_selected == null) return false;
    if (_isOther) return _customController.text.trim().isNotEmpty;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final reasons = await OrderService.getCancelReasons();
      if (!mounted) return;
      setState(() => _reasons = reasons);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _submit() {
    if (!_canSubmit) return;
    Navigator.of(context).pop(
      _CancelReasonResult(
        reason: _selected!,
        customReason: _isOther ? _customController.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cancel Item',
                        style: const TextStyle(
                          fontSize: 17,
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tell us why you\'re cancelling "${widget.productName}"',
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(child: _buildBody(scrollController)),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      disabledBackgroundColor: AppColors.line,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Submit & Cancel Item', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
              const SizedBox(height: 12),
              TextButton(onPressed: () { setState(() => _error = null); _load(); }, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final reasons = _reasons;
    if (reasons == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
    }

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      children: [
        ...reasons.map((reason) => _buildReasonTile(reason)),
        if (_isOther)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _customController,
              autofocus: true,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Type your reason…',
                filled: true,
                fillColor: AppColors.canvas,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.terracotta, width: 1.2),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReasonTile(String reason) {
    final selected = _selected == reason;
    return InkWell(
      onTap: () => setState(() => _selected = reason),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.terracottaSoft.withOpacity(0.4) : AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.terracotta : AppColors.line),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? AppColors.terracotta : AppColors.inkSoft,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ink,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}