import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_mobile_header.dart';
import 'product_filters.dart';

// ===========================================================================
// ARGS — what to fetch (shop or search) + the title to show
// ===========================================================================

class ProductListArgs {
  static const String keyShop = 'shopId';
  static const String keySearch = 'search';

  final String key;
  final dynamic value;
  final String title;
  final String? searchQuery;

  const ProductListArgs({
    required this.key,
    required this.value,
    required this.title,
    this.searchQuery,
  });

  factory ProductListArgs.shop({
    required int shopId,
    required String shopName,
  }) {
    return ProductListArgs(key: keyShop, value: shopId, title: shopName);
  }

  factory ProductListArgs.search({required String query}) {
    return ProductListArgs(
      key: keySearch,
      value: query,
      title: 'Results for "$query"',
      searchQuery: query,
    );
  }

  bool get isShop => key == keyShop;

  bool get isSearch => key == keySearch;

  int get shopId => value as int;
}

// ===========================================================================
// SCREEN
// ===========================================================================

/// Single reusable listing screen — driven entirely by ProductModel /
/// ProductService.
///
/// FILTERING MODEL:
/// - `_allProducts` = raw, unfiltered list fetched once per load.
/// - `_products` = `_allProducts` run through `_filters.matches()`.
/// - Applying filters never re-fetches.
/// - `_availableSizes` / `_availableColors` come from the backend.
///
/// DESKTOP vs MOBILE FILTER UX:
/// - Desktop: filters apply immediately.
/// - Mobile: filters are pushed to `/filter` and applied when committed.
///
/// MOBILE HEADER:
/// - Mobile header is extracted into ProductListMobileHeader.
/// - Search logic is handled by the reusable mobile header.
/// - Cart count is handled by the reusable mobile header.
class ProductListScreen extends StatefulWidget {
  final ProductListArgs args;
  final bool autoFocusSearch;

  const ProductListScreen({
    super.key,
    required this.args,
    this.autoFocusSearch = false,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // =========================================================================
  // CONSTANTS
  // =========================================================================

  static const double _desktopBreakpoint = 900;

  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _ink = Color(0xFF1F1B16);

  // =========================================================================
  // PRODUCTS
  // =========================================================================

  List<ProductModel> _allProducts = [];

  bool _isLoading = true;

  String? _error;

  ProductFilters _filters = const ProductFilters();

  List<String> _availableSizes = [];

  List<String> _availableColors = [];

  List<ProductModel> get _products =>
      _allProducts.where(_filters.matches).toList();

  // =========================================================================
  // WISHLIST
  // =========================================================================

  final Set<int> _wishlistIds = {};

  /// Product IDs whose wishlist request is currently being processed.
  ///
  /// This prevents rapid multiple clicks from sending duplicate API
  /// requests for the same product.
  final Set<int> _wishlistUpdatingIds = {};

  // =========================================================================
  // LIFECYCLE
  // =========================================================================

  @override
  void initState() {
    super.initState();

    _loadProducts();
    _loadWishlistIds();
    _loadFilterOptions();
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= _desktopBreakpoint;
  }

  bool get _isLoggedIn {
    final token = ApiService.getToken();

    return token != null && token.isNotEmpty;
  }

  // =========================================================================
  // DATA
  // =========================================================================

  Future<List<ProductModel>> _fetchProducts() {
    if (widget.args.isShop) {
      return ProductService.getProductsByShop(widget.args.shopId);
    }

    return ProductService.searchProducts(widget.args.value as String);
  }

  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final products = await _fetchProducts();

      if (!mounted) return;

      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Could not load products. Please try again.';
      });
    }
  }

  Future<void> _loadFilterOptions() async {
    try {
      final options = await ProductService.getFilterOptions();

      if (!mounted) return;

      setState(() {
        _availableSizes = options.sizes;
        _availableColors = options.colors;
      });
    } catch (_) {
      // Keep filter options empty if loading fails.
    }
  }

  Future<void> _loadWishlistIds() async {
    if (!_isLoggedIn) return;

    try {
      final items = await WishlistService.getWishlist();

      if (!mounted) return;

      setState(() {
        _wishlistIds
          ..clear()
          ..addAll(items.map((product) => product.id));
      });
    } catch (_) {
      // Silent — hearts simply remain unfilled
      // if loading fails.
    }
  }

  // =========================================================================
  // WISHLIST TOGGLE
  // =========================================================================

  Future<void> _toggleWishlist(ProductModel product) async {
    if (!_isLoggedIn) {
      _goToProtected(context, GoRouterState.of(context).uri.toString());

      return;
    }

    final productId = product.id;

    // Prevent duplicate requests for the same product.
    if (_wishlistUpdatingIds.contains(productId)) {
      return;
    }

    final wasWishlisted = _wishlistIds.contains(productId);

    // -----------------------------------------------------------------------
    // Optimistic UI update
    // -----------------------------------------------------------------------

    setState(() {
      _wishlistUpdatingIds.add(productId);

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

    if (!mounted) return;

    setState(() {
      _wishlistUpdatingIds.remove(productId);

      // ---------------------------------------------------------------------
      // Roll back optimistic update if API failed.
      // ---------------------------------------------------------------------

      if (!ok) {
        if (wasWishlisted) {
          _wishlistIds.add(productId);
        } else {
          _wishlistIds.remove(productId);
        }
      }
    });
  }

  // =========================================================================
  // NAVIGATION
  // =========================================================================

  void _openProduct(ProductModel product) {
    final search = widget.args.searchQuery?.trim();

    // -----------------------------------------------------------------------
    // SHOP PRODUCT
    // -----------------------------------------------------------------------

    if (widget.args.isShop) {
      context.push(
        Uri(
          path: '/products/${product.id}',
          queryParameters: {
            'shopId': widget.args.shopId.toString(),
            'shopName': widget.args.title,
          },
        ).toString(),
      );

      return;
    }

    // -----------------------------------------------------------------------
    // SEARCH PRODUCT
    // -----------------------------------------------------------------------

    context.push(
      Uri(
        path: '/products/${product.id}',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      ).toString(),
    );
  }

  void _openShopOverview() {
    context.push('/shops/${widget.args.shopId}');
  }

  void _openCart() {
    _goToProtected(context, '/cart');
  }

  // =========================================================================
  // FILTERS
  // =========================================================================

  Future<void> _openFilterPage() async {
    final result = await context.push<ProductFilters>(
      '/filter',
      extra: FilterPageArgs(
        filters: _filters,
        allProducts: _allProducts,
        availableSizes: _availableSizes,
        availableColors: _availableColors,
      ),
    );

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _filters = result;
      });
    }
  }

  void _applyDesktopFilters(ProductFilters filters) {
    if (!mounted) return;

    setState(() {
      _filters = filters;
    });
  }

  void _clearFilters() {
    if (!mounted) return;

    setState(() {
      _filters = const ProductFilters();
    });
  }

  // =========================================================================
  // PROTECTED ROUTES
  // =========================================================================

  void _goToProtected(BuildContext context, String route) {
    final token = ApiService.getToken();

    final isLoggedIn = token != null && token.isNotEmpty;

    if (isLoggedIn) {
      context.push(route);
    } else {
      context.push(
        Uri(path: '/login', queryParameters: {'redirect': route}).toString(),
      );
    }
  }

  // =========================================================================
  // BACK
  // =========================================================================

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  // =========================================================================
  // EMPTY STATE
  // =========================================================================

  String get _emptyMessage {
    if (_filters.activeCount > 0) {
      return 'No products match the selected filters.';
    }

    if (widget.args.isSearch) {
      return 'No products found for '
          '"${widget.args.value}".';
    }

    return 'No products in this shop yet.';
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: isDesktop,
        bottom: false,
        child: isDesktop ? _buildDesktopScaffold() : _buildMobileScaffold(),
      ),
    );
  }

  // =========================================================================
  // DESKTOP
  // =========================================================================

  Widget _buildDesktopScaffold() {
    return Column(
      children: [
        _buildDesktopTopBar(),

        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    ..._buildProductSlivers(isDesktopLayout: true),

                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),

              // ----------------------------------------------------------------
              // DESKTOP FILTER PANEL
              // ----------------------------------------------------------------
              Container(
                width: 340,
                margin: const EdgeInsets.fromLTRB(0, 16, 24, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                clipBehavior: Clip.antiAlias,
                child: FilterPanel(
                  initialFilters: _filters,
                  allProducts: _allProducts,
                  availableSizes: _availableSizes,
                  availableColors: _availableColors,
                  onApply: _applyDesktopFilters,
                  isDesktop: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // DESKTOP TOP BAR
  // =========================================================================

  Widget _buildDesktopTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 14, 24, 0),
      child: Row(
        children: [
          Expanded(child: _desktopBreadcrumb()),

          if (widget.args.isShop)
            OutlinedButton.icon(
              onPressed: _openShopOverview,
              icon: const Icon(Icons.storefront_outlined, size: 16),
              label: const Text('Overview'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(color: Colors.black26),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // DESKTOP BREADCRUMB
  // =========================================================================

  Widget _desktopBreadcrumb() {
    TextStyle crumbStyle({bool active = false}) {
      return TextStyle(
        fontSize: 15,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? _ink : _ink.withOpacity(0.5),
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Text('Home', style: crumbStyle()),
        ),

        Text('  /  ', style: crumbStyle()),

        Expanded(
          child: Text(
            widget.args.isShop
                ? widget.args.title
                : 'Search Results for '
                      '"${widget.args.value}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: crumbStyle(active: true),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // MOBILE
  // =========================================================================

  Widget _buildMobileScaffold() {
    return Column(
      children: [
        // ---------------------------------------------------------------------
        // REUSABLE MOBILE HEADER
        // ---------------------------------------------------------------------

        ProductMobileHeader(
          title: widget.args.title,
          onBack: () => _goBack(context),
          onCart: _openCart,
        ),

        Expanded(
          child: CustomScrollView(
            slivers: [
              // ---------------------------------------------------------------
              // MOBILE FILTER TOOLBAR
              // ---------------------------------------------------------------

              SliverToBoxAdapter(child: _buildMobileFilterToolbar()),

              // ---------------------------------------------------------------
              // PRODUCTS
              // ---------------------------------------------------------------
              ..._buildProductSlivers(isDesktopLayout: false),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // MOBILE FILTER TOOLBAR
  // =========================================================================

  Widget _buildMobileFilterToolbar() {
    final count = _filters.activeCount;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _openFilterPage,
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(Icons.tune, size: 18),
            ),
            label: const Text('Filters'),
            style: TextButton.styleFrom(foregroundColor: _ink),
          ),

          const Spacer(),

          if (widget.args.isShop)
            TextButton.icon(
              onPressed: _openShopOverview,
              icon: const Icon(Icons.storefront_outlined, size: 16),
              label: const Text('Overview'),
              style: TextButton.styleFrom(foregroundColor: _ink),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // GRID
  // =========================================================================

  int _gridColumnCount(double width) {
    if (width >= 1000) {
      return 4;
    }

    if (width >= 700) {
      return 3;
    }

    if (width >= 460) {
      return 2;
    }

    return 2;
  }

  // =========================================================================
  // PRODUCT SLIVERS
  // =========================================================================

  List<Widget> _buildProductSlivers({required bool isDesktopLayout}) {
    // -------------------------------------------------------------------------
    // LOADING
    // -------------------------------------------------------------------------

    if (_isLoading) {
      return const [
        SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      ];
    }

    // -------------------------------------------------------------------------
    // ERROR
    // -------------------------------------------------------------------------

    if (_error != null) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.black54)),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _loadProducts,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // -------------------------------------------------------------------------
    // EMPTY
    // -------------------------------------------------------------------------

    if (_products.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _emptyMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),

                if (_filters.activeCount > 0) ...[
                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Clear filters'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
    }

    // -------------------------------------------------------------------------
    // PRODUCT GRID
    // -------------------------------------------------------------------------

    return [
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _gridColumnCount(constraints.crossAxisExtent);

          return SliverPadding(
            padding: EdgeInsets.fromLTRB(16, isDesktopLayout ? 16 : 8, 16, 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = _products[index];

                final isUpdating = _wishlistUpdatingIds.contains(product.id);

                return ProductCard(
                  // Stable key prevents Flutter
                  // from incorrectly reusing a
                  // hovered card for another
                  // product when wishlist state
                  // changes.
                  key: ValueKey('product_${product.id}'),

                  product: product,

                  isWishlisted: _wishlistIds.contains(product.id),

                  isWishlistUpdating: isUpdating,

                  onWishlistTap: isUpdating
                      ? null
                      : () => _toggleWishlist(product),

                  onTap: () => _openProduct(product),
                );
              }, childCount: _products.length),
            ),
          );
        },
      ),
    ];
  }
}
