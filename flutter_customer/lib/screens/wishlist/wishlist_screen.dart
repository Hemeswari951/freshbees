//wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';
import '../cart/cart_screen.dart';
import '../../widgets/product_card.dart';
import '../product/product_view_screen.dart';

/// Wishlist screen — every product the logged-in customer has hearted,
/// backed by GET /api/customer/wishlist. Reuses the same ProductCard as
/// the rest of the app, so tapping the (now-filled) heart here removes
/// the item, matching the toggle behaviour everywhere else.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  bool _isLoggedIn = false;
  bool _isLoading = true;
  String? _error;
  List<ProductModel> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ApiService.loadToken();
    final token = ApiService.getToken();
    final loggedIn = token != null && token.isNotEmpty;

    if (!loggedIn) {
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
      return;
    }

    try {
      final items = await WishlistService.getWishlist();
      if (!mounted) return;
      setState(() {
        _isLoggedIn = true;
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Show the real reason (status code / server message) instead of a
      // generic string — this is what tells you 401 vs 404 vs 500 without
      // digging through DevTools every time.
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _removeFromWishlist(ProductModel product) async {
    // Optimistic removal — put it back if the backend call fails.
    final removedIndex = _items.indexWhere((p) => p.id == product.id);
    if (removedIndex == -1) return;

    setState(() => _items.removeAt(removedIndex));

    bool ok;
    String? failureReason;
    try {
      ok = await WishlistService.removeFromWishlist(product.id);
    } catch (e) {
      ok = false;
      failureReason = e.toString().replaceFirst('Exception: ', '');
    }

    if (!ok && mounted) {
      setState(() => _items.insert(removedIndex, product));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureReason ?? 'Could not remove item. Please try again.')),
      );
    }
  }

   Future<void> _confirmRemoveFromWishlist(ProductModel product) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Remove Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          content: const Text('Are you sure you want to remove this item from your wishlist?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Returns false on CANCEL
              child: const Text('CANCEL', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Returns true on REMOVE
              child: const Text('REMOVE', style: TextStyle(color: Color(0xFFFF3E6C), fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    // If the user clicked REMOVE, proceed with the actual removal
    if (shouldRemove == true) {
      _removeFromWishlist(product);
    }
  }



  Future<void> _moveToBag(ProductModel product) async {
    try {
      // 1. Add the item to the cart via the API
      await CartService.addToCart(
        productId: product.id,
        quantity: 1, // Default quantity when moving from wishlist
      );

      // 2. Remove it from the wishlist so it doesn't stay behind
      await _removeFromWishlist(product);

      if (!mounted) return;

      // 3. Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.productName} moved to bag')),
      );

      // 4. Navigate directly to the Cart Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const CartScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // Show error if the add-to-cart fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  void _openProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductViewScreen(productId: product.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Wishlist',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  /*Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isLoggedIn) {
      return _emptyState(
        icon: Icons.lock_outline,
        title: 'Please login to view your wishlist',
        actionLabel: 'Login',
        onAction: () => context.push('/login'),
      );
    }

    if (_error != null) {
      return _emptyState(
        icon: Icons.error_outline,
        title: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    if (_items.isEmpty) {
      return _emptyState(
        icon: Icons.favorite_border,
        title: 'Your wishlist is empty',
        subtitle: 'Tap the heart on any product to save it here.',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.62,
        ),
        itemBuilder: (context, index) {
          final product = _items[index];
          return ProductCard(
            product: product,
            isWishlisted: true,
            onWishlistTap: () => _removeFromWishlist(product),
            onTap: () => _openProduct(product),
          );
        },
      ),
    );
  }*/

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isLoggedIn) {
      return _emptyState(
        icon: Icons.lock_outline,
        title: 'Please login to view your wishlist',
        actionLabel: 'Login',
        onAction: () => context.push('/login'),
      );
    }

    if (_error != null) {
      return _emptyState(
        icon: Icons.error_outline,
        title: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    if (_items.isEmpty) {
      return _emptyState(
        icon: Icons.favorite_border,
        title: 'Your wishlist is empty',
        subtitle: 'Tap the heart on any product to save it here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Myntra-style header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                const TextSpan(
                  text: 'My Wishlist ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: '${_items.length} items',
                  style: const TextStyle(fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            // LayoutBuilder gives the real available width on every
            // rebuild (window resize, orientation change, going from a
            // phone-sized window to a maximized desktop one) so the grid
            // re-flows instead of being pinned to a fixed column count.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = _columnsForWidth(constraints.maxWidth);
                // Desktop cards get a taller image relative to width vs.
                // phones, matching Myntra's own layout at each breakpoint.
                final aspectRatio = columns <= 2 ? 0.58 : 0.66;

                return Center(
                  child: ConstrainedBox(
                    // Caps the grid on ultra-wide monitors so cards don't
                    // stretch into huge empty-feeling tiles — Myntra does
                    // the same with a centered, max-width content column.
                    constraints: const BoxConstraints(maxWidth: 1600),
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _items.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (context, index) {
                        final product = _items[index];
                        return _buildMyntraWishlistCard(product);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // Mirrors Myntra's own responsive breakpoints: 2-up on phones, scaling
  // up to 5-up on desktop-width screens.
  int _columnsForWidth(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  Widget _buildMyntraWishlistCard(ProductModel product) {
    // Safely calculate prices for the UI
    final double sellingPrice = product.price.toDouble();
    final double mrp = product.mrp?.toDouble() ?? sellingPrice;
    final int discount = mrp > sellingPrice ? ((mrp - sellingPrice) / mrp * 100).round() : 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image and Close (X) button
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => _openProduct(product),
                    child: Container(
                      color: const Color(0xFFF5F1EA),
                      child: product.thumbnail.isEmpty
                          ? const Center(
                              child: Icon(Icons.image_outlined, color: Colors.black26, size: 36),
                            )
                          : Image.network(
                              product.thumbnail,
                              fit: BoxFit.cover,
                              // A broken/missing thumbnail URL (e.g. one
                              // that 404s and returns an HTML error page)
                              // used to crash the tile with a big red
                              // "ImageCodecException" overlay. Fall back
                              // to a plain placeholder instead.
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(Icons.image_not_supported_outlined,
                                      color: Colors.black26, size: 36),
                                );
                              },
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
                            ),
                    ),
                  ),
                ),
                // Close 'X' Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    // UPDATE THIS LINE to call the new confirmation dialog
                    onTap: () => _confirmRemoveFromWishlist(product),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
                      ),
                      child: const Icon(Icons.close, size: 14, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product Details
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      'Rs.${sellingPrice.toInt()}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (discount > 0) ...[
                      Text(
                        'Rs.${mrp.toInt()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.4),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        '($discount% OFF)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Divider and Move to Bag Button
          const Divider(height: 1, color: Colors.black12),
          InkWell(
            onTap: () => _moveToBag(product),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 11),
              child: Text(
                'MOVE TO BAG',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF3E6C), // Myntra pink
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*Future<void> _moveToBag(ProductModel product) async {
    // TODO: Call your CartService to add the item to the bag.
    // Example: await CartService.addToCart(product.id, quantity: 1);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.productName} moved to bag')),
    );
    
    // Optional: Myntra typically removes the item from the wishlist once moved to the bag.
    // _removeFromWishlist(product); 
  }*/

  Widget _emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
