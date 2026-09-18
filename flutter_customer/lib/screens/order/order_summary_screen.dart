import 'package:flutter/material.dart';
import '../../services/address_service.dart';
import '../../services/cart_service.dart';
import '../../services/api_service.dart';
import '../../models/buy_now_product.dart';
import '../../widgets/checkout_stepper.dart';
import '../../utils/checkout_constants.dart';
import '../payment/payment_screen.dart';
import '../address/address_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  final AddressModel address;
  final BuyNowProduct? buyNowProduct;
  final List<int>? cartItemIds;

  const OrderSummaryScreen({
    super.key,
    required this.address,
    this.buyNowProduct,
    this.cartItemIds,
  }) : assert(
          buyNowProduct != null || cartItemIds != null,
          'OrderSummaryScreen needs either a buyNowProduct or cartItemIds',
        );
 
  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> {
  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _accentLight = Color(0xFFB08D63);
  static const Color _cardBorder = Color(0xFFEAEAEA);
  static const Color _imgBg = Color(0xFFF2ECE4);
  static const Color _green = Color(0xFF388E3C);

  static const double _desktopBreakpoint = 900;
  static const double _maxContentWidth = 1000;

  bool get _isBuyNow => widget.buyNowProduct != null;

  bool _loading = true;
  String? _error;

  List<CartItemModel> _cartItems = [];
  final Set<int> _busyCartRows = {};

  bool _proceeding = false;
 late AddressModel _address;   // ← ADD THIS
  @override
  void initState() {
    super.initState();
     _address = widget.address;   // ← ADD THIS
    if (_isBuyNow) {
      _loading = false;
    } else {
      _loadCartItems();
    }
  }

  Future<void> _loadCartItems({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await CartService.getCart();
      if (!mounted) return;
      setState(() {
        _cartItems = result.items
            .where((i) => widget.cartItemIds!.contains(i.cartItemId))
            .toList();
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

  Future<void> _changeBuyNowQty(int delta) async {
    final p = widget.buyNowProduct!;
    final newQty = p.quantity + delta;
    if (newQty < 1) return;
    if (p.stockQuantity != null && newQty > p.stockQuantity!) return;
    setState(() => p.quantity = newQty);
  }

  Future<void> _changeCartQty(CartItemModel item, int newQty) async {
    if (newQty < 1) return;
    setState(() => _busyCartRows.add(item.cartItemId));
    try {
      await CartService.updateQuantity(cartItemId: item.cartItemId, quantity: newQty);
      await _loadCartItems(silent: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyCartRows.remove(item.cartItemId));
    }
  }

  double get _mrpTotal {
    if (_isBuyNow) return widget.buyNowProduct!.mrpLineTotal;
    return _cartItems.fold(0, (sum, i) => sum + (i.mrp ?? i.price) * i.quantity);
  }

  double get _priceTotal {
    if (_isBuyNow) return widget.buyNowProduct!.lineTotal;
    return _cartItems.fold(0, (sum, i) => sum + i.lineTotal);
  }

  double get _discount {
    final d = _mrpTotal - _priceTotal;
    return d > 0 ? d : 0.0;
  }

  double get _grandTotal => _priceTotal + kPlatformFee;

  int get _itemCount => _isBuyNow ? widget.buyNowProduct!.quantity : _cartItems.length;

  void _continueToPayment() {
    if (!_isBuyNow && _cartItems.isEmpty) return;

    setState(() => _proceeding = true);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          address: _address,   // ← changed from widget.address
          buyNowProduct: widget.buyNowProduct,
          cartItemIds: widget.cartItemIds,
          cartItems: _isBuyNow ? null : _cartItems,
          subtotal: _priceTotal,
          itemCount: _itemCount,
          platformFee: kPlatformFee,
          mrpTotal: _mrpTotal,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => _proceeding = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Order Summary',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CheckoutStepper(currentStep: 1),
            Expanded(child: _buildBody(isDesktop)),
          ],
        ),
      ),
      // Only need the slim bottom bar on mobile — desktop's CTA lives
      // inside the sticky summary card next to the item list.
      bottomNavigationBar: (!isDesktop) ? _buildCheckoutBar() : null,
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.black26),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadCartItems,
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final itemsColumn = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _addressCard(isDesktop),
        const SizedBox(height: 16),
        if (_isBuyNow)
          _buyNowItemCard(isDesktop)
        else
          ..._cartItems.map((i) => _cartItemCard(i, isDesktop)),
        if (!isDesktop) ...[
          const SizedBox(height: 16),
          _priceDetailsCard(),
          const SizedBox(height: 24),
        ],
      ],
    );

    if (!isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: itemsColumn,
        ),
      );
    }

    // Desktop: items on the left, sticky price + CTA card on the right —
    // matches the Cart screen's split layout instead of a mobile list
    // stretched across a wide window.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: SizedBox(height: 640, child: itemsColumn)),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _desktopSummaryCard()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _desktopSummaryCard() {
    final savings = _discount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PRICE DETAILS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.black45)),
          const SizedBox(height: 14),
          _priceRow('MRP (incl. of all taxes)', '₹${_mrpTotal.toStringAsFixed(0)}'),
          if (savings > 0)
            _priceRow('Discount on MRP', '- ₹${savings.toStringAsFixed(0)}', valueColor: _green),
          _priceRow('Platform Fee', '₹${kPlatformFee.toStringAsFixed(0)}'),
          const Divider(height: 24),
          _priceRow('Total Amount', '₹${_grandTotal.toStringAsFixed(0)}', bold: true),
          if (savings > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(
                  "You'll save ₹${savings.toStringAsFixed(0)} on this order!",
                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: (_loading || _proceeding)
                    ? null
                    : const LinearGradient(colors: [_accent, _accentLight]),
                color: (_loading || _proceeding) ? Colors.black12 : null,
              ),
              child: ElevatedButton(
                onPressed: (_loading || _proceeding) ? null : _continueToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'CONTINUE TO PAYMENT',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressCard(bool isDesktop) {
    final a = _address;   // ← was widget.address
    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: _accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Deliver to: ${a.fullName}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _imgBg, borderRadius: BorderRadius.circular(4)),
                      child: Text(a.addressType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(a.oneLine, style: const TextStyle(color: Colors.black54, fontSize: 12.5, height: 1.4)),
                const SizedBox(height: 4),
                Text('Phone: ${a.phone}', style: const TextStyle(color: Colors.black54, fontSize: 12.5)),
              ],
            ),
          ),
          TextButton(
        onPressed: () async {
          final result = await Navigator.of(context).push<AddressModel>(
            MaterialPageRoute(
              builder: (_) => const AddressScreen(selectOnly: true),
            ),
          );
          if (result != null && mounted) {
            setState(() => _address = result);
          }
        },
        child: const Text('CHANGE', style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
      ),
        ],
      ),
    );
  }

  Widget _buyNowItemCard(bool isDesktop) {
    final p = widget.buyNowProduct!;
    final hasDiscount = p.mrp != null && p.mrp! > p.price;
    final discountPct = hasDiscount ? (((p.mrp! - p.price) / p.mrp!) * 100).round() : 0;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(p.thumbnail, size: isDesktop ? 100 : 72, discountPct: hasDiscount ? discountPct : null),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: isDesktop ? 15.5 : 14)),
                if (p.size != null) ...[
                  const SizedBox(height: 4),
                  Text('Size: ${p.size}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
                const SizedBox(height: 6),
                if (p.rating != null && p.rating! > 0) ...[
                  _ratingBadge(p.rating!, p.reviewCount ?? 0),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Text('₹${p.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text('₹${p.mrp!.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, color: Colors.black38, decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _qtyButton(icon: Icons.remove, onTap: () => _changeBuyNowQty(-1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('Qty: ${p.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    _qtyButton(icon: Icons.add, onTap: () => _changeBuyNowQty(1)),
                  ],
                ),
              ],
            ),
          ),
          Text('₹${p.lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _cartItemCard(CartItemModel item, bool isDesktop) {
    final busy = _busyCartRows.contains(item.cartItemId);
    final hasDiscount = item.mrp != null && item.mrp! > item.price;
    final discountPct = hasDiscount ? (((item.mrp! - item.price) / item.mrp!) * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isDesktop ? 18 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(
            item.thumbnail.isNotEmpty ? '${ApiService.serverUrl}${item.thumbnail}' : null,
            size: isDesktop ? 100 : 72,
            discountPct: hasDiscount ? discountPct : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.shopName != null && item.shopName!.isNotEmpty) ...[
                  Text(item.shopName!, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _accent)),
                  const SizedBox(height: 2),
                ],
                Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: isDesktop ? 15.5 : 14)),
                if (item.size != null || item.color != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (item.size != null) 'Size: ${item.size}',
                      if (item.color != null) 'Color: ${item.color}',
                    ].join('  |  '),
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 6),
                if (item.rating != null && item.rating! > 0) ...[
                  _ratingBadge(item.rating!, item.reviewCount ?? 0),
                  const SizedBox(height: 6),
                ],
                Row(
                  children: [
                    Text('₹${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Text('₹${item.mrp!.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, color: Colors.black38, decoration: TextDecoration.lineThrough)),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                busy
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : Row(
                        children: [
                          _qtyButton(icon: Icons.remove, onTap: () => _changeCartQty(item, item.quantity - 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('Qty: ${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          _qtyButton(icon: Icons.add, onTap: () => _changeCartQty(item, item.quantity + 1)),
                        ],
                      ),
              ],
            ),
          ),
          Text('₹${item.lineTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Thiraa rating pill: green badge + count + "Thiraa Assured" mark ──
  Widget _ratingBadge(double rating, int reviewCount) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
          decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(4)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
              const SizedBox(width: 2),
              const Icon(Icons.star, color: Colors.white, size: 11),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text('($reviewCount)', style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified, size: 13, color: _accent),
            SizedBox(width: 2),
            Text('Thiraa Assured',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _accent, fontStyle: FontStyle.italic)),
          ],
        ),
      ],
    );
  }

  Widget _thumb(String? url, {double size = 72, int? discountPct}) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: size,
            height: size,
            child: Container(
              color: _imgBg,
              child: url != null
                  ? Image.network(url, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.black38))
                  : const Icon(Icons.image, color: Colors.black38),
            ),
          ),
        ),
        if (discountPct != null && discountPct > 0)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_accent, _accentLight]),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('$discountPct% OFF',
                  style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: _imgBg, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 14, color: Colors.black87),
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, color: Colors.black87)),
          Text(value, style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  // Only used on mobile now — desktop shows _priceDetailsCard via
  // _desktopSummaryCard instead, inline with the CTA.
  Widget _priceDetailsCard() {
    final savings = _discount;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text('PRICE DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: Colors.black45)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _priceRow('MRP (incl. of all taxes)', '₹${_mrpTotal.toStringAsFixed(0)}'),
                if (savings > 0)
                  _priceRow('Discount on MRP', '- ₹${savings.toStringAsFixed(0)}', valueColor: _green),
                _priceRow('Platform Fee', '₹${kPlatformFee.toStringAsFixed(0)}'),
                const Divider(height: 20),
                _priceRow('Total Amount', '₹${_grandTotal.toStringAsFixed(0)}', bold: true),
              ],
            ),
          ),
          if (savings > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
              child: Center(
                child: Text(
                  "You'll save ₹${savings.toStringAsFixed(0)} on this order!",
                  style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -4), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${_priceTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12, color: Colors.black38, decoration: TextDecoration.lineThrough),
                  ),
                  Text(
                    '₹${_grandTotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 170,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: (_loading || _proceeding)
                      ? null
                      : const LinearGradient(colors: [_accent, _accentLight]),
                  color: (_loading || _proceeding) ? Colors.black12 : null,
                ),
                child: ElevatedButton(
                  onPressed: (_loading || _proceeding) ? null : _continueToPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}