
import 'package:flutter/material.dart';
import '../../services/address_service.dart';
import '../../services/cart_service.dart';
import '../../services/order_service.dart';
import '../../models/buy_now_product.dart';
import '../../widgets/checkout_stepper.dart';
import '../../utils/checkout_constants.dart';
import '../order/order_success_screen.dart';

/// Step 3 of checkout: pick a payment mode and place the order.
///
/// Reached from OrderSummaryScreen with either a [buyNowProduct] (single
/// item, no cart — hits POST /orders/buy-now) or [cartItemIds] (hits the
/// existing POST /orders/checkout). Exactly one of the two is set.
class PaymentScreen extends StatefulWidget {
  final AddressModel address;
  final double subtotal;
  final int itemCount;
  final List<int>? cartItemIds;
  final List<CartItemModel>? cartItems;
  final BuyNowProduct? buyNowProduct;
  final double platformFee;
  final double? mrpTotal;

  const PaymentScreen({
    super.key,
    required this.address,
    required this.subtotal,
    required this.itemCount,
    this.cartItemIds,
    this.cartItems,
    this.buyNowProduct,
    this.platformFee = kPlatformFee,
    this.mrpTotal,
  }) : assert(
          buyNowProduct != null || cartItemIds != null,
          'PaymentScreen needs either a buyNowProduct or cartItemIds',
        );

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

enum _PaymentMethod { cod, upi, card, netbanking }

extension on _PaymentMethod {
  String get label {
    switch (this) {
      case _PaymentMethod.cod:
        return 'Cash on Delivery';
      case _PaymentMethod.upi:
        return 'UPI';
      case _PaymentMethod.card:
        return 'Credit / Debit Card';
      case _PaymentMethod.netbanking:
        return 'Net Banking';
    }
  }

  String get apiValue {
    switch (this) {
      case _PaymentMethod.cod:
        return 'COD';
      case _PaymentMethod.upi:
        return 'UPI';
      case _PaymentMethod.card:
        return 'CARD';
      case _PaymentMethod.netbanking:
        return 'NETBANKING';
    }
  }

  IconData get icon {
    switch (this) {
      case _PaymentMethod.cod:
        return Icons.payments_outlined;
      case _PaymentMethod.upi:
        return Icons.qr_code_2;
      case _PaymentMethod.card:
        return Icons.credit_card;
      case _PaymentMethod.netbanking:
        return Icons.account_balance_outlined;
    }
  }
}

class _PaymentScreenState extends State<PaymentScreen> {
  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _cardBorder = Color(0xFFEAEAEA);
  static const Color _imgBg = Color(0xFFF2ECE4);
  static const double _desktopBreakpoint = 900;
  static const double _maxContentWidth = 1000;

  _PaymentMethod _selected = _PaymentMethod.cod;
  bool _placingOrder = false;

  double get _codFee => _selected == _PaymentMethod.cod ? kCodHandlingFee : 0;
  double get _grandTotal => widget.subtotal + widget.platformFee + _codFee;

  Future<void> _placeOrder() async {
    setState(() => _placingOrder = true);
    try {
      final int orderId;

      if (widget.buyNowProduct != null) {
        final p = widget.buyNowProduct!;
        final result = await OrderService.buyNow(
          productId: p.productId,
          variantId: p.variantId,
          quantity: p.quantity,
          addressId: widget.address.addressId,
          paymentMethod: _selected.apiValue,
        );
        orderId = result.orderId;
      } else {
        final result = await CartService.checkout(
          addressId: widget.address.addressId,
          paymentMethod: _selected.apiValue,
          cartItemIds: widget.cartItemIds,
        );
        orderId = result.orderId;
      }

      if (!mounted) return;

      final successItems = widget.buyNowProduct != null
          ? [
              OrderSuccessItem(
                productName: widget.buyNowProduct!.productName,
                size: widget.buyNowProduct!.size,
              ),
            ]
          : (widget.cartItems ?? [])
              .map((i) => OrderSuccessItem(
                    shopName: i.shopName,
                    productName: i.productName,
                    size: i.size,
                    color: i.color,
                  ))
              .toList();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
           orderId: orderId,
            subtotal: _grandTotal,
            paymentMethod: _selected.label,
            items: successItems,
          ),
        ),
        (route) => route.isFirst, // back to Home, dropping Cart/Address/Order Summary/Payment
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
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
          'Payment',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const CheckoutStepper(currentStep: 2),
            Expanded(child: _buildBody(isDesktop)),
          ],
        ),
      ),
      // Desktop shows the price card + Place Order button inline (sticky,
      // next to the payment options) — mobile gets a fixed bottom bar
      // instead, same pattern as Cart / Order Summary.
      bottomNavigationBar: (!isDesktop) ? _buildCheckoutBar() : null,
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (!isDesktop) {
      // Mobile: single scrollable column, price card inline, Place Order
      // lives in the bottom bar.
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._formFields(),
              const SizedBox(height: 16),
              _priceDetailsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    }

    // Desktop: address + payment method on the left, a sticky price +
    // Place Order card on the right — matches Cart / Order Summary.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 640,
                  child: ListView(
                    padding: const EdgeInsets.only(right: 4),
                    children: _formFields(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _desktopSummaryCard()),
            ],
          ),
        ),
      ),
    );
  }

  // Address card + payment method picker + notes — shared by both layouts.
  List<Widget> _formFields() {
    return [
      _addressCard(),
      const SizedBox(height: 16),
      const Text(
        'SELECT PAYMENT METHOD',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: Colors.black45,
        ),
      ),
      const SizedBox(height: 10),
      ..._PaymentMethod.values.map(_paymentOption),
      if (_selected == _PaymentMethod.cod) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _imgBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Due to handling costs, a nominal fee of ₹${kCodHandlingFee.toStringAsFixed(0)} will be charged for orders placed using Cash on Delivery. Avoid this fee by paying online.',
            style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
          ),
        ),
      ],
      const SizedBox(height: 8),
      const Text(
        'Demo checkout — no real payment is processed.',
        style: TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
      ),
    ];
  }

  // Desktop-only: sticky price card + Place Order button, next to the form.
  Widget _desktopSummaryCard() {
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
          _priceDetailsCardContent(),
          const SizedBox(height: 20),
          _placeOrderButton(height: 50),
        ],
      ),
    );
  }

  // Slim bottom bar for mobile — total + Place Order, same pattern as
  // Cart / Order Summary's bottom checkout bar.
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
                  const Text('Total', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('₹${_grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            SizedBox(width: 190, height: 48, child: _placeOrderButton()),
          ],
        ),
      ),
    );
  }

  Widget _placeOrderButton({double height = 48}) {
    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: _placingOrder ? null : _placeOrder,
        icon: _placingOrder
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : const Icon(Icons.lock_outline, color: Colors.white, size: 18),
        label: Text(
          _placingOrder
              ? 'PLACING ORDER...'
              : _selected == _PaymentMethod.cod
                  ? 'PLACE ORDER  •  ₹${_grandTotal.toStringAsFixed(0)}'
                  : 'PAY  •  ₹${_grandTotal.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _addressCard() {
    final a = widget.address;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
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
                    Text(
                      'Deliver to: ${a.fullName}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _imgBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        a.addressType,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  a.oneLine,
                  style: const TextStyle(color: Colors.black54, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CHANGE', style: TextStyle(color: _accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
          Text(value, style: TextStyle(fontSize: 13.5, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }

  Widget _priceDetailsCardContent() {
    final mrpTotal = widget.mrpTotal ?? widget.subtotal;
    final discount = (mrpTotal - widget.subtotal).clamp(0, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Order Total (${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Colors.black45)),
        const SizedBox(height: 6),
        _priceRow('MRP (incl. of all taxes)', '₹${mrpTotal.toStringAsFixed(0)}'),
        if (discount > 0)
          _priceRow('Discount on MRP', '- ₹${discount.toStringAsFixed(0)}', valueColor: const Color(0xFF388E3C)),
        _priceRow('Platform Fee', '₹${widget.platformFee.toStringAsFixed(0)}'),
        if (_codFee > 0) _priceRow('Payment Handling Fee', '₹${_codFee.toStringAsFixed(0)}'),
        const Divider(height: 20),
        _priceRow('Total Amount', '₹${_grandTotal.toStringAsFixed(0)}', bold: true),
      ],
    );
  }

  Widget _priceDetailsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _priceDetailsCardContent(),
      ),
    );
  }

  Widget _paymentOption(_PaymentMethod method) {
    final selected = _selected == method;
    return InkWell(
      onTap: () => setState(() => _selected = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _accent : _cardBorder, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(method.icon, color: selected ? _accent : Colors.black54),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? _accent : Colors.black26,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}