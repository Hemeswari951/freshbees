import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_colors.dart';
import '../../services/product_service.dart';
import '../../services/search_service.dart';
import '../../models/product_details_model.dart';
import '../../services/api_service.dart';
import '../../services/cart_service.dart';
import '../../services/wishlist_service.dart';
import '../cart/cart_screen.dart';
import '../../widgets/reviews_section.dart';
import '../../models/review_model.dart';

class ProductViewScreen extends StatefulWidget {
  final int productId;
  final int? shopId;
  final String? shopName;
  final String? searchQuery;

  const ProductViewScreen({
    super.key,
    required this.productId,
    this.shopId,
    this.shopName,
    this.searchQuery,
  });

  @override
  State<ProductViewScreen> createState() => _ProductViewScreenState();
}

class _ProductViewScreenState extends State<ProductViewScreen> {
  // Header breakpoint — desktop gets the breadcrumb, mobile gets the
  // back/search/cart bar. Separate from the 640px breakpoint below
  // (that one is only about gallery/details layout, not the header).
  static const double _desktopHeaderBreakpoint = 900;

  ProductDetailsModel? _product;
  ReviewSummaryModel? _liveSummary;
  bool _loading = true;
  String? _error;
  bool _addingToBag = false;
  bool _buyingNow = false;

  // Wishlist heart state for THIS product — separate from the list-screen
  // pattern (which tracks a Set<int> of many products) since this screen
  // only ever cares about one product.
  bool _isWishlisted = false;

  int _activeColorIndex = 0;
  int _selectedIndex = 0; // index within _galleryItems

  // Which size is currently SELECTED — defaults to the FIRST size of
  // whichever color is active, exactly like the color swatch above it
  // defaults to the first color. Null only ever happens transiently
  // (e.g. a color with zero sizes) — see _defaultSizeSelection().
  int? _selectedSizeIndex;

  late final PageController _pageController;

  // ── Inline mobile search — same pattern as product_list_screen.dart's
  // search bar, so tapping the search field here behaves identically:
  // shows a live suggestion dropdown, and only navigates away once the
  // user actually submits a query.
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchExpanded = false;
  final LayerLink _searchLayerLink = LayerLink();
  final OverlayPortalController _searchOverlayController =
      OverlayPortalController();
  Timer? _searchDebounce;
  List<SearchSuggestion> _suggestions = [];
  bool _isSuggesting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktopHeaderBreakpoint;

  bool get _isLoggedIn {
    final token = ApiService.getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final product = await ProductService.getProductDetails(widget.productId);
      setState(() {
        _product = product;
        _loading = false;
      });
      // Once data is in, default-select size 0 for whatever color is
      // currently active — same idea as the color swatch defaulting to
      // index 0 on first load.
      _defaultSizeSelection();
      _checkWishlistStatus();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // Guests don't have a wishlist — heart just stays unfilled for them.
  Future<void> _checkWishlistStatus() async {
    if (!_isLoggedIn) return;
    try {
      final items = await WishlistService.getWishlist();
      if (!mounted) return;
      setState(() {
        _isWishlisted = items.any((p) => p.id == widget.productId);
      });
    } catch (_) {
      // Silent — heart simply defaults to unfilled if this fails.
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // Same helper used across the other modules — gates a protected
  // route behind login. If logged in, pushes straight there. If not,
  // pushes to /login with `route` as the redirect target, so login
  // sends the user back to exactly where they were headed.
  // ──────────────────────────────────────────────────────────────────
  void _goToProtected(BuildContext context, String route) {
    if (_isLoggedIn) {
      context.push(route);
    } else {
      context.push(
        Uri(path: '/login', queryParameters: {'redirect': route}).toString(),
      );
    }
  }

  // Safe go_router back — used by the mobile header's back button and
  // the desktop breadcrumb's shop-fallback tap. context.canPop() checks
  // GoRouter's own stack (not the raw Navigator), so this correctly
  // detects the "arrived here via a redirect/deep-link with nothing
  // behind it" case and falls back to Home instead of doing nothing.
  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _openCart() {
    _goToProtected(context, '/cart');
  }

  Future<void> _toggleWishlist() async {
    if (!_isLoggedIn) {
      _goToProtected(
        context,
        Uri(
          path: '/products/${widget.productId}',
          queryParameters: {
            if (widget.shopId != null) 'shopId': widget.shopId.toString(),
            if (widget.shopName != null) 'shopName': widget.shopName!,
          },
        ).toString(),
      );
      return;
    }

    final wasWishlisted = _isWishlisted;

    // Optimistic UI update, reconciled with the backend call below.
    setState(() => _isWishlisted = !wasWishlisted);

    bool ok;
    try {
      ok = wasWishlisted
          ? await WishlistService.removeFromWishlist(widget.productId)
          : await WishlistService.addToWishlist(widget.productId);
    } catch (_) {
      ok = false;
    }

    // Roll back on failure so the heart doesn't lie about what's saved.
    if (!ok && mounted) {
      setState(() => _isWishlisted = wasWishlisted);
    }
  }

  // Selects the first size for the active color, if one exists.
  // Called on initial load and every time the active color changes.
  void _defaultSizeSelection() {
    final variants = _activeVariants;
    setState(() => _selectedSizeIndex = variants.isNotEmpty ? 0 : null);
  }

  List<ProductColorModel> get _colors => _product?.colors ?? [];

  ProductColorModel? get _activeColor => _colors.isNotEmpty
      ? _colors[_activeColorIndex.clamp(0, _colors.length - 1)]
      : null;

  List<ProductImageModel> get _activeImages => _activeColor?.images ?? [];

  List<ProductVariantModel> get _activeVariants => _activeColor?.variants ?? [];

  // The variant the admin has currently SELECTED by tapping a size chip
  // (or the auto-selected default — see _defaultSizeSelection).
  ProductVariantModel? get _selectedVariant {
    if (_selectedSizeIndex == null) return null;
    final variants = _activeVariants;
    if (_selectedSizeIndex! < 0 || _selectedSizeIndex! >= variants.length) {
      return null;
    }
    return variants[_selectedSizeIndex!];
  }

  // ── Product specifications — everything captured on Add Product that
  // isn't already shown elsewhere on this page. SKU is intentionally
  // NOT included (internal detail, not something a customer needs to
  // see on the product page).
  List<MapEntry<String, String>> get _specifications {
    final p = _product!;

    final entries = <MapEntry<String, String>>[];
    void add(String label, dynamic value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        entries.add(MapEntry(label, value.toString()));
      }
    }

    add('Fabric', p.fabric);
    add('Pattern', p.pattern);
    add('Fit', p.fitType);
    add('Sleeve', p.sleeveType);
    add('Neck', p.neckType);
    add('Occasion', p.occasion);
    add('Brand', p.brandName);
    add('Sub-category', p.subCategory);
    add('Wash care', p.washCare);
    add('Country of origin', p.countryOfOrigin);
    return entries;
  }

  List<ProductTagModel> get _tags => _product?.tags ?? [];

  List<ProductAttributeModel> get _extraAttributes =>
      _product?.attributes ?? [];

  /// Builds the gallery sequence for the active color: photos in order,
  /// with any group of images tagged type: '360' collapsed into ONE spin
  /// item, inserted right where the first 360-frame appears — so it sits
  /// in the list like any other photo, just interactive.
  List<_GalleryItem> get _galleryItems {
    final items = <_GalleryItem>[];
    List<String>? spinList;
    for (final img in _activeImages) {
      final type = img.imageType;
      final url = img.imageUrl;

      if (type == '360') {
        spinList ??= <String>[];
        if (spinList.isEmpty) {
          items.add(_GalleryItem.spin(spinList));
        }
        spinList.add(url);
      } else {
        items.add(_GalleryItem.photo(url));
      }
    }
    // Needs 2+ frames to actually spin — drop it otherwise.
    items.removeWhere(
      (it) => it.kind == _GalleryKind.spin && (it.spinUrls?.length ?? 0) < 2,
    );
    return items;
  }

  /// First photo for a given color entry — used as that color's "swatch".
  /// Prefers a normal photo over a 360 frame.
  String? _colorCoverUrl(ProductColorModel color) {
    final images = color.images;

    if (images.isEmpty) return null;

    final nonSpin = images.firstWhere(
      (img) => img.imageType != '360',
      orElse: () => images.first,
    );

    return nonSpin.imageUrl;
  }

  void _selectColor(int index) {
    setState(() {
      _activeColorIndex = index;
      _selectedIndex = 0;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    // New color -> new set of sizes -> default to its first size, same
    // way switching colors doesn't leave the size picker on a stale pick.
    _defaultSizeSelection();
  }

  // Tapping a size chip SELECTS it — exactly like a customer choosing a
  // size. Unlike a customer page there's always a default, so tapping the
  // already-selected size just keeps it selected.
  void _onSizeTap(int index) {
    setState(() => _selectedSizeIndex = index);
  }

  /// Shared guest/size checks for both "Add to Cart" and "Buy Now" —
  /// returns false (and redirects to login via _goToProtected, or shows
  /// the size-required message) if the flow shouldn't proceed.
  bool _passesPreChecks() {
    if (!_isLoggedIn) {
      _goToProtected(
        context,
        Uri(
          path: '/products/${widget.productId}',
          queryParameters: {
            if (widget.shopId != null) 'shopId': widget.shopId.toString(),
            if (widget.shopName != null) 'shopName': widget.shopName!,
          },
        ).toString(),
      );
      return false;
    }

    if (_activeVariants.isNotEmpty && _selectedVariant == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a size')));
      return false;
    }

    return true;
  }

  Future<void> _handleAddToBag() async {
    if (!_passesPreChecks()) return;

    setState(() => _addingToBag = true);

    try {
      await CartService.addToCart(
        productId: widget.productId,
        variantId: _selectedVariant?.variantId,
        quantity: 1,
      );

      if (!mounted) return;

      // 1. Capture the messenger locally so it works even if you navigate away
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: const Text('Added to Cart'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              scaffoldMessenger.hideCurrentSnackBar();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ),
      );

      // 2. Force the SnackBar to close after 3 seconds, bypassing the mouse-hover pause
      Future.delayed(const Duration(seconds: 3), () {
        scaffoldMessenger.hideCurrentSnackBar();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _addingToBag = false);
      }
    }
  }

  /// "Buy Now" — adds the selected item to the cart (same as Add to Cart)
  /// then jumps straight to checkout instead of staying on this page.
  /// TODO: swap CartScreen for your actual checkout screen/route once
  /// that exists — this currently opens the cart as the next step.
  Future<void> _handleBuyNow() async {
    if (!_passesPreChecks()) return;

    setState(() => _buyingNow = true);

    try {
      await CartService.addToCart(
        productId: widget.productId,
        variantId: _selectedVariant?.variantId,
        quantity: 1,
      );

      if (!mounted) return;

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const CartScreen()));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _buyingNow = false);
      }
    }
  }

  // ── Inline search — mirrors product_list_screen.dart exactly, so the
  // suggestion dropdown behaves identically wherever the user opens it.
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

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();

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

    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
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
        } else if (_suggestions.isEmpty && _searchOverlayController.isShowing) {
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

  // Only THIS actually navigates away — pressing enter / submitting a
  // real query. Typing itself just shows suggestions in place.
  void _onSearchSubmitted(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _searchFocusNode.unfocus();
    _searchOverlayController.hide();
    setState(() => _searchExpanded = false);

    final uri = Uri(path: '/products', queryParameters: {'search': trimmed});
    context.push(uri.toString());
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    _searchController.text = suggestion.text;
    _searchOverlayController.hide();
    _onSearchSubmitted(suggestion.text);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.ink.withOpacity(0.7)),
                ),
                const SizedBox(height: 12),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final product = _product!;
    final isDesktop = _isDesktop(context);

    // Base product price/mrp/discount.
    double price = product.price;
    double? mrp = product.mrp;
    int discountPercent = product.discountPercent;

    // The selected size (default = first size) may carry its own
    // effective price/mrp — see Approach 1 in the backend. When present,
    // it overrides the base price shown, same as tapping a size on a
    // real customer product page can change the shown price.
    final selected = _selectedVariant;
    if (selected != null) {
      if (selected.price != null) {
        price = selected.price!;
      }

      if (selected.mrp != null) {
        mrp = selected.mrp!;
      }
    }

    final items = _galleryItems;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2), // Matches the thiraa app theme
      // Desktop gets no AppBar at all — just the breadcrumb row inside
      // the body below. Mobile gets the back/search/cart bar.
      appBar: isDesktop
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: _mobileHeader(),
            ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop) ...[
                  _desktopBreadcrumb(product),
                  const SizedBox(height: 16),
                ],
                LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 640;
                    final gallery = wide
                        ? _desktopGallery(items)
                        : _mobileGallery(items);
                    final details = _detailsSection(
                      price,
                      mrp,
                      discountPercent,
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 380, child: gallery),
                          const SizedBox(width: 32),
                          Expanded(child: details),
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [gallery, const SizedBox(height: 24), details],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      // --- PROFESSIONAL STICKY BOTTOM BAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_addingToBag || _buyingNow)
                      ? null
                      : _handleAddToBag,
                  icon: _addingToBag
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.ink,
                          size: 20,
                        ),
                  label: Text(
                    _addingToBag ? 'ADDING...' : 'ADD TO CART',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppColors.ink.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_addingToBag || _buyingNow)
                      ? null
                      : _handleBuyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _buyingNow
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'BUY NOW',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mobile header: swaps between title-row (back / search-bar /
  // cart) and search-row (back-to-close / live textfield + suggestion
  // dropdown), exactly like product_list_screen.dart's header.
  Widget _mobileHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: SafeArea(
        bottom: false,
        child: _searchExpanded ? _buildSearchRow() : _buildTitleRow(),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => _goBack(context),
        ),
        Expanded(
          child: GestureDetector(
            onTap: _openInlineSearch,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1ECE3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: Colors.black45),
                  const SizedBox(width: 8),
                  Text(
                    'Search products',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withOpacity(0.45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.ink),
          onPressed: _openCart,
        ),
      ],
    );
  }

  // Live search field + suggestion dropdown — identical structure to
  // product_list_screen.dart's _buildSearchRow, so behaviour matches.
  Widget _buildSearchRow() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
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
                  style: const TextStyle(fontSize: 14, color: AppColors.ink),
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

  // ── Desktop breadcrumb: Home / <Shop> / <Category> — replaces the
  // AppBar entirely on wide screens.
  Widget _desktopBreadcrumb(ProductDetailsModel product) {
    TextStyle crumbStyle({bool active = false}) => TextStyle(
      fontSize: 13,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      color: active ? AppColors.ink : AppColors.ink.withOpacity(0.5),
    );

    final search = widget.searchQuery?.trim();

    // If product was opened from search results
    // If product was opened from search results
    if (search != null && search.isNotEmpty) {
      return Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Text('Home', style: crumbStyle()),
          ),
          Text('  /  ', style: crumbStyle()),
          GestureDetector(
            onTap: () {
              final uri = Uri(
                path: '/products',
                queryParameters: {'search': search},
              );
              context.push(uri.toString());
            },
            child: Text('Search Results for "$search"', style: crumbStyle()),
          ),
          Text('  /  ', style: crumbStyle()),
          Expanded(
            child: Text(
              product.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: crumbStyle(active: true),
            ),
          ),
        ],
      );
    }

    // Direct navigation — no shop, no search (came straight from Home/
    // Wishlist/etc). Just Home / Product name, nothing else.
    if (widget.shopId == null) {
      return Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: Text('Home', style: crumbStyle()),
          ),
          Text('  /  ', style: crumbStyle()),
          Expanded(
            child: Text(
              product.productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: crumbStyle(active: true),
            ),
          ),
        ],
      );
    }

    // Shop navigation — Home / Shop / Category
    final shopLabel = widget.shopName ?? 'Shop';

    final categoryLabel =
        (product.subCategory != null && product.subCategory!.trim().isNotEmpty)
        ? product.subCategory!
        : null;

    return Row(
      children: [
        GestureDetector(
          onTap: () => context.go('/home'),
          child: Text('Home', style: crumbStyle()),
        ),
        Text('  /  ', style: crumbStyle()),
        GestureDetector(
          onTap: () {
            final uri = Uri(
              path: '/products',
              queryParameters: {
                'shopId': widget.shopId.toString(),
                if (widget.shopName != null &&
                    widget.shopName!.trim().isNotEmpty)
                  'shopName': widget.shopName!,
              },
            );
            context.push(uri.toString());
          },
          child: Text(shopLabel, style: crumbStyle()),
        ),
        if (categoryLabel != null) ...[
          Text('  /  ', style: crumbStyle()),
          Text(categoryLabel, style: crumbStyle(active: true)),
        ],
      ],
    );
  }

  // ── Desktop: thumbnails left→right on top, big image below them ──────────
  Widget _desktopGallery(List<_GalleryItem> items) {
    final selected = items.isEmpty
        ? 0
        : _selectedIndex.clamp(0, items.length - 1);
    return Column(
      children: [
        SizedBox(
          height: 64,
          child: items.isEmpty
              ? const SizedBox()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) =>
                      _thumbnail(items[i], i, i == selected),
                ),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: items.isEmpty
                ? _emptyImagePlaceholder()
                : _bigDisplay(items[selected]),
          ),
        ),
      ],
    );
  }

  // ── Mobile: swipeable gallery (next/prev), thumbnail strip underneath ────
  Widget _mobileGallery(List<_GalleryItem> items) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: items.isEmpty
                ? _emptyImagePlaceholder()
                : Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: items.length,
                        onPageChanged: (i) =>
                            setState(() => _selectedIndex = i),
                        itemBuilder: (context, i) => _bigDisplay(items[i]),
                      ),
                      if (items.length > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(items.length, (i) {
                              final active = i == _selectedIndex;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: active ? 16 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.ink
                                      : AppColors.ink.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        if (items.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) =>
                  _thumbnail(items[i], i, i == _selectedIndex),
            ),
          ),
        ],
      ],
    );
  }

  // Plain image thumbnail, no backdrop, no "front/back/360" labels — just
  // the picture, with a soft ring when it's the active one.
  Widget _thumbnail(_GalleryItem item, int index, bool active) {
    final thumbUrl = item.kind == _GalleryKind.spin
        ? item.spinUrls!.first
        : item.url!;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.terracotta.withOpacity(0.45),
                    blurRadius: 0,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          thumbUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: AppColors.blush),
        ),
      ),
    );
  }

  Widget _bigDisplay(_GalleryItem item) {
    if (item.kind == _GalleryKind.spin) {
      return Product360AutoViewer(imageUrls: item.spinUrls!);
    }
    return _ZoomableNetworkImage(imageUrl: item.url!);
  }

  Widget _emptyImagePlaceholder() => Container(
    color: AppColors.blush,
    alignment: Alignment.center,
    child: const Icon(Icons.checkroom, size: 56, color: AppColors.inkSoft),
  );

  // ── Details column ────────────────────────────────────────────────────
  Widget _detailsSection(double price, double? mrp, int discountPercent) {
    final product = _product!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name — bold, dark, tighter than before (Myntra-style brand/name line)
        // + wishlist heart, right-aligned on the same line.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.productName,
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.25,
                ),
              ),
            ),
            GestureDetector(
              onTap: _toggleWishlist,
              child: Padding(
                padding: const EdgeInsets.only(left: 10, top: 2),
                child: Icon(
                  _isWishlisted ? Icons.favorite : Icons.favorite_border,
                  size: 24,
                  color: _isWishlisted
                      ? Colors.red
                      : AppColors.ink.withOpacity(0.45),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Sub name (category) — regular weight, softer gray, more legible
        // than the previous heavy 45% opacity mute.
        Text(
          product.subCategory ?? '',
          style: TextStyle(
            fontSize: 14.5,
            color: AppColors.ink.withOpacity(0.6),
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),

        const SizedBox(height: 16),
        // Ratings summary — green pill badge + count, matching the
        // Myntra "4.4 ★ | 679 Ratings" treatment.
        if (_liveSummary != null && _liveSummary!.totalReviews > 0)
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _liveSummary!.avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_liveSummary!.totalReviews} ${_liveSummary!.totalReviews == 1 ? 'Rating' : 'Ratings'}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.ink.withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          )
        else
          Text(
            'No ratings yet',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.ink.withOpacity(0.5),
            ),
          ),
        Divider(color: Colors.grey.withOpacity(0.45), thickness: 1, height: 20),
        const SizedBox(height: 10),

        // Price — reflects the selected size's own price if it has one
        // (Approach 1 per-size override), otherwise the base product price.
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontFamily: 'JetBrainsMono',
              ),
            ),
            if (mrp != null && mrp > price) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'MRP ₹${mrp.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.ink.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
            ],
            if (discountPercent > 0) ...[
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '($discountPercent% OFF)',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE07A29),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'inclusive of all taxes',
          style: TextStyle(
            fontSize: 12.5,
            color: const Color.fromARGB(255, 2, 103, 41).withOpacity(0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        // Colors — shown as each color's own product photo, not a dot
        if (_colors.isNotEmpty) ...[
          const Text(
            'Available Colors',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final c = _colors[i];
                final active = i == _activeColorIndex;
                final coverUrl = _colorCoverUrl(c);
                return GestureDetector(
                  onTap: () => _selectColor(i),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 70,
                        decoration: BoxDecoration(
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppColors.terracotta.withOpacity(
                                      0.45,
                                    ),
                                    blurRadius: 0,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: coverUrl != null
                            ? Image.network(
                                coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: AppColors.blush),
                              )
                            : Container(color: AppColors.blush),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.colorName,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.ink.withOpacity(active ? 0.9 : 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],

        _sizeSection(),
        Divider(color: Colors.grey.withOpacity(0.45), thickness: 1, height: 20),
        const SizedBox(height: 24),

        _sectionTitle('PRODUCT DETAILS'),
        const SizedBox(height: 10),
        Text(
          product.description.trim().isNotEmpty
              ? product.description
              : 'No description added yet.',
          style: const TextStyle(
            fontSize: 13.5,
            color: AppColors.ink,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 28),
        // ── Product specifications — Myntra-style two-column grid ──────
        if (_specifications.isNotEmpty ||
            _tags.isNotEmpty ||
            _extraAttributes.isNotEmpty) ...[
          _specificationsSection(),
          const SizedBox(height: 24),
        ],

        ReviewsSection(
          productId: product.id,
          onSummaryChanged: (summary) => setState(() => _liveSummary = summary),
        ),
      ],
    );
  }

  // ── Size chart (read-only for stock) ──────────────────────────────────
  // Tap the size itself to SELECT it (updates price above if this size has
  // its own price/mrp). Size 0 is selected by default, exactly like the
  // color swatch above defaults to index 0.
  Widget _sizeSection() {
    final variants = _activeVariants;
    if (variants.isEmpty) return const SizedBox.shrink();
    final totalStock = variants.fold<int>(
      0,
      (sum, v) => sum + (v.stockQuantity as num).toInt(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'SELECT SIZE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              'Total: $totalStock pcs',
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.ink.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: List.generate(variants.length, (i) {
            final v = variants[i];
            final stock = v.stockQuantity;
            final outOfStock = stock <= 0;
            final lowStock = stock > 0 && stock <= 5;
            final selected = _selectedSizeIndex == i;

            return GestureDetector(
              onTap: () => _onSizeTap(i),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? AppColors.terracotta.withOpacity(0.18)
                          : const Color.fromARGB(
                              255,
                              246,
                              243,
                              241,
                            ).withOpacity(0.5),
                      border: selected
                          ? Border.all(
                              color: const Color.fromARGB(93, 15, 12, 10),
                              width: 1.6,
                            )
                          : null,
                    ),
                    child: Text(
                      v.size,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        decoration: outOfStock
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    outOfStock ? 'Out of stock' : '$stock left',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: outOfStock
                          ? AppColors.ink.withOpacity(0.4)
                          : (lowStock ? AppColors.gold : AppColors.green),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Product specifications — laid out like Myntra's "Specifications"
  // block: a bold section title, then pairs of (muted label / bold value)
  // arranged two-per-row, each pair separated by a thin divider line.
  Widget _specificationsSection() {
    final pairs = <MapEntry<String, String>>[
      ..._specifications,
      ..._extraAttributes
          .where((a) => a.label.trim().isNotEmpty)
          .map((a) => MapEntry(a.label, a.value)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('SPECIFICATIONS'),
        const SizedBox(height: 14),
        if (pairs.isNotEmpty)
          Column(
            children: List.generate((pairs.length / 2).ceil(), (rowIndex) {
              final leftIndex = rowIndex * 2;
              final rightIndex = leftIndex + 1;
              final isLastRow = rightIndex >= pairs.length - 1;
              return Padding(
                padding: EdgeInsets.only(bottom: isLastRow ? 0 : 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _specPair(pairs[leftIndex])),
                    const SizedBox(width: 16),
                    Expanded(
                      child: rightIndex < pairs.length
                          ? _specPair(pairs[rightIndex])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }

  // One label/value pair, Myntra style: small muted uppercase-ish label
  // on top, bold larger value underneath.
  Widget _specPair(MapEntry<String, String> entry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.key,
          style: TextStyle(
            fontSize: 11.5,
            color: AppColors.ink.withOpacity(0.45),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.value,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
        Divider(color: Colors.grey.withOpacity(0.45), thickness: 1, height: 20),
      ],
    );
  }

  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontFamily: 'Fraunces',
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.ink,
      letterSpacing: 0.3,
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Gallery item model — a photo, or a collapsed group of 360° frames.
// ─────────────────────────────────────────────────────────────

enum _GalleryKind { photo, spin }

class _GalleryItem {
  final _GalleryKind kind;
  final String? url;
  final List<String>? spinUrls;

  _GalleryItem.photo(this.url) : kind = _GalleryKind.photo, spinUrls = null;

  _GalleryItem.spin(this.spinUrls) : kind = _GalleryKind.spin, url = null;
}

/// Spin viewer for a group of frames. Sits in the gallery list like any
/// other photo — no on-image label, no backdrop. Drag left/right to
/// rotate; auto-spins after 2 seconds of no touch.
class Product360AutoViewer extends StatefulWidget {
  final List<String> imageUrls;
  final bool autoPlay;
  const Product360AutoViewer({
    required this.imageUrls,
    this.autoPlay = true,
    super.key,
  });

  @override
  State<Product360AutoViewer> createState() => _Product360AutoViewerState();
}

class _Product360AutoViewerState extends State<Product360AutoViewer> {
  int _frame = 0;
  double _dragBuffer = 0;
  Timer? _autoTimer;
  Timer? _resumeTimer;

  static const double _sensitivity = 22;
  static const _autoStep = Duration(milliseconds: 450);
  static const _resumeAfter = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    for (final url in widget.imageUrls) {
      precacheImage(NetworkImage(url), context);
    }
    if (widget.autoPlay) _startAuto();
  }

  void _startAuto() {
    _autoTimer?.cancel();
    if (widget.imageUrls.length < 2) return;
    _autoTimer = Timer.periodic(_autoStep, (_) {
      if (!mounted) return;
      setState(() => _frame = (_frame + 1) % widget.imageUrls.length);
    });
  }

  void _pauseThenResume() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    if (!widget.autoPlay) return;
    _resumeTimer = Timer(_resumeAfter, () {
      if (mounted) _startAuto();
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _pauseThenResume();
    _dragBuffer += details.delta.dx;
    final steps = (_dragBuffer / _sensitivity).truncate();
    if (steps == 0) return;
    final n = widget.imageUrls.length;
    setState(() {
      _frame = ((_frame - steps) % n + n) % n;
      _dragBuffer -= steps * _sensitivity;
    });
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _resumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onDragUpdate,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: Image.network(
          widget.imageUrls[_frame],
          key: ValueKey(_frame),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.inkSoft),
          ),
        ),
      ),
    );
  }
}

/// Pinch-to-zoom on a single product photo, with a fullscreen expand
/// button for an even closer look. No backdrop.
class _ZoomableNetworkImage extends StatefulWidget {
  final String imageUrl;
  const _ZoomableNetworkImage({required this.imageUrl});

  @override
  State<_ZoomableNetworkImage> createState() => _ZoomableNetworkImageState();
}

class _ZoomableNetworkImageState extends State<_ZoomableNetworkImage> {
  final _transform = TransformationController();

  void _openFullscreen() {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            _FullscreenZoomView(imageUrl: widget.imageUrl),
      ),
    );
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          transformationController: _transform,
          minScale: 1,
          maxScale: 4,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.blush,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: AppColors.inkSoft,
              ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _openFullscreen,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.open_in_full,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fullscreen popup — pinch or drag to zoom further, tap X to close.
class _FullscreenZoomView extends StatelessWidget {
  final String imageUrl;
  const _FullscreenZoomView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
