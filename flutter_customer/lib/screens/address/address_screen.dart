
import 'package:flutter/material.dart';
import '../../services/address_service.dart';
import 'add_address_screen.dart';
import '../payment/payment_screen.dart';

/// Step 2 of checkout: select (or add) a delivery address, then continue
/// to the Payment screen. Reached from CartScreen's "Buy Now".
class AddressScreen extends StatefulWidget {
  final double subtotal;
  final int itemCount;
  final List<int> cartItemIds;

  const AddressScreen({
    super.key,
    required this.subtotal,
    required this.itemCount,
    required this.cartItemIds,
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _cardBorder = Color(0xFFEAEAEA);

  bool _loading = true;
  String? _error;
  List<AddressModel> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final addresses = await AddressService.getAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
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

  Future<void> _addNewAddress() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddAddressScreen()),
    );
    if (added == true) {
      _loadAddresses();
    }
  }

  void _deliverHere(AddressModel address) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          address: address,
          subtotal: widget.subtotal,
          itemCount: widget.itemCount,
          cartItemIds: widget.cartItemIds,
        ),
      ),
    );
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
          'Select Delivery Address',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 700 : double.infinity),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
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
                onPressed: _loadAddresses,
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _addNewAddressButton(),
        const SizedBox(height: 16),
        if (_addresses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: const [
                Icon(Icons.location_off_outlined, size: 48, color: Colors.black26),
                SizedBox(height: 12),
                Text(
                  'No saved addresses yet',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Add an address to continue to payment.',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ..._addresses.map(_buildAddressCard),
      ],
    );
  }

  Widget _addNewAddressButton() {
    return InkWell(
      onTap: _addNewAddress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent, width: 1.2, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline, color: _accent),
            const SizedBox(width: 10),
            const Text(
              'ADD NEW ADDRESS',
              style: TextStyle(
                color: _accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  address.fullName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2ECE4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _accent),
                  ),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2ECE4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  address.addressType,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            address.oneLine,
            style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 4),
          Text(
            'Phone: ${address.phone}',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _deliverHere(address),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _accent,
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'DELIVER HERE',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}