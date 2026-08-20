import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_details_screen.dart';

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
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
        _error = 'Could not load your wishlist. Please try again.';
      });
    }
  }

  Future<void> _removeFromWishlist(ProductModel product) async {
    // Optimistic removal — put it back if the backend call fails.
    final removedIndex = _items.indexWhere((p) => p.id == product.id);
    if (removedIndex == -1) return;

    setState(() => _items.removeAt(removedIndex));

    bool ok;
    try {
      ok = await WishlistService.removeFromWishlist(product.id);
    } catch (_) {
      ok = false;
    }

    if (!ok && mounted) {
      setState(() => _items.insert(removedIndex, product));
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
  }

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