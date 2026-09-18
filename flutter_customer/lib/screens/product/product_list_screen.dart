import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
  static const String keyImage = 'image';

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

  /// Camera-icon image search — the picked/captured photo is carried as
  /// the arg value (routed in via GoRouter `extra`, since an XFile can't
  /// travel in a URL). Reuses this same screen/UI so image results get
  /// the exact same product grid, filters, and product-tap navigation as
  /// every other product list.
  factory ProductListArgs.image({required XFile image}) {
    return ProductListArgs(
      key: keyImage,
      value: image,
      title: 'Results for your photo',
    );
  }

  bool get isShop => key == keyShop;

  bool get isSearch => key == keySearch;

  bool get isImage => key == keyImage;

  //new // <-- UPDATED: Safely parse value to prevent type cast crashes when routing
  int get shopId {
    if (value is int) return value as int;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
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

  final Set<String> _wishlistIds = {};

  /// Product IDs whose wishlist request is currently being processed.
  final Set<String> _wishlistUpdatingIds = {};


 // -------------------------------------------------------------------------
  // SEARCH
  // -------------------------------------------------------------------------

 /* final TextEditingController _searchController = TextEditingController();
 final FocusNode _searchFocusNode = FocusNode();

  bool _searchExpanded = false;

  final LayerLink _searchLayerLink = LayerLink();

  final OverlayPortalController _searchOverlayController =
      OverlayPortalController();

  Timer? _debounce;

  List<SearchSuggestion> _suggestions = [];

  bool _isSuggesting = false;*/
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
    // This converts ALL selected filters (Sizes, Colors, etc.) into API parameters
    final queryParams = _filters.toQueryParams();

    if (widget.args.isShop) {
      return ProductService.getProductsByShop(
        widget.args.shopId,
        filters: queryParams.isNotEmpty ? queryParams : null,
      );
    }

    if (widget.args.isImage) {
      // Visual similarity search isn't filterable by size/color the same
      // way text search is (there's only ever one close match), so the
      // size/color/discount filters simply have nothing to narrow here —
      // no special-casing needed beyond calling the right service method.
      return ProductService.searchByImage(widget.args.value as XFile);
    }

    return ProductService.searchProducts(
      widget.args.value as String,
      filters: queryParams.isNotEmpty ? queryParams : null,
    );
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
          ..addAll(items.map((product) => '${product.id}_${product.productColorId ?? 0}'));
      });
    } catch (_) {
      // Silent — hearts simply remain unfilled if loading fails.
    }
  }

  // =========================================================================
  // WISHLIST TOGGLE
  // =========================================================================

Future<void> _toggleWishlist(ProductModel product) async {
    if (!_isLoggedIn) {
      _goToProtected(
        context,
        GoRouterState.of(context).uri.toString(),
      );
      return;
    }

    final key = '${product.id}_${product.productColorId ?? 0}';

    // Prevent duplicate requests for the same product.
    if (_wishlistUpdatingIds.contains(key)) {
      return;
    }

    final wasWishlisted = _wishlistIds.contains(key);

    // Optimistic UI update.
    setState(() {
      _wishlistUpdatingIds.add(key);

      if (wasWishlisted) {
        _wishlistIds.remove(key);
      } else {
        _wishlistIds.add(key);
      }
    });

    bool ok;

    try {
      ok = wasWishlisted
          ? await WishlistService.removeFromWishlist(product.id, productColorId: product.productColorId)
          : await WishlistService.addToWishlist(product.id, productColorId: product.productColorId);
    } catch (_) {
      ok = false;
    }

    if (!mounted) return;

    setState(() {
      _wishlistUpdatingIds.remove(key);

      // Roll back optimistic update if API failed.
      if (!ok) {
        if (wasWishlisted) {
          _wishlistIds.add(key);
        } else {
          _wishlistIds.remove(key);
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
      // Check if ANY filter was changed
      final needsRefetch = _filters != result;

      setState(() {
        _filters = result;
      });

      if (needsRefetch) {
        _loadProducts();
      }
    }
  }

  void _applyDesktopFilters(ProductFilters filters) {
    if (!mounted) return;

    final needsRefetch = _filters != filters;

    setState(() {
      _filters = filters;
    });

    if (needsRefetch) {
      _loadProducts();
    }
  }

  void _clearFilters() {
    if (!mounted) return;

    const cleared = ProductFilters();
    final needsRefetch = _filters != cleared;

    setState(() {
      _filters = cleared;
    });

    if (needsRefetch) {
      _loadProducts();
    }
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

    if (widget.args.isImage) {
      return "We couldn't find products that closely match this photo.";
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
                : widget.args.isImage
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
             delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = _products[index];

                  final key = '${product.id}_${product.productColorId ?? 0}';
                  final isUpdating = _wishlistUpdatingIds.contains(key);

                  // 1. Determine the best color to pass based on active filters
                  String? filterColor;
                  final selectedColors = _filters.selectedFilters['Color'];
                  if (selectedColors != null && selectedColors.isNotEmpty) {
                    final productColors = product.colors.map((c) => c.trim().toLowerCase()).toSet();
                    for (final c in selectedColors) {
                      if (productColors.contains(c.trim().toLowerCase())) {
                        filterColor = c;
                        break;
                      }
                    }
                  }

                  return ProductCard(
                    key: ValueKey('product_$key'),
                    product: product,
                    // 2. Pass the matching color so the card can display the correct variant thumbnail
                    color: filterColor, 
                    isWishlisted: _wishlistIds.contains(key),
                    isWishlistUpdating: isUpdating,
                    onWishlistTap: isUpdating
                        ? null
                        : () => _toggleWishlist(product),
                    onTap: () => _openProduct(product),
                  );
                },
                childCount: _products.length,
              ),
            ),
          );
        },
      ),
    ];
  }
}
