
import 'package:flutter/material.dart';
import '../../services/address_service.dart';
import '../../services/cart_service.dart';
import '../order/order_success_screen.dart';


/// payment mode.
class PaymentScreen extends StatefulWidget {
  final AddressModel address;
  final double subtotal;
  final int itemCount;
  final List<int> cartItemIds;
  

  const PaymentScreen({
    super.key,
    required this.address,
    required this.subtotal,
    required this.itemCount,
    required this.cartItemIds,
  });

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

  _PaymentMethod _selected = _PaymentMethod.cod;
  bool _placingOrder = false;

  Future<void> _placeOrder() async {
    setState(() => _placingOrder = true);
    try {
      final result = await CartService.checkout(
        addressId: widget.address.addressId,
         paymentMethod: _selected.apiValue,
         cartItemIds: widget.cartItemIds,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
           orderId: result.orderId,
            subtotal: widget.subtotal,
            paymentMethod: _selected.label,
          ),
        ),
        (route) => route.isFirst, // back to Home, dropping Cart/Address/Payment
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
    final isDesktop = MediaQuery.of(context).size.width >= 900;

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
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 700 : double.infinity),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _addressCard(),
                const SizedBox(height: 16),
                _orderSummaryCard(),
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
                const SizedBox(height: 8),
                const Text(
                  'Demo checkout — no real payment is processed.',
                  style: TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
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
                          : 'PLACE ORDER  •  ₹${widget.subtotal.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
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

  Widget _orderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Order Total (${widget.itemCount} item${widget.itemCount == 1 ? '' : 's'})'),
          Text(
            '₹${widget.subtotal.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
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