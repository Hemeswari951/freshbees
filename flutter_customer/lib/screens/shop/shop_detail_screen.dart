
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../services/api_service.dart';
import '../../services/shop_service.dart';
import '../../services/wishlist_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_details_screen.dart';

/// Shop Detail screen — opened when a customer taps a shop on the Home
/// screen's "Nearby Shops" section. Lists every ACTIVE product the shop
/// owner has added for this shop (the same ones already visible under
/// the shop in the Admin Portal), reusing the same ProductCard used
/// elsewhere in the app so styling and wishlist behaviour stay consistent.
class ShopDetailScreen extends StatefulWidget {
  final int shopId;

  /// Passed in via go_router's `extra` when navigating from a screen that
  /// already has the full ShopModel (Home) — avoids an extra network
  /// round-trip. Left null when arriving from a deep link with only the
  /// id, in which case the screen fetches it itself.
  final ShopModel? initialShop;

  const ShopDetailScreen({super.key, required this.shopId, this.initialShop});

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  ShopModel? _shop;

  List<ProductModel> _products = [];
  bool _isLoadingProducts = true;
  String? _productsError;

  final Set<int> _wishlistIds = {};

  @override
  void initState() {
    super.initState();
    _shop = widget.initialShop;
    _loadShop();
    _loadProducts();
    _loadWishlistIds();
  }

  Future<void> _loadShop() async {
    if (_shop != null) return; // already have it from `extra`
    try {
      final shop = await ShopService.getShopById(widget.shopId);
      if (!mounted) return;
      setState(() => _shop = shop);
    } catch (_) {
      // Header just falls back to showing "Shop" — the product grid
      // below still loads independently.
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });
    try {
      final products = await ShopService.getShopProducts(widget.shopId);
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
        _productsError = 'Could not load products. Please try again.';
      });
    }
  }

  Future<void> _loadWishlistIds() async {
    final token = ApiService.getToken();
    if (token == null || token.isEmpty) return; // guest — hearts stay unfilled

    try {
      final items = await WishlistService.getWishlist();
      if (!mounted) return;
      setState(() {
        _wishlistIds
          ..clear()
          ..addAll(items.map((p) => p.id));
      });
    } catch (_) {
      // Silent — hearts simply default to unfilled if this fails.
    }
  }

  Future<void> _toggleWishlist(ProductModel product) async {
    final token = ApiService.getToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use your wishlist')),
      );
      return;
    }

    final wasWishlisted = _wishlistIds.contains(product.id);

    // Optimistic UI update, reconciled with the backend call below.
    setState(() {
      if (wasWishlisted) {
        _wishlistIds.remove(product.id);
      } else {
        _wishlistIds.add(product.id);
      }
    });

    bool ok;
    try {
      ok = wasWishlisted
          ? await WishlistService.removeFromWishlist(product.id)
          : await WishlistService.addToWishlist(product.id);
    } catch (_) {
      ok = false;
    }

    // Roll back on failure so the heart doesn't lie about what's saved.
    if (!ok && mounted) {
      setState(() {
        if (wasWishlisted) {
          _wishlistIds.add(product.id);
        } else {
          _wishlistIds.remove(product.id);
        }
      });
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
    final bannerUrl = (_shop?.shopBanner != null && _shop!.shopBanner!.isNotEmpty)
        ? '${ApiService.serverUrl}${_shop!.shopBanner}'
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go('/home'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _shop?.shopName ?? 'Shop',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  bannerUrl != null
                      ? Image.network(
                          bannerUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              Container(color: const Color(0xFF2D2D2D)),
                        )
                      : Container(
                          color: const Color(0xFF2D2D2D),
                          child: const Icon(
                            Icons.storefront_outlined,
                            size: 50,
                            color: Colors.white30,
                          ),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if ((_shop?.locationLabel ?? '').isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _shop!.locationLabel,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Products',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          if (_isLoadingProducts)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_productsError != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_productsError!,
                        style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 12),
                    TextButton(onPressed: _loadProducts, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_products.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'No products in this shop yet.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.62,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _products[index];
                    return ProductCard(
                      product: product,
                      isWishlisted: _wishlistIds.contains(product.id),
                      onWishlistTap: () => _toggleWishlist(product),
                      onTap: () => _openProduct(product),
                    );
                  },
                  childCount: _products.length,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}