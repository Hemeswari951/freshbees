import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/product_service.dart';
import '../../services/search_service.dart';
import '../../widgets/product_card.dart';
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

  const ProductListArgs({
    required this.key,
    required this.value,
    required this.title,
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
/// - `_products` (getter) = `_allProducts` run through `_filters.matches()`.
/// - Applying filters never re-fetches — just updates `_filters` and the
///   grid rebuilds instantly against the already-fetched list.
/// - `_availableSizes` / `_availableColors` = distinct values pulled from
///   the backend (ProductService.getFilterOptions()) so the filter panel
///   never shows a hardcoded list that's out of sync with real data.
class ProductListScreen extends StatefulWidget {
  final ProductListArgs args;

  const ProductListScreen({super.key, required this.args});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  static const double _desktopBreakpoint = 900;
  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _ink = Color(0xFF1F1B16);

  List<ProductModel> _allProducts = [];
  bool _isLoading = true;
  String? _error;

  ProductFilters _filters = const ProductFilters();

  List<String> _availableSizes = [];
  List<String> _availableColors = [];

  List<ProductModel> get _products =>
      _allProducts.where(_filters.matches).toList();

  final Set<int> _wishlistIds = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _searchExpanded = false;

  final LayerLink _searchLayerLink = LayerLink();
  final OverlayPortalController _searchOverlayController =
      OverlayPortalController();
  Timer? _debounce;
  List<SearchSuggestion> _suggestions = [];
  bool _isSuggesting = false;

  @override
  void initState() {
    super.initState();
    if (widget.args.isSearch) {
      _searchController.text = widget.args.value as String;
    }
    _loadProducts();
    _loadWishlistIds();
    _loadFilterOptions();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktopBreakpoint;

  bool get _isLoggedIn {
    final token = ApiService.getToken();
    return token != null && token.isNotEmpty;
  }

  // ===========================================================
  // DATA
  // ===========================================================

  Future<List<ProductModel>> _fetchProducts() {
    if (widget.args.isShop) {
      return ProductService.getProductsByShop(widget.args.shopId);
    }
    return ProductService.searchProducts(widget.args.value as String);
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
        _allProducts = products;
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

  /// Distinct sizes/colors currently in the catalog, for the filter
  /// panel's Size/Color lists. Failure is silent — those two filter
  /// groups just show "No sizes/colors available" instead of breaking
  /// the screen.
  Future<void> _loadFilterOptions() async {
    final options = await ProductService.getFilterOptions();
    if (!mounted) return;
    setState(() {
      _availableSizes = options.sizes;
      _availableColors = options.colors;
    });
  }

  Future<void> _loadWishlistIds() async {
    if (!_isLoggedIn) return;

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
    if (!_isLoggedIn) {
      context.push('/login');
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

  // ===========================================================
  // NAVIGATION
  // ===========================================================

  void _openProduct(ProductModel product) {
    context.push('/products/${product.id}');
  }

  void _openShopOverview() {
    context.push('/shops/${widget.args.shopId}');
  }

  void _openCart() {
    _goToProtected(context, '/cart');
  }

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri(path: '/products', queryParameters: {'search': trimmed});
    context.pushReplacement(uri.toString());
  }

  void _openInlineSearch() {
    setState(() => _searchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeInlineSearch() {
    _searchOverlayController.hide();
    setState(() => _searchExpanded = false);
    _searchFocusNode.unfocus();
  }

  /// Mobile: pushes the filter page with the CURRENT filters, the
  /// already-fetched base list (for the live "N of M products" count),
  /// and the backend-driven size/color option lists.
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

    if (result != null) {
      setState(() => _filters = result);
    }
  }

  /// Desktop: sidebar's Apply just updates state in place — no route,
  /// no refetch.
  void _applyDesktopFilters(ProductFilters filters) {
    setState(() => _filters = filters);
  }

  void _clearFilters() {
    setState(() => _filters = const ProductFilters());
  }

  void _goToProtected(BuildContext context, String route) {
    final isLoggedIn =
        ApiService.getToken() != null && ApiService.getToken()!.isNotEmpty;

    if (isLoggedIn) {
      context.go(route);
    } else {
      context.go(
        Uri(path: '/login', queryParameters: {'redirect': route}).toString(),
      );
    }
  }

  String get _emptyMessage {
    if (_filters.activeCount > 0) {
      return 'No products match the selected filters.';
    }
    if (widget.args.isSearch) {
      return 'No products found for "${widget.args.value}".';
    }
    return 'No products in this shop yet.';
  }

  // ===========================================================
  // SEARCH SUGGESTIONS
  // ===========================================================

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isSuggesting = false;
      });
      if (_searchOverlayController.isShowing) {
        _searchOverlayController.hide();
      }
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSuggesting = true);
      try {
        final results = await SearchService.getSearchSuggestions(value);
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _isSuggesting = false;
        });
        if (_suggestions.isNotEmpty && !_searchOverlayController.isShowing) {
          _searchOverlayController.show();
        } else if (_suggestions.isEmpty &&
            _searchOverlayController.isShowing) {
          _searchOverlayController.hide();
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _suggestions = [];
          _isSuggesting = false;
        });
      }
    });
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    _searchController.text = suggestion.text;
    _searchOverlayController.hide();
    _onSearchSubmitted(suggestion.text);
  }

  // ===========================================================
  // BUILD
  // ===========================================================

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

  // ===========================================================
  // DESKTOP
  // ===========================================================

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
                    ..._buildProductSlivers(),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(4, 14, 24, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: _ink),
            onPressed: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: Text(
              widget.args.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
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

  // ===========================================================
  // MOBILE
  // ===========================================================

  Widget _buildMobileScaffold() {
    return Column(
      children: [
        _buildMobileHeader(),
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildMobileFilterToolbar()),
              ..._buildProductSlivers(),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: _searchExpanded ? _buildSearchRow() : _buildTitleRow(),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: _ink),
          onPressed: () => Navigator.maybePop(context),
        ),
        Expanded(
          child: Text(
            widget.args.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.search, color: _ink),
          onPressed: _openInlineSearch,
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: _ink),
          onPressed: _openCart,
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: _ink),
          onPressed: _closeInlineSearch,
        ),
        Expanded(
          child: CompositedTransformTarget(
            link: _searchLayerLink,
            child: OverlayPortal(
              controller: _searchOverlayController,
              overlayChildBuilder: (context) {
                return Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _searchOverlayController.hide(),
                    child: Stack(
                      children: [
                        CompositedTransformFollower(
                          link: _searchLayerLink,
                          showWhenUnlinked: false,
                          offset: const Offset(0, 46),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 56,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 320,
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    itemCount: _suggestions.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Colors.black.withOpacity(0.05),
                                    ),
                                    itemBuilder: (context, index) {
                                      final s = _suggestions[index];
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          s.isTag
                                              ? Icons.sell_outlined
                                              : Icons.search_rounded,
                                          size: 18,
                                          color: const Color(0xFF8B7355),
                                        ),
                                        title: Text(
                                          s.text,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        trailing: s.isTag
                                            ? const Text(
                                                'tag',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black38,
                                                ),
                                              )
                                            : null,
                                        onTap: () => _onSuggestionTap(s),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1ECE3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (q) {
                    _searchOverlayController.hide();
                    _onSearchSubmitted(q);
                  },
                  onChanged: _onSearchChanged,
                  style: const TextStyle(fontSize: 14, color: _ink),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.black45,
                    ),
                    suffixIcon: _isSuggesting
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : (_searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.black45,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _suggestions = [];
                                    });
                                    _searchOverlayController.hide();
                                  },
                                )),
                    hintText: 'Search products',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// "Filters" trigger (with live active-count badge) on the left,
  /// "Overview" (shop lists only) on the right.
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

  // ===========================================================
  // GRID
  // ===========================================================

  int _gridColumnCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    if (width >= 460) return 2;
    return 2;
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

    if (_products.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _emptyMessage,
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

    return [
      SliverLayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _gridColumnCount(constraints.crossAxisExtent);
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = _products[index];
                return ProductCard(
                  product: product,
                  isWishlisted: _wishlistIds.contains(product.id),
                  onWishlistTap: () => _toggleWishlist(product),
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