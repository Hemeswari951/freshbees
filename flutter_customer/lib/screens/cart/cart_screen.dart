import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/cart_service.dart';
import '../address/address_screen.dart';
import '../../services/wishlist_service.dart';

/// Bag / Cart screen.
/// e-commerce cart page.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = true;
  String? _error;
  bool _placingOrder = false;
  List<CartItemModel> _items = [];
  double _subtotal = 0;
// Track which items are currently checked/selected
  final Set<int> _selectedCartItemIds = {};
 
  // cartItemId → true while that row's quantity/remove request is in flight,
  // so only that row shows a spinner instead of blocking the whole screen.
  final Set<int> _busyRows = {};
  
  static const double _desktopBreakpoint = 900;

  static const double _maxContentWidth = 1000;
  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _cardBorder = Color(0xFFEAEAEA);
  static const Color _imgBg = Color(0xFFF2ECE4);

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

Future<void> _loadCart() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await CartService.getCart();
      if (!mounted) return;
      setState(() {
        _items = result.items;
       
        _selectedCartItemIds.retainWhere(
          (id) => _items.any((item) => item.cartItemId == id)
        );
       
        _recalculateSubtotal();
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
 
  void _recalculateSubtotal() {
    _subtotal = _items
        .where((i) => _selectedCartItemIds.contains(i.cartItemId))
        .fold(0, (sum, i) => sum + i.lineTotal);
  }
 void _toggleSelectAll() {
    setState(() {
      if (_selectedCartItemIds.length == _items.length) {
        _selectedCartItemIds.clear();
      } else {
        _selectedCartItemIds.clear();
        _selectedCartItemIds.addAll(_items.map((i) => i.cartItemId));
      }
      _recalculateSubtotal();
    });
  }
 
  void _toggleItemSelection(int cartItemId) {
    setState(() {
      if (_selectedCartItemIds.contains(cartItemId)) {
        _selectedCartItemIds.remove(cartItemId);
      } else {
        _selectedCartItemIds.add(cartItemId);
      }
      _recalculateSubtotal();
    });
  }
 
  Future<void> _changeQuantity(CartItemModel item, int newQty) async {
    if (newQty < 1) {
      _removeItem(item);
      return;
    }
    setState(() => _busyRows.add(item.cartItemId));
    try {
      await CartService.updateQuantity(cartItemId: item.cartItemId, quantity: newQty);
      await _loadCart();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyRows.remove(item.cartItemId));
    }
  }

  Future<void> _removeItem(CartItemModel item) async {
    setState(() => _busyRows.add(item.cartItemId));
    try {
      await CartService.removeItem(item.cartItemId);
      if (!mounted) return;
      setState(() {
        _items.removeWhere((i) => i.cartItemId == item.cartItemId);
        _selectedCartItemIds.remove(item.cartItemId);
        _recalculateSubtotal();
        _busyRows.remove(item.cartItemId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busyRows.remove(item.cartItemId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  // "Buy Now" no longer checks out directly — it now hands off to the
  // Address screen (Cart -> Address -> Payment -> Order Success), matching
  // a normal e-commerce flow. The actual CartService.checkout() call now
  // happens on the Payment screen, once an address and payment method are
  // chosen. When that flow finishes and pops back here, we just reload the
  // cart so it reflects whatever the server actually ordered/cleared.
  Future<void> _handleBuyNow() async {
    final selectedCount = _selectedCartItemIds.length;
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item to proceed')),
      );
      return;
    }
 
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddressScreen(
          subtotal: _subtotal,
          itemCount: selectedCount,
        ),
      ),
    );
 
    if (mounted) _loadCart();
  }
  Future<void> _confirmRemoveItem(CartItemModel item) async {
    // Change the return type from bool to String to handle multiple button actions
    final action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Move from Bag', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          content: const Text('Are you sure you want to move this item from your bag?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('wishlist'), // Returns 'wishlist'
              child: const Text('MOVE TO WISHLIST', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('remove'), // Returns 'remove'
              child: const Text('REMOVE', style: TextStyle(color: Color(0xFFFF3E6C), fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
 
    // Handle standard removal
    if (action == 'remove') {
      _removeItem(item);
    }
    // Handle move to wishlist
    else if (action == 'wishlist') {
      // 1. Remove it from the cart
      _removeItem(item);
     
      // 2. Add it to the wishlist
      try {
        // NOTE: Make sure `addToWishlist` (or equivalent method name) exists in your WishlistService
        await WishlistService.addToWishlist(item.productId);
       
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item moved to wishlist')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
          );
        }
      }
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
        title: Text(
          'My Bag${_items.isNotEmpty ? ' (${_items.length})' : ''}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(child: _buildBody(isDesktop)),
      // On desktop the summary + Buy Now live inline with the list, so we
      // only need the slim bottom bar on narrower / mobile screens.
      bottomNavigationBar: (!isDesktop && _items.isNotEmpty) ? _buildCheckoutBar() : null,
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
                onPressed: _loadCart,
                style: ElevatedButton.styleFrom(backgroundColor: _accent),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.black26),
              const SizedBox(height: 16),
              const Text(
                'Your bag is empty',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Items you add to your bag will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final list = RefreshIndicator(
      onRefresh: _loadCart,
       child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + 1, // +1 for the select-all header
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSelectionHeader();
          }
          return _buildCartTile(_items[index - 1]);
        },
      ),
    );
 
    if (!isDesktop) {
      return list;
    }
 

    // Desktop: centered, max-width, list on the left + a sticky order
    // summary card on the right — the familiar cart-page layout instead of
    // a full-width mobile list stretched across a wide browser window.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: SizedBox(height: 600, child: list)),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildSummaryCard()),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildSelectionHeader() {
    final allSelected = _items.isNotEmpty && _selectedCartItemIds.length == _items.length;
 
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            activeColor: _accent,
            onChanged: (_) => _toggleSelectAll(),
          ),
          Text(
            '${_selectedCartItemIds.length}/${_items.length} ITEMS SELECTED',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
 

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items (${_items.length})', style: const TextStyle(color: Colors.black54)),
              Text('₹${_subtotal.toStringAsFixed(0)}'),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              Text(
                '₹${_subtotal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _placingOrder ? null : _handleBuyNow,
              icon: _placingOrder
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.flash_on, color: Colors.white, size: 20),
              label: Text(
                _placingOrder ? 'PLACING...' : 'PROCEED',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTile(CartItemModel item) {
    final busy = _busyRows.contains(item.cartItemId);
    final isSelected = _selectedCartItemIds.contains(item.cartItemId);
    final imageUrl = item.thumbnail.isNotEmpty
        ? '${ApiService.serverUrl}${item.thumbnail}'
        : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Checkbox(
              value: isSelected,
              activeColor: _accent,
              onChanged: (_) => _toggleItemSelection(item.cartItemId),
            ),
          ),
          // Fixed-size box regardless of image load state, so a slow or
          // failed image never collapses the row to zero height.
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 80,
              height: 80,
              child: Container(
                color: _imgBg,
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.image, color: Colors.black38),
                      )
                    : const Icon(Icons.image, color: Colors.black38),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                if (item.size != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Size: ${item.size}',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  '₹${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                busy
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        children: [
                          _qtyButton(
                            icon: Icons.remove,
                            onTap: () => _changeQuantity(item, item.quantity - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          _qtyButton(
                            icon: Icons.add,
                            onTap: () => _changeQuantity(item, item.quantity + 1),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                // CHANGED: Icons.delete_outline is now Icons.close
                icon: const Icon(Icons.close, color: Colors.black45, size: 20),
                onPressed: busy ? null : () => _confirmRemoveItem(item),
              ),
              Text(
                '₹${item.lineTotal.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: _imgBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.black87),
      ),
    );
  }

  // Mobile / narrow-screen bottom bar. Fixed height via SafeArea + a
  // height-bound Row (no Expanded ancestor forcing it to fill the screen)
  // is what keeps this pinned as a slim bar instead of stretching full-page.
  Widget _buildCheckoutBar() {
    return SafeArea(
      top: false,
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Subtotal',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  Text(
                    '₹${_subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 170,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _placingOrder ? null : _handleBuyNow,
                icon: _placingOrder
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.flash_on, color: Colors.white, size: 20),
                label: Text(
                  _placingOrder ? 'PLACING...' : 'BUY NOW',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
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
