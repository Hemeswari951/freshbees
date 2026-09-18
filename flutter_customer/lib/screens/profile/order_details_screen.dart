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

/// Order Details screen — shown when a customer taps "VIEW FULL ORDER" on
/// the Orders list. Mirrors Myntra/Flipkart's order page: hero delivery
/// banner per item, image/name/shop/size/price, a "Track item" entry that
/// opens the dedicated tracking screen, Cancel while still eligible, and
/// a Price Details + address summary below.
class OrderDetailsScreen extends StatefulWidget {
  final int orderId;

  /// Optional — the specific order item this screen was opened for, set
  /// when the user arrives from a notification. That item's card gets a
  /// ring around it so they can see straight away which product the
  /// update was about.
  final int? highlightOrderItemId;

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.highlightOrderItemId,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _loading = true;
  String? _error;
  OrderModel? _order;
  int? _cancelling;

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
      final order = await OrderService.getOrderById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // Opens the "why are you cancelling" sheet (reasons loaded from the
  // backend, so the list can change without an app update). Returns null
  // if the customer backed out without picking anything.
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
      await _load();
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
    // Mobile-only back button: on desktop the browser's own back
    // button is already visible in the toolbar, so we skip our own.
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: !isDesktop,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                onPressed: () => context.pop(),
              ),
        title: const Text(
          'Order Details',
          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terracotta));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('RETRY'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.terracotta,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildOrderHeader(order),
              const SizedBox(height: 18),
              const _SectionLabel('Items in this order'),
              const SizedBox(height: 10),
              ...order.items.map((item) {
                final highlighted = widget.highlightOrderItemId != null &&
                    widget.highlightOrderItemId == item.orderItemId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: highlighted ? const EdgeInsets.all(2) : EdgeInsets.zero,
                    decoration: highlighted
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppColors.terracotta,
                              width: 1.6,
                            ),
                          )
                        : null,
                    child: _ItemHeroCard(
                      item: item,
                      order: order,
                      cancelling: _cancelling == item.orderItemId,
                      onCancel: () => _cancelItem(item),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 4),
              _CollapsibleCard(
                title: 'Price Details',
                initiallyExpanded: true,
                child: _buildPriceDetailsContent(order),
              ),
              if (order.deliveryName != null) ...[
                const SizedBox(height: 14),
                _CollapsibleCard(
                  title: 'Delivery Address',
                  child: _buildAddressContent(order),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(OrderModel order) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Placed on ${_formatDate(order.createdAt)}',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${order.activeTotal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textDark),
              ),
              const SizedBox(height: 2),
              const Text('Total paid', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // PRICE DETAILS — one row per product (so a multi-item order shows what
  // each thing actually cost), then Item Total -> Total Amount below a
  // divider, then payment method/status. Rendered inside a
  // _CollapsibleCard, so this just returns the inner content — no card
  // chrome or title here, the collapsible header already shows the title.
  //
  // A cancelled item is still listed (struck through, greyed out) so the
  // breakdown still adds up visually, but it's EXCLUDED from Item Total /
  // Total Amount — order.activeTotal already does that math, it just
  // ignores anything with itemStatus == 'Cancelled'.
  // ---------------------------------------------------------------------
  Widget _buildPriceDetailsContent(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in order.items) ...[
          _priceItemRow(item),
          const SizedBox(height: 10),
        ],
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 8),
        _priceRow('Item Total', '₹${order.activeTotal.toStringAsFixed(0)}'),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 8),
        _priceRow(
          'Total Amount',
          '₹${order.activeTotal.toStringAsFixed(0)}',
          bold: true,
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 14),
        _kv('Payment Method', order.paymentMethod == 'COD' ? 'Cash on Delivery' : (order.paymentMethod ?? '—')),
        if (order.paymentStatus != null) ...[
          const SizedBox(height: 12),
          _kv('Payment Status', order.paymentStatus!),
        ],
      ],
    );
  }

  // Single product line inside Price Details: name (+ qty if more than 1)
  // on the left, its line total (price * qty) on the right. Cancelled
  // items get struck through and greyed out, and a small "Cancelled" tag
  // so it's obvious at a glance why it isn't counted in the total below.
  Widget _priceItemRow(OrderItemModel item) {
    final isCancelled = item.itemStatus.toLowerCase() == 'cancelled';
    final lineTotal = item.price * item.quantity;
    final name = item.productName ?? 'Product';
    final label = item.quantity > 1 ? '$name  × ${item.quantity}' : name;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: isCancelled ? AppColors.textLight : AppColors.inkSoft,
                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.textLight,
                ),
              ),
              if (isCancelled) ...[
                const SizedBox(height: 2),
                const Text(
                  'Cancelled — not included in total',
                  style: TextStyle(fontSize: 11, color: AppColors.red),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '₹${lineTotal.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isCancelled ? AppColors.textLight : AppColors.textDark,
            decoration: isCancelled ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 13.5 : 13,
            color: bold ? AppColors.textDark : AppColors.inkSoft,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 15 : 13.5,
            color: AppColors.textDark,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAddressContent(OrderModel order) {
    final lines = [
      order.deliveryName,
      order.addressLine1,
      order.addressLine2,
      [order.deliveryCity, order.deliveryState, order.deliveryPincode]
          .where((e) => e != null && e.isNotEmpty)
          .join(', '),
    ].where((e) => e != null && e.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final l in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(l!, style: const TextStyle(color: AppColors.ink, fontSize: 13.5)),
          ),
        if (order.deliveryPhone != null) ...[
          const SizedBox(height: 4),
          Text('Phone: ${order.deliveryPhone}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _kv(String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(k, style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5))),
        Expanded(child: Text(v, style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700, fontSize: 13.5))),
      ],
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ============================================================================
// SMALL SHARED PIECES
// ============================================================================

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark));
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

// ============================================================================
// COLLAPSIBLE CARD — same bordered white card look as everything else on
// this screen, but the body only shows once the header row is tapped.
// Used for "Price Details" and "Delivery Address" (Flipkart-style).
// ============================================================================

class _CollapsibleCard extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleCard({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  State<_CollapsibleCard> createState() => _CollapsibleCardState();
}

class _CollapsibleCardState extends State<_CollapsibleCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity, height: 0),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ITEM HERO CARD — image/name/shop/size/price + status chip + actions
// ============================================================================

class _ItemHeroCard extends StatelessWidget {
  final OrderItemModel item;
  final OrderModel order;
  final bool cancelling;
  final VoidCallback onCancel;

  const _ItemHeroCard({
    required this.item,
    required this.order,
    required this.cancelling,
    required this.onCancel,
  });

  bool get _isCancellable => item.itemStatus.toLowerCase() == 'pending';
  bool get _isCancelled => item.itemStatus.toLowerCase() == 'cancelled';
  bool get _isDelivered => item.itemStatus.toLowerCase() == 'delivered';

  static String _formatDeliveredDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Same direct-popup flow as the orders list card — see orders_screen.dart.
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
      eligibility = null;
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

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 78,
                height: 92,
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
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.textDark),
                    ),
                    if (item.shopName != null) ...[
                      const SizedBox(height: 4),
                      Text(item.shopName!, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
                    ],
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 10,
                      children: [
                        if (item.colorName != null)
                          Text(item.colorName!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                        if (item.size != null)
                          Text('Size: ${item.size}', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Qty: ${item.quantity}', style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5, color: AppColors.textDark)),
            ],
          ),

          const SizedBox(height: 14),

          OrderStatusRow(status: item.itemStatus),

          if (_isDelivered && item.itemUpdatedAt != null) ...[
            const SizedBox(height: 2),
            Text(
              'Delivered on ${_formatDeliveredDate(item.itemUpdatedAt!)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],

          if (_isCancelled && (item.cancellationReason ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${item.cancellationReason}',
              style: const TextStyle(color: AppColors.textGrey, fontSize: 12.5),
            ),
          ],

          if (!_isCancelled) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 22,
              runSpacing: 6,
              children: [
                _isDelivered
                    ? OrderLinkAction(
                        icon: Icons.star_rounded,
                        iconColor: AppColors.gold,
                        label: 'Rate & Review',
                        color: AppColors.blue,
                        onTap: () => _openReviewSheet(context),
                      )
                    : OrderLinkAction(
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
            ),
          ],
        ],
      ),
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