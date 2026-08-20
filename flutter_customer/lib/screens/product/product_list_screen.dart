import 'package:flutter/material.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
// TODO: point this at wherever your product endpoints live.
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import '../product/product_details_screen.dart';
import 'product_filters.dart';

// ===========================================================================
// ARGS — what to fetch (shop or search) + the title to show
// ===========================================================================

/// Carries the "which products to show" info from Home (or search bar)
/// into ProductListScreen. Only two keys are used right now — add more
/// later (e.g. 'categoryId') without touching anything else if needed.
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

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadWishlistIds();
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
        actions: [_buildFilterAction()],
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