import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
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

  /// Text shown in the header — shop name, or `Results for "query"`.
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

  /// Shop id, only valid when [isShop] is true.
  int get shopId => value as int;
}

// ===========================================================================
// SCREEN
// ===========================================================================

/// Single reusable listing screen — driven entirely by ProductModel /
/// ProductService. Every clickable entry point on Home (nearby shop
/// card, search bar) routes here with a [ProductListArgs]; this screen
/// decides which API to call and applies [ProductFilters] on top.
///
/// Responsive behaviour:
/// - Width >= [_desktopBreakpoint] → "desktop": a top bar with a back
///   button, the title (shop name / search query), and — only for shop
///   lists — an "Overview" button on the right. Products render in a
///   grid on the LEFT with the filter form ([FilterPanel]) permanently
///   visible as a sidebar on the RIGHT. Changing a filter and tapping
///   Apply just re-runs the fetch, no navigation involved.
/// - Below that → "mobile": a compact header — back button, title,
///   a search icon, and a bag/cart icon. The filter/overview toolbar
///   row ("Filters" on the left, "Overview" — shop only — on the
///   right) now scrolls WITH the page content instead of being pinned
///   under the header. Tapping the search icon expands an inline
///   search field in place of the title/icons. Tapping "Filters"
///   pushes [FilterPage] as its own full screen route and applies
///   whatever comes back.
///
/// Wishlist: tapping the heart on a card checks login state first. A
/// guest gets sent straight to `/login` — nothing is written until
/// they're actually signed in. A logged-in tap flips the heart
/// optimistically and calls [ProductService.addToWishlist] /
/// [ProductService.removeFromWishlist], rolling the heart back if the
/// API call fails.
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

  List<ProductModel> _products = [];
  bool _isLoading = true;
  String? _error;

  ProductFilters _filters = const ProductFilters();

  final Set<int> _wishlistIds = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  /// Mobile only — whether the header is showing the inline search field
  /// in place of the title/search-icon/cart-icon row.
  bool _searchExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.args.isSearch) {
      _searchController.text = widget.args.value as String;
    }
    _loadProducts();
    _loadWishlistIds();
  }

  @override
  void dispose() {
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

  /// Only place that decides which service call to make. If your real
  /// method names/signatures differ, this is the one spot to edit.
  Future<List<ProductModel>> _fetchProducts() {
    final queryParams = _filters.toQueryParams();
    if (widget.args.isShop) {
      return ProductService.getProductsByShop(
        widget.args.shopId,
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
    if (!_isLoggedIn) return; // guest — hearts stay unfilled

    try {
      final items = await ProductService.getWishlist();
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

  /// Login gate lives here: guests are routed to `/login` and nothing
  /// is written. Logged-in users get an optimistic heart flip + the
  /// actual API call, rolled back if that call fails.
  Future<void> _toggleWishlist(ProductModel product) async {
    if (!_isLoggedIn) {
      // Not logged in — send them to login instead of writing anything.
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
          ? await ProductService.removeFromWishlist(product.id)
          : await ProductService.addToWishlist(product.id);
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

  /// Only relevant when we got here via a shop (widget.args.isShop).
  void _openShopOverview() {
    context.push('/shops/${widget.args.shopId}');
  }

  void _openCart() {
    _goToProtected(context, '/cart');
  }

  /// New search from the mobile header's search field — replaces this
  /// screen with a fresh ProductListScreen for the new query so the
  /// back stack still makes sense (Home -> this new search result).
  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) return;

    final uri = Uri(path: '/products', queryParameters: {'search': trimmed});

    context.pushReplacement(uri.toString());
  }

  void _openInlineSearch() {
    setState(() => _searchExpanded = true);
    // Give the field a frame to build before requesting focus.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeInlineSearch() {
    setState(() => _searchExpanded = false);
    _searchFocusNode.unfocus();
  }

  /// Mobile: pushes the filter form as its own full page and applies
  /// whatever comes back.
  Future<void> _openFilterPage() async {
    final result = await context.push<ProductFilters>(
      '/filter',
      extra: _filters,
    );

    if (result != null) {
      setState(() => _filters = result);
      _loadProducts();
    }
  }

  /// Desktop: sidebar's Apply just updates state in place — no route.
  void _applyDesktopFilters(ProductFilters filters) {
    setState(() => _filters = filters);
    _loadProducts();
  }

  // Checks login state before navigating to a protected route.
  // If not logged in, redirects to /login and passes the intended
  // destination so the login flow can send the user back afterwards.
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
    if (widget.args.isSearch) {
      return 'No products found for "${widget.args.value}".';
    }
    return 'No products in this shop yet.';
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
  // DESKTOP — back button + title (+ Overview for shop lists) top
  // bar, then left grid / right filter sidebar
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
                  onApply: _applyDesktopFilters,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Back button + title (shop name / search query) on the left,
  /// "Overview" button on the right — only shown when this list came
  /// from a shop.
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
  // MOBILE — back+name+search-icon+cart header. Filter/Overview
  // toolbar now scrolls WITH the product grid instead of being
  // pinned under the header.
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

  /// Back button, screen name, a search icon, and a bag icon — all in
  /// one row. Tapping the search icon swaps the title/icons for an
  /// inline, auto-focused search field (with a close icon to collapse
  /// back to the normal header).
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
              onSubmitted: _onSearchSubmitted,
              style: const TextStyle(fontSize: 14, color: _ink),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Colors.black45,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.black45,
                        ),
                        onPressed: () {
                          setState(() => _searchController.clear());
                        },
                      ),
                hintText: 'Search products',
                hintStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ],
    );
  }

  /// Slim strip — "Filters" trigger on the left, "Overview" (shop
  /// lists only) on the right. Now placed as the first sliver in the
  /// scroll view, so it scrolls away with the rest of the page
  /// content instead of staying pinned under the header. Tapping
  /// Filters pushes [FilterPage].
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

  /// Column count adapts to width: 2 on phones, scales up as the
  /// available grid width grows (desktop already loses 340px to the
  /// sidebar, so this reads the ACTUAL remaining width, not the full
  /// screen width).
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