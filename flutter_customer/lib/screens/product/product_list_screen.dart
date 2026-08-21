import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_details_screen.dart';
import 'product_filters.dart';
import '../../services/wishlist_service.dart';
import '../wishlist/wishlist_screen.dart'; // Adjust path if your folder structure is different

class ProductListArgs {
  static const String keyShop = 'shopId';
  static const String keySearch = 'search';

  /// Which kind of filter this is — [keyShop] or [keySearch].
  final String key;

  /// The value for that filter: shop id (int) for [keyShop],
  /// the typed query (String) for [keySearch].
  final dynamic value;

  /// Text shown in the AppBar — shop name, or `Results for "query"`.
  final String title;

  const ProductListArgs({
    required this.key,
    required this.value,
    required this.title,
  });

  factory ProductListArgs.shop({required int shopId, required String shopName}) {
    return ProductListArgs(key: keyShop, value: shopId, title: shopName);
  }

  factory ProductListArgs.search({required String query}) {
    return ProductListArgs(
      key: keySearch,
      value: query,
      title: 'Results for "$query"',
    );
  }

  bool get isShop => key == keyShop;
  bool get isSearch => key == keySearch;
}

// ===========================================================================
// SCREEN
// ===========================================================================

/// Single reusable listing screen — driven entirely by ProductModel /
/// ProductService. Every clickable entry point on Home (nearby shop
/// card, search bar) routes here with a [ProductListArgs]; this screen
/// decides which API to call and applies [ProductFilters] on top.
class ProductListScreen extends StatefulWidget {
  final ProductListArgs args;

  const ProductListScreen({super.key, required this.args});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;

  ProductFilters _filters = const ProductFilters();

  final Set<int> _wishlistIds = {};
  bool _isLoggedIn = false; // Safely track login state

  

  @override
  void initState() {
    super.initState();
    _loadProducts();
    //_loadWishlistIds();
    _loadWishlist();
    _checkLoginAndLoadWishlist(); // Initialize login status safely

  }

  /// Only place that decides which service call to make. If your real
  /// method names/signatures differ, this is the one spot to edit.
  Future<List<ProductModel>> _fetchProducts() {
    final queryParams = _filters.toQueryParams();
    if (widget.args.isShop) {
      return ProductService.getProductsByShop(
        widget.args.value as int,
        filters: queryParams,
      );
    }
    return ProductService.searchProducts(
      widget.args.value as String,
      filters: queryParams,
    );
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final products = await _fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load products. Please try again.';
      });
    }
  }


   Future<void> _checkLoginAndLoadWishlist() async {
    await ApiService.loadToken();
    final token = ApiService.getToken();
    
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
      });
    }

    if (_isLoggedIn) {
      _loadWishlist();
    }
  }

  // 2. Load wishlist directly without reloading the token
  Future<void> _loadWishlist() async {
    try {
      final items = await WishlistService.getWishlist();
      if (!mounted) return;
      setState(() {
        _wishlistIds
          ..clear()
          ..addAll(items.map((p) => p.id));
      });
    } catch (_) {
      // Silent fail
    }
  }

  // 3. Toggle wishlist purely relying on the safe _isLoggedIn state. 
  // DO NOT call ApiService.loadToken() inside this function.
  Future<void> _toggleWishlist(ProductModel product) async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use your wishlist')),
      );
      return;
    }

    final int productId = product.id;
    final bool wasWishlisted = _wishlistIds.contains(productId);

    // Optimistic UI update for instant red heart
    setState(() {
      if (wasWishlisted) {
        _wishlistIds.remove(productId);
      } else {
        _wishlistIds.add(productId);
      }
    });

    bool ok;
    try {
      ok = wasWishlisted
          ? await WishlistService.removeFromWishlist(productId)
          : await WishlistService.addToWishlist(productId);
    } catch (_) {
      ok = false;
    }

    // Roll back UI only if the API genuinely fails
    if (!ok && mounted) {
      setState(() {
        if (wasWishlisted) {
          _wishlistIds.add(productId);
        } else {
          _wishlistIds.remove(productId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update wishlist. Please try again.')),
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

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<ProductFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FilterBottomSheet(initialFilters: _filters),
    );

    if (result != null) {
      setState(() => _filters = result);
      _loadProducts(); // refetch with the new filters applied
    }
  }

  String get _emptyMessage {
    if (widget.args.isSearch) {
      return 'No products found for "${widget.args.value}".';
    }
    return 'No products in this shop yet.';
  }

 /* @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          widget.args.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [_buildFilterAction()],
      ),
      body: CustomScrollView(
        slivers: [
          ..._buildProductSlivers(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(
          widget.args.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [
          _buildFilterAction(),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          ..._buildProductSlivers(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildFilterAction() {
    final count = _filters.activeCount;
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.tune, color: Colors.black87),
          onPressed: _openFilterSheet,
        ),
        if (count > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildProductSlivers() {
    if (_isLoading) {
      return const [
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                TextButton(onPressed: _loadProducts, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ];
    }

    if (_products.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_emptyMessage, style: const TextStyle(color: Colors.black54)),
                if (_filters.activeCount > 0) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() => _filters = const ProductFilters());
                      _loadProducts();
                    },
                    child: const Text('Clear filters'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
    }

    return [
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
    ];
  }
}

/// ---------------------------------------------------------------------
/// USAGE — call these from Home.
/// ---------------------------------------------------------------------
///
/// Nearby shop card tapped — shopId/shopName both already sit on
/// ProductModel, so if you're navigating from a list of products (or
/// have the shop's name/id from wherever the card came from) this is
/// all you need — no separate shop fetch:
///
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ProductListScreen(
///     args: ProductListArgs.shop(shopId: shopId, shopName: shopName),
///   ),
/// ));
///
/// Search bar submitted:
///
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ProductListScreen(
///     args: ProductListArgs.search(query: query),
///   ),
/// ));