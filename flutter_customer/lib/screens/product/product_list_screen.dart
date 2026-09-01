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
    return ProductListArgs(
      key: keyShop,
      value: shopId,
      title: shopName,
    );
  }

  factory ProductListArgs.search({
    required String query,
  }) {
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

  // -------------------------------------------------------------------------
  // WISHLIST
  // -------------------------------------------------------------------------

  final Set<int> _wishlistIds = {};

  /// Product IDs whose wishlist request is currently being processed.
  ///
  /// This prevents rapid multiple clicks from sending duplicate API
  /// requests for the same product.
  final Set<int> _wishlistUpdatingIds = {};

  // -------------------------------------------------------------------------
  // SEARCH
  // -------------------------------------------------------------------------

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  bool _searchExpanded = false;

  final LayerLink _searchLayerLink = LayerLink();

  final OverlayPortalController _searchOverlayController =
      OverlayPortalController();

  Timer? _debounce;

  List<SearchSuggestion> _suggestions = [];

  bool _isSuggesting = false;

  // =========================================================================
  // LIFECYCLE
  // =========================================================================

  @override
  void initState() {
    super.initState();

    if (widget.args.isSearch) {
      _searchController.text = widget.args.value as String;
    }

    _loadProducts();
    _loadWishlistIds();
    _loadFilterOptions();

    // Came here via ProductViewScreen's search icon.
    if (widget.autoFocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (!_isDesktop(context)) {
          _openInlineSearch();
        }
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();

    if (_searchOverlayController.isShowing) {
      _searchOverlayController.hide();
    }

    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
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

    return ProductService.searchProducts(
      widget.args.value as String,
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
          ..addAll(items.map((product) => product.id));
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

    final productId = product.id;

    // Prevent duplicate requests for the same product.
    if (_wishlistUpdatingIds.contains(productId)) {
      return;
    }

    final wasWishlisted = _wishlistIds.contains(productId);

    // Optimistic UI update.
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

      // Roll back optimistic update if API failed.
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
  // SEARCH
  // =========================================================================

  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) return;

    _searchFocusNode.unfocus();
    _searchOverlayController.hide();

    setState(() {
      _searchExpanded = false;
    });

    final uri = Uri(
      path: '/products',
      queryParameters: {
        'search': trimmed,
      },
    );

    context.go(uri.toString());
  }

  void _openInlineSearch() {
    setState(() {
      _searchExpanded = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _searchFocusNode.requestFocus();
    });
  }

  void _closeInlineSearch() {
    _searchOverlayController.hide();

    setState(() {
      _searchExpanded = false;
    });

    _searchFocusNode.unfocus();
  }

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
        Uri(
          path: '/login',
          queryParameters: {
            'redirect': route,
          },
        ).toString(),
      );
    }
  }

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
      return 'No products found for "${widget.args.value}".';
    }

    return 'No products in this shop yet.';
  }

  // =========================================================================
  // SEARCH SUGGESTIONS
  // =========================================================================

  void _onSearchChanged(String value) {
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

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () async {
        if (!mounted) return;

        setState(() {
          _isSuggesting = true;
        });

        try {
          final results =
              await SearchService.getSearchSuggestions(value);

          if (!mounted) return;

          setState(() {
            _suggestions = results;
            _isSuggesting = false;
          });

          if (_suggestions.isNotEmpty &&
              !_searchOverlayController.isShowing) {
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
      },
    );
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    _searchController.text = suggestion.text;

    _searchOverlayController.hide();

    _onSearchSubmitted(suggestion.text);
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
        child: isDesktop
            ? _buildDesktopScaffold()
            : _buildMobileScaffold(),
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
                    ..._buildProductSlivers(
                      isDesktopLayout: true,
                    ),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 24),
                    ),
                  ],
                ),
              ),

              Container(
                width: 340,
                margin: const EdgeInsets.fromLTRB(
                  0,
                  16,
                  24,
                  16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black12,
                  ),
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

  Widget _buildDesktopTopBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        4,
        14,
        24,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _desktopBreadcrumb(),
          ),

          if (widget.args.isShop)
            OutlinedButton.icon(
              onPressed: _openShopOverview,
              icon: const Icon(
                Icons.storefront_outlined,
                size: 16,
              ),
              label: const Text('Overview'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: const BorderSide(
                  color: Colors.black26,
                ),
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

  Widget _desktopBreadcrumb() {
    TextStyle crumbStyle({
      bool active = false,
    }) {
      return TextStyle(
        fontSize: 15,
        fontWeight:
            active ? FontWeight.w700 : FontWeight.w500,
        color: active
            ? _ink
            : _ink.withOpacity(0.5),
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Text(
            'Home',
            style: crumbStyle(),
          ),
        ),

        Text(
          '  /  ',
          style: crumbStyle(),
        ),

        Expanded(
          child: Text(
            widget.args.isShop
                ? widget.args.title
                : 'Search Results for "${widget.args.value}"',
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
        _buildMobileHeader(),

        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildMobileFilterToolbar(),
              ),

              ..._buildProductSlivers(
                isDesktopLayout: false,
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(
        4,
        8,
        12,
        8,
      ),
      child: _searchExpanded
          ? _buildSearchRow()
          : _buildTitleRow(),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _ink,
          ),
          onPressed: () => _goBack(context),
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
          icon: const Icon(
            Icons.search,
            color: _ink,
          ),
          onPressed: _openInlineSearch,
        ),

        IconButton(
          icon: const Icon(
            Icons.shopping_cart_outlined,
            color: _ink,
          ),
          onPressed: _openCart,
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: _ink,
          ),
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
                    behavior:
                        HitTestBehavior.translucent,
                    onTap: () {
                      _searchOverlayController.hide();
                    },
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
                              borderRadius:
                                  BorderRadius.circular(14),
                              color: Colors.white,
                              child: SizedBox(
                                width:
                                    MediaQuery.of(context)
                                            .size
                                            .width -
                                        56,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(
                                    maxHeight: 320,
                                  ),
                                  child:
                                      ListView.separated(
                                    shrinkWrap: true,
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      vertical: 6,
                                    ),
                                    itemCount:
                                        _suggestions.length,
                                    separatorBuilder:
                                        (_, __) =>
                                            Divider(
                                      height: 1,
                                      color: Colors.black
                                          .withOpacity(0.05),
                                    ),
                                    itemBuilder:
                                        (context, index) {
                                      final suggestion =
                                          _suggestions[index];

                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          suggestion.isTag
                                              ? Icons
                                                  .sell_outlined
                                              : Icons
                                                  .search_rounded,
                                          size: 18,
                                          color:
                                              const Color(
                                            0xFF8B7355,
                                          ),
                                        ),
                                        title: Text(
                                          suggestion.text,
                                          style:
                                              const TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                FontWeight.w500,
                                          ),
                                        ),
                                        trailing:
                                            suggestion.isTag
                                                ? const Text(
                                                    'tag',
                                                    style:
                                                        TextStyle(
                                                      fontSize:
                                                          11,
                                                      color:
                                                          Colors
                                                              .black38,
                                                    ),
                                                  )
                                                : null,
                                        onTap: () =>
                                            _onSuggestionTap(
                                          suggestion,
                                        ),
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
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textInputAction:
                      TextInputAction.search,
                  onSubmitted: (query) {
                    _searchOverlayController.hide();
                    _onSearchSubmitted(query);
                  },
                  onChanged: _onSearchChanged,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _ink,
                  ),
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
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : (_searchController
                                .text
                                .isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.black45,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController
                                        .clear();
                                    _suggestions = [];
                                  });

                                  _searchOverlayController
                                      .hide();
                                },
                              )),
                    hintText: 'Search products',
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.black45,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
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
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        16,
        10,
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _openFilterPage,
            icon: Badge(
              isLabelVisible: count > 0,
              label: Text('$count'),
              child: const Icon(
                Icons.tune,
                size: 18,
              ),
            ),
            label: const Text('Filters'),
            style: TextButton.styleFrom(
              foregroundColor: _ink,
            ),
          ),

          const Spacer(),

          if (widget.args.isShop)
            TextButton.icon(
              onPressed: _openShopOverview,
              icon: const Icon(
                Icons.storefront_outlined,
                size: 16,
              ),
              label: const Text('Overview'),
              style: TextButton.styleFrom(
                foregroundColor: _ink,
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // GRID
  // =========================================================================

  int _gridColumnCount(double width) {
    if (width >= 1000) return 4;
    if (width >= 700) return 3;
    if (width >= 460) return 2;

    return 2;
  }

  List<Widget> _buildProductSlivers({
    required bool isDesktopLayout,
  }) {
    if (_isLoading) {
      return const [
        SliverFillRemaining(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }

    if (_error != null) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
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
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),

                if (_filters.activeCount > 0) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      'Clear filters',
                    ),
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
          final crossAxisCount =
              _gridColumnCount(
            constraints.crossAxisExtent,
          );

          return SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              isDesktopLayout ? 16 : 8,
              16,
              8,
            ),
            sliver: SliverGrid(
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.62,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = _products[index];

                  final isUpdating =
                      _wishlistUpdatingIds
                          .contains(product.id);

                  return ProductCard(
                    // IMPORTANT:
                    // Stable key prevents Flutter from incorrectly
                    // reusing a hovered card for another product when
                    // the wishlist state changes.
                    key: ValueKey(
                      'product_${product.id}',
                    ),

                    product: product,

                    isWishlisted:
                        _wishlistIds.contains(
                      product.id,
                    ),

                    isWishlistUpdating:
                        isUpdating,

                    onWishlistTap:
                        isUpdating
                            ? null
                            : () =>
                                _toggleWishlist(product),

                    onTap: () =>
                        _openProduct(product),
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