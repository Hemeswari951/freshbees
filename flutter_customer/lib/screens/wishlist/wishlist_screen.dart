//wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_thiraa/widgets/app_colors.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';
import '../cart/cart_screen.dart';
import '../product/product_view_screen.dart';

/// Wishlist screen — every product the logged-in customer has hearted,
/// backed by GET /api/customer/wishlist.
///
/// Layout:
/// - Desktop (>=900px): "My Wishlist" + item count header above the grid,
///   with a "Select" action that turns on multi-select for bulk delete.
/// - Mobile (<900px): AppBar with back button, "My Wishlist" + item count,
///   and a cart icon on the right. A checklist icon in the AppBar (or a
///   long-press on a card) turns on the same multi-select mode.
/// - Cards: image -> name -> sub category -> price/offer -> a row of
///   Add to cart / Delete / Share icon buttons (no divider lines, evenly
///   spaced — matches the cleaner spacing used on the customer
///   ProductCard). In selection mode a checkbox appears on the image and
///   tapping the card toggles selection instead of opening the product.
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

  // --- Multi-select state -------------------------------------------------
  bool _isSelectionMode = false;
  // Using dynamic keys so this keeps working whether ProductModel.id is an
  // int or a String in your model.
  final Set<dynamic> _selectedIds = {};

  // Tracks which product is currently mid "Add to cart" call, so only
  // that card's button shows a spinner (same idea as _addingToBag on the
  // product view screen, just keyed per-card since this screen has many
  // products at once instead of one).
  final Set<dynamic> _addingToCartIds = {};

  static const double _desktopBreakpoint = 900;

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
      // Show the real reason (status code / server message) instead of a
      // generic string — this is what tells you 401 vs 404 vs 500 without
      // digging through DevTools every time.
      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // --- Single-item removal (used by the card's delete action) -----------

  Future<void> _removeFromWishlist(ProductModel product) async {
    // Optimistic removal — put it back if the backend call fails.
    final removedIndex = _items.indexWhere((p) => p.id == product.id);
    if (removedIndex == -1) return;

    setState(() {
      _items.removeAt(removedIndex);
      _selectedIds.remove(product.id);
    });

    bool ok;
    String? failureReason;
    try {
      ok = await WishlistService.removeFromWishlist(product.id);
    } catch (e) {
      ok = false;
      failureReason = e.toString().replaceFirst('Exception: ', '');
    }

    if (!ok && mounted) {
      setState(() => _items.insert(removedIndex, product));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failureReason ?? 'Could not remove item. Please try again.')),
      );
    }
  }

  // --- Multi-select helpers ------------------------------------------------

  void _enterSelectionMode({ProductModel? initialProduct}) {
    setState(() {
      _isSelectionMode = true;
      if (initialProduct != null) {
        _selectedIds.add(initialProduct.id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelectItem(ProductModel product) {
    setState(() {
      if (_selectedIds.contains(product.id)) {
        _selectedIds.remove(product.id);
      } else {
        _selectedIds.add(product.id);
      }
      // Auto-exit selection mode once nothing is left selected.
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll() {
    setState(() => _selectedIds.addAll(_items.map((p) => p.id)));
  }

  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove items?'),
        content: Text('Remove $count ${count == 1 ? 'item' : 'items'} from your wishlist?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('REMOVE', style: TextStyle(color: Color(0xFFFF3E6C))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _removeSelected();
  }

  Future<void> _removeSelected() async {
    final toRemove = _items.where((p) => _selectedIds.contains(p.id)).toList();
    if (toRemove.isEmpty) return;

    setState(() {
      _items.removeWhere((p) => _selectedIds.contains(p.id));
      _isSelectionMode = false;
      _selectedIds.clear();
    });

    final failed = <ProductModel>[];
    for (final product in toRemove) {
      try {
        final ok = await WishlistService.removeFromWishlist(product.id);
        if (!ok) failed.add(product);
      } catch (_) {
        failed.add(product);
      }
    }

    if (!mounted) return;

    if (failed.isNotEmpty) {
      setState(() => _items.insertAll(0, failed));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failed.length == 1
              ? 'Could not remove ${failed.first.productName}.'
              : 'Could not remove ${failed.length} items.'),
        ),
      );
    }
  }

  // --- Row actions on each card --------------------------------------------

  /// Add to cart — mirrors _handleAddToBag on ProductViewScreen:
  /// guest check -> CartService.addToCart -> "Added to Cart" snackbar with
  /// a VIEW CART action -> error snackbar on failure.
  ///
  /// Wishlist cards don't have a size/variant picker, so this adds the
  /// product with no variantId. If a product requires a size to be picked
  /// before it can go in the cart, the backend/CartService should reject
  /// it — in that case we just surface whatever message it throws and
  /// send the customer to the product page to pick a size.
  Future<void> _addToCart(ProductModel product) async {
    final token = ApiService.getToken();

    // ==========================================
    // GUEST USER → GO TO LOGIN
    // ==========================================
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add items to your bag'),
          duration: Duration(seconds: 2),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.push('/login');
      return;
    }

    setState(() => _addingToCartIds.add(product.id));

    try {
      await CartService.addToCart(
        productId: product.id,
        quantity: 1,
      );

      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.clearSnackBars();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('${product.productName} added to cart'),
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

      Future.delayed(const Duration(seconds: 3), () {
        scaffoldMessenger.hideCurrentSnackBar();
      });
    } catch (e) {
      if (!mounted) return;

      final message = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          // If the failure is because a size needs to be picked, give the
          // customer a direct path to the product page to pick one,
          // instead of a dead-end error.
          action: SnackBarAction(
            label: 'SELECT SIZE',
            onPressed: () => _openProduct(product),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _addingToCartIds.remove(product.id));
      }
    }
  }

  Future<void> _shareProduct(ProductModel product) async {
    // TODO: Wire this up to the share_plus package once it's added to
    // pubspec.yaml, e.g.:
    //   await Share.share('Check this out: ${product.productName}\n$productUrl');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share ${product.productName}')),
    );
  }

  // Back button — uses GoRouter's own stack (context.canPop/pop) instead
  // of Navigator.maybePop, since this screen is reached via go_router
  // (context.push('/wishlist') etc.) and Navigator.maybePop doesn't
  // reliably know about that stack. Falls back to going home if there's
  // genuinely nowhere to pop back to (e.g. wishlist opened as a deep link).
  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
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

  // ProductModel exposes subCategory directly (same field the customer
  // ProductCard uses), so just read it straight off.
  String _subCategoryOf(ProductModel product) => product.subCategory;

  // Matches ProductCard's image handling: thumbnail is a relative path
  // from the backend, so it needs the server URL prefixed. Left as-is if
  // it's already an absolute URL.
  String _imageUrlOf(ProductModel product) {
    if (product.thumbnail.isEmpty) return '';
    if (product.thumbnail.startsWith('http')) return product.thumbnail;
    return '${ApiService.serverUrl}${product.thumbnail}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
        return Scaffold(
          backgroundColor: const Color(0xFFFAF7F2),
          appBar: isDesktop ? null : _buildMobileAppBar(),
          body: SafeArea(
            child: Column(
              children: [
                if (isDesktop) _buildDesktopHeader(),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Headers --------------------------------------------------------------

  PreferredSizeWidget _buildMobileAppBar() {
    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          '${_selectedIds.length} selected',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: _selectedIds.length == _items.length ? null : _selectAll,
            child: const Text('SELECT ALL'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove selected',
            onPressed: _selectedIds.isEmpty ? null : _confirmDeleteSelected,
          ),
        ],
      );
    }

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.black),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _handleBack,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'My Wishlist',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          if (_isLoggedIn && _error == null && !_isLoading)
            Text(
              '${_items.length} ${_items.length == 1 ? 'item' : 'items'}',
              style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w400),
            ),
        ],
      ),
      actions: [
        if (_items.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.checklist),
            tooltip: 'Select items',
            onPressed: () => _enterSelectionMode(),
          ),
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          tooltip: 'Cart',
          onPressed: () => context.push('/cart'),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    // Nothing useful to show on top of loading/empty/error states — those
    // already carry their own messaging.
    if (_isLoading || !_isLoggedIn || _error != null || _items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black87, fontSize: 18),
                    children: [
                      const TextSpan(text: 'My Wishlist  ', style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(
                        text: '${_items.length} ${_items.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(fontWeight: FontWeight.w400, color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isSelectionMode) ...[
                Text(
                  '${_selectedIds.length} selected',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _selectedIds.length == _items.length ? null : _selectAll,
                  child: const Text('SELECT ALL'),
                ),
                TextButton(onPressed: _exitSelectionMode, child: const Text('CANCEL')),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove selected',
                  onPressed: _selectedIds.isEmpty ? null : _confirmDeleteSelected,
                ),
              ] else
                TextButton.icon(
                  onPressed: () => _enterSelectionMode(),
                  icon: const Icon(Icons.checklist, size: 18),
                  label: const Text('SELECT'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Body / grid -----------------------------------------------------------

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
      // LayoutBuilder gives the real available width on every rebuild
      // (window resize, orientation change, phone -> maximized desktop
      // window) so the grid re-flows instead of being pinned to a fixed
      // column count.
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = _columnsForWidth(constraints.maxWidth);
          // Desktop cards get a taller image relative to width vs. phones,
          // matching Myntra's own layout at each breakpoint. Slightly
          // taller than before to fit the sub-category line + action row.
          final aspectRatio = columns <= 2 ? 0.54 : 0.6;

          return Center(
            child: ConstrainedBox(
              // Caps the grid on ultra-wide monitors so cards don't
              // stretch into huge empty-feeling tiles — Myntra does the
              // same with a centered, max-width content column.
              constraints: const BoxConstraints(maxWidth: 1600),
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) {
                  final product = _items[index];
                  return _buildMyntraWishlistCard(product);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Mirrors Myntra's own responsive breakpoints: 2-up on phones, scaling
  // up to 5-up on desktop-width screens.
  int _columnsForWidth(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  Widget _buildMyntraWishlistCard(ProductModel product) {
    final double sellingPrice = product.price.toDouble();
    final double mrp = product.mrp?.toDouble() ?? sellingPrice;
    final int discount = mrp > sellingPrice ? ((mrp - sellingPrice) / mrp * 100).round() : 0;
    final String subCategory = _subCategoryOf(product);
    final bool isSelected = _selectedIds.contains(product.id);
    final bool isAddingToCart = _addingToCartIds.contains(product.id);
    final double rating = product.rating; // always shown now, 0.0 included
    final int reviewCount = product.reviewCount;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelectItem(product);
        } else {
          _openProduct(product);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) _enterSelectionMode(initialProduct: product);
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFFFF3E6C) : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Image + selection checkbox ---
            Expanded(
              child: Padding(
                // Small left/right breathing room + a bit more space up
                // top before the image starts.
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          color: const Color(0xFFF5F1EA),
                          child: product.thumbnail.isEmpty
                              ? const Center(
                                  child: Icon(Icons.image_outlined, color: Colors.black26, size: 36),
                                )
                              : Image.network(
                                  _imageUrlOf(product),
                                  fit: BoxFit.cover,
                                  // A broken/missing thumbnail URL (e.g. one
                                  // that 404s and returns an HTML error page)
                                  // used to crash the tile with a big red
                                  // "ImageCodecException" overlay. Fall back
                                  // to a plain placeholder instead.
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.image_not_supported_outlined,
                                          color: Colors.black26, size: 36),
                                    );
                                  },
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),
                    // Ratings badge — bottom-left over the image, matching
                    // ProductCard's pill exactly: cream/white background,
                    // bold black rating, teal star, a thin divider, then
                    // the review count — instead of the green pill this
                    // screen had before. Always shown (0.0 / 0 included).
                    Positioned(
                      bottom: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, size: 11, color: Colors.teal),
                            const SizedBox(width: 4),
                            Container(
                              width: 1,
                              height: 10,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatReviewCount(reviewCount),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isSelectionMode)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => _toggleSelectItem(product),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF3E6C) : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFF3E6C) : Colors.black38,
                                width: 1.5,
                              ),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 14, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // --- Name / sub category / price ---
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (subCategory.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subCategory,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        '₹${sellingPrice.toInt()}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      if (discount > 0) ...[
                        Text(
                          '₹${mrp.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.4),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          '($discount% OFF)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // --- Add to cart (prominent, colored) + delete / share chips ---
            // Fixed a mobile overflow here: "ADD TO CART" + icon + two
            // 34px chips didn't fit inside a narrow 2-column card width
            // (~150px), which is exactly the RenderFlex overflow seen on
            // phone widths. Shortened the label to "ADD", shrunk the chip
            // buttons to 30px, and wrapped the button's content in a
            // FittedBox so it scales down instead of overflowing on any
            // width that's still too tight.
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: isAddingToCart ? null : () => _addToCart(product),
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isAddingToCart
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.white),
                                    SizedBox(width: 5),
                                    Text(
                                      'ADD',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _colorChipButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Remove',
                    color: const Color(0xFFE0523F),
                    background: const Color(0xFFFCE9E6),
                    onTap: () => _removeFromWishlist(product),
                  ),
                  const SizedBox(width: 6),
                  _colorChipButton(
                    icon: Icons.share_outlined,
                    tooltip: 'Share',
                    color: const Color(0xFF3E7BC4),
                    background: const Color(0xFFE7F0FA),
                    onTap: () => _shareProduct(product),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact display for the review count — same helper as ProductCard,
  // 1,240 -> "1.2k", 950 -> "950" — so the number reads consistently
  // wherever a rating pill shows up in the app.
  String _formatReviewCount(int count) {
    if (count >= 1000) {
      final thousands = count / 1000;
      return '${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}k';
    }
    return count.toString();
  }

  // Small colored circle chip used for the delete/share actions next to
  // the Add to Cart pill — a tinted background + matching icon color
  // instead of a plain black icon, so each action reads distinctly.
  Widget _colorChipButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        containedInkWell: true,
        highlightShape: BoxShape.circle,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
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