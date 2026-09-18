import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/cart_service.dart';
import '../address/address_screen.dart';
import '../../services/wishlist_service.dart';
import '../product/product_view_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = true;
  String? _error;
  final bool _placingOrder = false;
  List<CartItemModel> _items = [];
  double _subtotal = 0;
  final Set<int> _selectedCartItemIds = {};
  final Set<int> _busyRows = {};

  static const double _desktopBreakpoint = 900;
  static const double _maxContentWidth = 1100;

  // Custom Ivory & Proceed Theme Colors
  static const Color _ivoryBg = Color(0xFFFAF7F2);
  static const Color _cardBg = Colors.white;
  static const Color _accentBrown = Color(0xFF5D4037);
  static const Color _accentBrownLight = Color(0xFF8D6E63);
  static const Color _primaryText = Color(0xFF212121);
  static const Color _secondaryText = Color(0xFF757575);
  static const Color _cardBorder = Color(0xFFEFEBE9);
  static const Color _imgBg = Color(0xFFF5F2EC);

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart({bool silent = false}) async {
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
        _items = result.items;
        _selectedCartItemIds.retainWhere(
          (id) => _items.any((item) => item.cartItemId == id),
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
      _confirmRemoveItem(item);
      return;
    }
    setState(() => _busyRows.add(item.cartItemId));
    try {
      await CartService.updateQuantity(
        cartItemId: item.cartItemId,
        quantity: newQty,
      );
      await _loadCart(silent: true);
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

  Future<void> _handleBuyNow() async {
    final selectedCount = _selectedCartItemIds.length;
    final selectedCartItemIds = _selectedCartItemIds.toList();
    if (selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item to proceed'),
        ),
      );
      return;
    }

    await AddressScreen.startCheckout(
      context,
      cartItemIds: selectedCartItemIds,
    );
    if (mounted) _loadCart();
  }

  Future<void> _confirmRemoveItem(CartItemModel item) async {
    final action = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _ivoryBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Remove Item',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: _primaryText,
            ),
          ),
          content: const Text(
            'Are you sure you want to remove this item from your cart?',
            style: TextStyle(color: _secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('wishlist'),
              child: const Text(
                'MOVE TO WISHLIST',
                style: TextStyle(
                  color: _accentBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop('remove'),
              child: const Text(
                'REMOVE',
                style: TextStyle(
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (action == 'remove') {
      _removeItem(item);
    } else if (action == 'wishlist') {
      _removeItem(item);
      try {
        // NOTE: Make sure `addToWishlist` (or equivalent method name) exists in your WishlistService
        await WishlistService.addToWishlist(
          item.productId,
          productColorId: item.productColorId, // <-- NEW: Pass the color ID
        );
       
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item moved to wishlist')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      }
    }
  }

  PreferredSizeWidget _buildMobileCartAppBar() {
    return AppBar(
      backgroundColor: _cardBg,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 56,
      titleSpacing: 0,

      title: Row(
        children: [
          // ---------------------------------------------------------------
          // BACK BUTTON
          // ---------------------------------------------------------------

          SizedBox(
            width: 42,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.arrow_back, color: _primaryText, size: 22),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.of(context).maybePop();
                }
              },
            ),
          ),

          // Small gap only
          const SizedBox(width: 2),

          // ---------------------------------------------------------------
          // CART TITLE
          // ---------------------------------------------------------------
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Shopping Cart',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _primaryText,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),

                if (_items.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(
                    '(${_items.length})',
                    style: const TextStyle(
                      color: _secondaryText,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= _desktopBreakpoint;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: _ivoryBg,
        appBar: isDesktop ? null : _buildMobileCartAppBar(),
        body: SafeArea(child: _buildBody(isDesktop)),
        bottomNavigationBar: (!isDesktop && _items.isNotEmpty)
            ? _buildCheckoutBar()
            : null,
      ),
    );
  }

  Widget _buildBody(bool isDesktop) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _accentBrown),
      );
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _secondaryText),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadCart,
                style: ElevatedButton.styleFrom(backgroundColor: _accentBrown),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
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
              const Icon(
                Icons.shopping_cart_outlined,
                size: 72,
                color: Colors.black12,
              ),
              const SizedBox(height: 24),
              const Text(
                'Your shopping cart is empty',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _primaryText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add items you love to your cart.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _secondaryText, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBrown,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Continue Shopping',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final list = RefreshIndicator(
      color: _accentBrown,
      onRefresh: _loadCart,
      child: ListView.separated(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        itemCount: _items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSelectionHeader();
          }
          return _buildModernCartTile(_items[index - 1]);
        },
      ),
    );

    if (!isDesktop) {
      return list;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxContentWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: list),
              const SizedBox(width: 32),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildSummaryCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionHeader() {
    final allSelected =
        _items.isNotEmpty && _selectedCartItemIds.length == _items.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: allSelected,
              activeColor: _accentBrown,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              onChanged: (_) => _toggleSelectAll(),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_selectedCartItemIds.length}/${_items.length} ITEMS SELECTED',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primaryText,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Items (${_selectedCartItemIds.length})',
                style: const TextStyle(color: _secondaryText),
              ),
              Text(
                '₹${_subtotal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: _cardBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: _primaryText,
                ),
              ),
              Text(
                '₹${_subtotal.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: _accentBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Requirement 3 Fix: Styled with gradient and polish shadow effect
          SizedBox(
            width: double.infinity,
            height: 50,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [_accentBrown, _accentBrownLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentBrown.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _placingOrder ? null : _handleBuyNow,
                icon: const Icon(
                  Icons.lock_outline,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'PROCEED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCartTile(CartItemModel item) {
    final busy = _busyRows.contains(item.cartItemId);
    final isSelected = _selectedCartItemIds.contains(item.cartItemId);
    final imageUrl = item.thumbnail.isNotEmpty
        ? '${ApiService.serverUrl}${item.thumbnail}'
        : null;
    final hasDiscount = item.mrp != null && item.mrp! > item.price;
    final discountPct = hasDiscount
        ? (((item.mrp! - item.price) / item.mrp!) * 100).round()
        : 0;

    // Requirement 2 Fix: Dynamic live rating with 0.0 fallback logic when reviews are missing/zero
    final double displayRating = (item.rating != null) ? item.rating! : 0.0;
    final int displayReviewCount = item.reviewCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: isSelected,
            activeColor: _accentBrown,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (_) => _toggleItemSelection(item.cartItemId),
          ),
          const SizedBox(width: 8),

          // Active Navigation: Clickable Product Image -> Goes to Product View Screen
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductViewScreen(productId: item.productId),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Container(
                  color: _imgBg,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.image, color: Colors.black38),
                        )
                      : const Icon(Icons.image, color: Colors.black38),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.shopName != null && item.shopName!.isNotEmpty) ...[
                  Text(
                    item.shopName!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _accentBrown,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Active Navigation: Clickable Product Name -> Goes to Product View Screen
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductViewScreen(productId: item.productId),
                      ),
                    );
                  },
                  child: Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: _primaryText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                if (item.size != null || item.color != null) ...[
                  Text(
                    [
                      if (item.size != null) 'Size: ${item.size}',
                      if (item.color != null) 'Color: ${item.color}',
                    ].join('  |  '),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _secondaryText,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Requirement 2 Fix: Dynamic Live Rating Badge Display in Cart (shows 0.0 or actual rating)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: displayRating > 0
                            ? const Color(0xFF388E3C)
                            : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            displayRating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star, color: Colors.white, size: 10),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($displayReviewCount)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: _secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    Text(
                      '₹${item.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _primaryText,
                      ),
                    ),
                    if (hasDiscount && item.mrp != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${item.mrp!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: _secondaryText,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$discountPct% OFF',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                busy
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accentBrown,
                        ),
                      )
                    : Row(
                        children: [
                          _qtyButton(
                            icon: Icons.remove,
                            onTap: () =>
                                _changeQuantity(item, item.quantity - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          _qtyButton(
                            icon: Icons.add,
                            onTap: () =>
                                _changeQuantity(item, item.quantity + 1),
                          ),
                        ],
                      ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.black54,
              size: 22,
            ),
            onPressed: busy ? null : () => _confirmRemoveItem(item),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _imgBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _cardBorder),
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  Widget _buildCheckoutBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                  'Total Amount',
                  style: TextStyle(fontSize: 12, color: _secondaryText),
                ),
                Text(
                  '₹${_subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _primaryText,
                  ),
                ),
              ],
            ),
          ),
          // Requirement 3 Fix: Mobile bottom proceed button styled with gradient and polish shadow effect
          SizedBox(
            width: 160,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [_accentBrown, _accentBrownLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _accentBrown.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _placingOrder ? null : _handleBuyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'PROCEED',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
