// wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_thiraa/widgets/app_colors.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';
import '../../services/cart_count.dart';
import '../product/product_view_screen.dart';

/// Wishlist screen — every product the logged-in customer has hearted,
/// backed by GET /api/customer/wishlist.
///
/// Layout:
/// - Desktop (>=900px): "My Wishlist" + item count header above the grid,
///   with a "Select" action that turns on multi-select for bulk delete.
/// - Mobile (<900px): compact AppBar with back button, "My Wishlist" +
///   item count, checklist icon and cart icon with cart count.
/// - Cards: image -> name -> sub category -> price/offer -> a row of
///   Add to cart / Delete / Share icon buttons.
/// - In selection mode a checkbox appears on the image and tapping the
///   card toggles selection instead of opening the product.
/// 
/// 
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

  // ---------------------------------------------------------------------------
  // Multi-select state
  // ---------------------------------------------------------------------------

  bool _isSelectionMode = false;

  //final Set<dynamic> _selectedIds = {};
   final Set<String> _selectedIds = {};
  // ---------------------------------------------------------------------------
  // Add to cart loading state
  // ---------------------------------------------------------------------------
 
  final Set<dynamic> _addingToCartIds = {};

  static const double _desktopBreakpoint = 900;

   static const List<String> _sizeOrder = [
    'XS', 'S', 'M', 'L', 'XL', 'XXL', '3XL', '4XL',
  ];

  List<String> _sortedSizes(List<String> sizes) {
    final list = [...sizes];
    list.sort((a, b) {
      final ai = _sizeOrder.indexOf(a.toUpperCase());
      final bi = _sizeOrder.indexOf(b.toUpperCase());
      // Unknown/numeric sizes (e.g. "28", "30") that aren't in the known
      // apparel order fall back to a plain alphabetical/numeric sort and
      // are placed after all known sizes.
      if (ai == -1 && bi == -1) return a.compareTo(b);
      if (ai == -1) return 1;
      if (bi == -1) return -1;
      return ai.compareTo(bi);
    });
    return list;
  }

  // Best-effort mapping from a color name (as stored in
  // product_colors.color_name) to an actual swatch color, so each color
  // chip in the popup can show a small preview dot next to its name —
  // same pattern most e-commerce PDPs use for color pickers. Returns null
  // for unrecognized names, in which case the chip just shows text.
  static const Map<String, Color> _colorSwatches = {
    'red': Colors.red,
    'blue': Colors.blue,
    'lightblue': Color(0xFFADD8E6),
    'skyblue': Color(0xFF87CEEB),
    'navy': Color(0xFF001F54),
    'white': Colors.white,
    'black': Colors.black,
    'green': Colors.green,
    'yellow': Colors.yellow,
    'pink': Colors.pink,
    'purple': Colors.purple,
    'orange': Colors.orange,
    'grey': Colors.grey,
    'gray': Colors.grey,
    'brown': Colors.brown,
    'maroon': Color(0xFF800000),
    'beige': Color(0xFFF5F5DC),
    'cream': Color(0xFFFFFDD0),
    'gold': Color(0xFFFFD700),
    'silver': Color(0xFFC0C0C0),
    'teal': Colors.teal,
    'olive': Color(0xFF808000),
    'mustard': Color(0xFFFFDB58),
    'peach': Color(0xFFFFE5B4),
    'lavender': Color(0xFFE6E6FA),
    'mint': Color(0xFF98FF98),
  };

  Color? _swatchForColorName(String name) {
    final key = name.trim().toLowerCase().replaceAll(' ', '');
    return _colorSwatches[key];
  }

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ---------------------------------------------------------------------------
  // LOAD WISHLIST
  // ---------------------------------------------------------------------------

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

      setState(() {
        _isLoggedIn = true;
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ---------------------------------------------------------------------------
  // REMOVE SINGLE WISHLIST ITEM
  // ---------------------------------------------------------------------------

   Future<void> _removeFromWishlist(ProductModel product) async {
    final key = '${product.id}_${product.productColorId ?? 0}';
    final removedIndex = _items.indexWhere((p) => '${p.id}_${p.productColorId ?? 0}' == key);
    if (removedIndex == -1) return;

    setState(() {
      _items.removeAt(removedIndex);
      _selectedIds.remove(key);
    });


    bool ok;
    String? failureReason;
    try {
     ok = await WishlistService.removeFromWishlist(
      product.id, 
      productColorId: product.productColorId
    );
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
        _selectedIds.add('${initialProduct.id}_${initialProduct.productColorId ?? 0}');
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
    final key = '${product.id}_${product.productColorId ?? 0}';
    setState(() {
      if (_selectedIds.contains(key)) {
        _selectedIds.remove(key);
      } else {
        _selectedIds.add(key);
      }
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _selectAll() {
    setState(() => _selectedIds.addAll(_items.map((p) => '${p.id}_${p.productColorId ?? 0}')));
  }

  // ---------------------------------------------------------------------------
  // DELETE SELECTED ITEMS
  // ---------------------------------------------------------------------------

  Future<void> _confirmDeleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove items?'),
        content: Text(
          'Remove $count '
          '${count == 1 ? 'item' : 'items'} '
          'from your wishlist?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'REMOVE',
              style: TextStyle(
                color: Color(0xFFFF3E6C),
              ),
            ),
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

  // ---------------------------------------------------------------------------
  // ADD TO CART
  // ---------------------------------------------------------------------------

     Future<void> _addToCart(ProductModel product) async {
    final token = ApiService.getToken();

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to add items to your bag'), duration: Duration(seconds: 2)),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.push('/login');
      return;
    }

    String? selectedSize;
    
    // AUTO-SELECT: Automatically use the wishlisted color since the backend 
    // now filters product.colors to only contain the wishlisted variation.
    String? selectedColor = product.colors.isNotEmpty ? product.colors.first : null;

    final hasSizes = product.sizes.isNotEmpty;

    // Show popup ONLY if the product requires a size
    if (hasSizes) {
      final result = await _showSelectionBottomSheet(product);
      if (result == null) return; 
      selectedSize = result['size'];
    }

    final key = '${product.id}_${product.productColorId ?? 0}';
    setState(() => _addingToCartIds.add(key));


    try {
      await CartService.addToCart(
        productId: product.id,
        quantity: 1,
        size: selectedSize, 
        color: selectedColor, // Passes the auto-selected color
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.productName} added to cart'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'VIEW CART',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              context.push('/cart');
            },
          ),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')), 
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _addingToCartIds.remove(key));
    }
  }

   Future<Map<String, String?>?> _showSelectionBottomSheet(ProductModel product) {
    String? tempSelectedSize;
    final hasSizes = product.sizes.isNotEmpty;
    final hasVariantData = product.variants.isNotEmpty;

    // All valid sizes for this specific wishlisted color
    Set<String> availableSizes() {
      if (!hasVariantData) return product.sizes.toSet();
      return product.variants
          .map((v) => v.size ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
    }

    return showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isValid = !hasSizes || tempSelectedSize != null;
            final sizes = availableSizes();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 12,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Small Drag Handle ---
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                 // --- Header: "Choose options" + Close Icon ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Size',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(ctx),
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.close, size: 22, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Product Info Header ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 64,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F1EA),
                          image: product.thumbnail.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_imageUrlOf(product)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: product.thumbnail.isEmpty
                            ? const Icon(Icons.image_outlined, color: Colors.black26, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _subCategoryOf(product),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- Sizes Section ---
                  if (hasSizes) ...[
                    const Text(
                      'Size',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _sortedSizes(product.sizes).map<Widget>((size) {
                        final isSelected = tempSelectedSize == size;
                        final isEnabled = sizes.contains(size);
                        return GestureDetector(
                          onTap: !isEnabled
                              ? null
                              : () => setSheetState(() {
                                    tempSelectedSize = size;
                                  }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isSelected ? Colors.black : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.black
                                    : (isEnabled ? Colors.black38 : Colors.black12),
                                width: isSelected ? 1.4 : 1,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  size,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isEnabled ? Colors.black87 : Colors.black26),
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                                if (!isEnabled)
                                  Container(
                                    width: 34,
                                    height: 1.4,
                                    color: Colors.black38,
                                    transform: Matrix4.rotationZ(-0.79),
                                    transformAlignment: Alignment.center,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // --- Continue Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isValid ? Colors.black : Colors.grey.shade200,
                        foregroundColor: isValid ? Colors.white : Colors.black38,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: isValid
                          ? () => Navigator.pop(ctx, {'size': tempSelectedSize})
                          : null,
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SHARE
  // ---------------------------------------------------------------------------

  Future<void> _shareProduct(ProductModel product) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Share ${product.productName}',
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BACK
  // ---------------------------------------------------------------------------

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  // ---------------------------------------------------------------------------
  // OPEN PRODUCT
  // ---------------------------------------------------------------------------

  void _openProduct(ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductViewScreen(
          productId: product.id,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PRODUCT HELPERS
  // ---------------------------------------------------------------------------

  String _subCategoryOf(ProductModel product) {
    return product.subCategory;
  }

  String _imageUrlOf(ProductModel product) {
    if (product.thumbnail.isEmpty) {
      return '';
    }

    if (product.thumbnail.startsWith('http')) {
      return product.thumbnail;
    }

    return '${ApiService.serverUrl}${product.thumbnail}';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth >= _desktopBreakpoint;

        return Scaffold(
          backgroundColor: const Color(0xFFFAF7F2),

          appBar: isDesktop
              ? null
              : _buildMobileAppBar(),

          body: SafeArea(
            child: Column(
              children: [
                if (isDesktop)
                  _buildDesktopHeader(),

                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MOBILE HEADER
  // ===========================================================================
  //
  // IMPORTANT:
  // We are NOT using AppBar.leading + AppBar.title here.
  //
  // Instead everything is inside one Row.
  //
  // This removes the large default gap between the back button and title.
  //
  // Cart uses cartItemCount from cart_count.dart.
  // ===========================================================================

  PreferredSizeWidget _buildMobileAppBar() {
    // -------------------------------------------------------------------------
    // SELECTION MODE HEADER
    // -------------------------------------------------------------------------

    if (_isSelectionMode) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        ),
        title: Text(
          '${_selectedIds.length} selected',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                _selectedIds.length == _items.length
                    ? null
                    : _selectAll,
            child: const Text('SELECT ALL'),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
            ),
            tooltip: 'Remove selected',
            onPressed: _selectedIds.isEmpty
                ? null
                : _confirmDeleteSelected,
          ),
        ],
      );
    }

    // -------------------------------------------------------------------------
    // NORMAL MOBILE HEADER
    // -------------------------------------------------------------------------

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,

      // Removes AppBar's automatic leading/title spacing.
      automaticallyImplyLeading: false,

      // Important for tight layout.
      toolbarHeight: 56,
      titleSpacing: 0,

      title: Row(
        children: [
          // -------------------------------------------------------------------
          // BACK BUTTON
          // -------------------------------------------------------------------

          SizedBox(
            width: 42,
            height: 44,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 22,
              ),
              onPressed: _handleBack,
            ),
          ),

          // Very small gap between back button and title.
          const SizedBox(width: 2),

          // -------------------------------------------------------------------
          // TITLE + ITEM COUNT
          // -------------------------------------------------------------------

          Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'My Wishlist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),

                if (_isLoggedIn &&
                    _error == null &&
                    !_isLoading)
                  Text(
                    '${_items.length} '
                    '${_items.length == 1 ? 'item' : 'items'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // SELECT / CHECKLIST
          // -------------------------------------------------------------------

          if (_items.isNotEmpty)
            SizedBox(
              width: 42,
              height: 44,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.checklist,
                  color: Colors.black,
                  size: 22,
                ),
                tooltip: 'Select items',
                onPressed: () {
                  _enterSelectionMode();
                },
              ),
            ),

          // -------------------------------------------------------------------
          // CART + COUNT BADGE
          // -------------------------------------------------------------------

          ValueListenableBuilder<int>(
            valueListenable: cartItemCount,
            builder: (
              context,
              count,
              child,
            ) {
              return SizedBox(
                width: 48,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Cart icon
                    Positioned.fill(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(),
                        icon: const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.black,
                          size: 22,
                        ),
                        tooltip: 'Cart',
                        onPressed: () {
                          context.push('/cart');
                        },
                      ),
                    ),

                    // Cart count badge
                    if (count > 0)
                      Positioned(
                        right: 2,
                        top: 1,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          constraints:
                              const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          decoration:
                              const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            count > 99
                                ? '99+'
                                : '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DESKTOP HEADER
  // ===========================================================================

  Widget _buildDesktopHeader() {
    if (_isLoading ||
        !_isLoggedIn ||
        _error != null ||
        _items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        24,
        4,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1600,
          ),
          child: Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                    ),
                    children: [
                      const TextSpan(
                        text: 'My Wishlist  ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(
                        text:
                            '${_items.length} '
                            '${_items.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_isSelectionMode) ...[
                Text(
                  '${_selectedIds.length} selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(width: 16),

                TextButton(
                  onPressed:
                      _selectedIds.length ==
                              _items.length
                          ? null
                          : _selectAll,
                  child: const Text(
                    'SELECT ALL',
                  ),
                ),

                TextButton(
                  onPressed: _exitSelectionMode,
                  child: const Text(
                    'CANCEL',
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                  tooltip: 'Remove selected',
                  onPressed:
                      _selectedIds.isEmpty
                          ? null
                          : _confirmDeleteSelected,
                ),
              ] else
                TextButton.icon(
                  onPressed: () {
                    _enterSelectionMode();
                  },
                  icon: const Icon(
                    Icons.checklist,
                    size: 18,
                  ),
                  label: const Text(
                    'SELECT',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // BODY
  // ===========================================================================

  Widget _buildBody() {
    // Loading
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Not logged in
    if (!_isLoggedIn) {
      return _emptyState(
        icon: Icons.lock_outline,
        title:
            'Please login to view your wishlist',
        actionLabel: 'Login',
        onAction: () {
          context.push('/login');
        },
      );
    }

    // Error
    if (_error != null) {
      return _emptyState(
        icon: Icons.error_outline,
        title: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }

    // Empty
    if (_items.isEmpty) {
      return _emptyState(
        icon: Icons.favorite_border,
        title: 'Your wishlist is empty',
        subtitle:
            'Tap the heart on any product to save it here.',
      );
    }

    // Wishlist grid
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (
          context,
          constraints,
        ) {
          final columns =
              _columnsForWidth(
            constraints.maxWidth,
          );

          final aspectRatio =
              columns <= 2 ? 0.54 : 0.6;

          return Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 1600,
              ),
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _items.length,
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio:
                      aspectRatio,
                ),
                itemBuilder: (
                  context,
                  index,
                ) {
                  final product =
                      _items[index];

                  return _buildMyntraWishlistCard(
                    product,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // GRID COLUMNS
  // ===========================================================================

  int _columnsForWidth(double width) {
    if (width >= 1200) {
      return 5;
    }

    if (width >= 900) {
      return 4;
    }

    if (width >= 600) {
      return 3;
    }

    return 2;
  }

  // ===========================================================================
  // WISHLIST CARD
  // ===========================================================================

  Widget _buildMyntraWishlistCard(
    ProductModel product,
  ) {
    final double sellingPrice =
        product.price.toDouble();

    final double mrp =
        product.mrp?.toDouble() ??
            sellingPrice;

    final int discount =
        mrp > sellingPrice
            ? ((mrp - sellingPrice) /
                    mrp *
                    100)
                .round()
            : 0;

    final String subCategory =
        _subCategoryOf(product);

    final bool isSelected =
        _selectedIds.contains(product.id);

    final bool isAddingToCart =
        _addingToCartIds.contains(
      product.id,
    );

    final double rating =
        product.rating;

    final int reviewCount =
        product.reviewCount;

    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelectItem(product);
        } else {
          _openProduct(product);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(
            initialProduct: product,
          );
        }
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF3E6C)
                : Colors.grey.shade200,
            width: isSelected
                ? 1.5
                : 1,
          ),
          borderRadius:
              BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            // -----------------------------------------------------------------
            // IMAGE
            // -----------------------------------------------------------------

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  8,
                  12,
                  8,
                  6,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(
                          10,
                        ),
                        child: Container(
                          color:
                              const Color(
                            0xFFF5F1EA,
                          ),
                          child: product
                                  .thumbnail
                                  .isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons
                                        .image_outlined,
                                    color:
                                        Colors.black26,
                                    size: 36,
                                  ),
                                )
                              : Image.network(
                                  _imageUrlOf(
                                    product,
                                  ),
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Center(
                                      child:
                                          Icon(
                                        Icons
                                            .image_not_supported_outlined,
                                        color:
                                            Colors.black26,
                                        size: 36,
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (
                                    context,
                                    child,
                                    progress,
                                  ) {
                                    if (progress ==
                                        null) {
                                      return child;
                                    }

                                    return const Center(
                                      child:
                                          SizedBox(
                                        width: 20,
                                        height: 20,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ),

                    // -----------------------------------------------------------
                    // RATING
                    // -----------------------------------------------------------

                    Positioned(
                      bottom: 5,
                      left: 5,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: AppColors
                              .cream
                              .withOpacity(0.9),
                          borderRadius:
                              BorderRadius.circular(
                            4,
                          ),
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              rating.toStringAsFixed(
                                1,
                              ),
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    Colors.black87,
                              ),
                            ),

                            const SizedBox(
                              width: 2,
                            ),

                            const Icon(
                              Icons.star,
                              size: 11,
                              color:
                                  Colors.teal,
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Container(
                              width: 1,
                              height: 10,
                              color: Colors
                                  .grey
                                  .shade400,
                            ),

                            const SizedBox(
                              width: 4,
                            ),

                            Text(
                              _formatReviewCount(
                                reviewCount,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors
                                    .grey
                                    .shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // -----------------------------------------------------------
                    // SELECTION CHECKBOX
                    // -----------------------------------------------------------

                    if (_isSelectionMode)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () {
                            _toggleSelectItem(
                              product,
                            );
                          },
                          child:
                              AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds: 120,
                            ),
                            width: 22,
                            height: 22,
                            decoration:
                                BoxDecoration(
                              color: isSelected
                                  ? const Color(
                                      0xFFFF3E6C,
                                    )
                                  : Colors.white,
                              shape:
                                  BoxShape.circle,
                              border:
                                  Border.all(
                                color: isSelected
                                    ? const Color(
                                        0xFFFF3E6C,
                                      )
                                    : Colors
                                        .black38,
                                width: 1.5,
                              ),
                              boxShadow:
                                  const [
                                BoxShadow(
                                  color:
                                      Colors.black12,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 14,
                                    color:
                                        Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // -----------------------------------------------------------------
            // PRODUCT DETAILS
            // -----------------------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                10,
                10,
                10,
                6,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    product.productName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          Colors.black87,
                    ),
                  ),

                  if (subCategory.isNotEmpty) ...[
                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subCategory,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 11.5,
                        color:
                            Colors.black54,
                      ),
                    ),
                  ],

                  const SizedBox(
                    height: 6,
                  ),

                  Wrap(
                    crossAxisAlignment:
                        WrapCrossAlignment
                            .center,
                    spacing: 6,
                    children: [
                      Text(
                        '₹${sellingPrice.toInt()}',
                        style:
                            const TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Colors.black87,
                        ),
                      ),

                      if (discount > 0) ...[
                        Text(
                          '₹${mrp.toInt()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors
                                .black
                                .withOpacity(
                              0.4,
                            ),
                            decoration:
                                TextDecoration
                                    .lineThrough,
                          ),
                        ),

                        Text(
                          '($discount% OFF)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors
                                .green
                                .shade700,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // -----------------------------------------------------------------
            // ACTIONS
            // -----------------------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                8,
                0,
                8,
                8,
              ),
              child: Row(
                children: [
                  // -----------------------------------------------------------
                  // ADD TO CART
                  // -----------------------------------------------------------

                  Expanded(
                    child: GestureDetector(
                      onTap: isAddingToCart
                          ? null
                          : () {
                              _addToCart(
                                product,
                              );
                            },
                      child: Container(
                        height: 32,
                        alignment:
                            Alignment.center,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              AppColors.ink,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),
                        child: isAddingToCart
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  valueColor:
                                      AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit
                                    .scaleDown,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                  mainAxisSize:
                                      MainAxisSize
                                          .min,
                                  children: const [
                                    Icon(
                                      Icons
                                          .shopping_bag_outlined,
                                      size: 14,
                                      color:
                                          Colors.white,
                                    ),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      'ADD',
                                      style:
                                          TextStyle(
                                        color:
                                            Colors.white,
                                        fontSize:
                                            11,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        letterSpacing:
                                            0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  // -----------------------------------------------------------
                  // DELETE
                  // -----------------------------------------------------------

                  _colorChipButton(
                    icon:
                        Icons.delete_outline,
                    tooltip: 'Remove',
                    color:
                        const Color(0xFFE0523F),
                    background:
                        const Color(0xFFFCE9E6),
                    onTap: () {
                      _removeFromWishlist(
                        product,
                      );
                    },
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  // -----------------------------------------------------------
                  // SHARE
                  // -----------------------------------------------------------

                  _colorChipButton(
                    icon:
                        Icons.share_outlined,
                    tooltip: 'Share',
                    color:
                        const Color(0xFF3E7BC4),
                    background:
                        const Color(0xFFE7F0FA),
                    onTap: () {
                      _shareProduct(
                        product,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // REVIEW COUNT
  // ===========================================================================

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      final thousands = count / 1000;

      return '${thousands.toStringAsFixed(
        thousands >= 10 ? 0 : 1,
      )}k';
    }

    return count.toString();
  }

  // ===========================================================================
  // DELETE / SHARE SMALL BUTTON
  // ===========================================================================

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
        highlightShape:
            BoxShape.circle,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 15,
            color: color,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // EMPTY STATE
  // ===========================================================================

  Widget _emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: Colors.black26,
            ),

            const SizedBox(
              height: 16,
            ),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.black87,
              ),
            ),

            if (subtitle != null) ...[
              const SizedBox(
                height: 6,
              ),

              Text(
                subtitle,
                textAlign:
                    TextAlign.center,
                style:
                    const TextStyle(
                  fontSize: 13,
                  color:
                      Colors.black54,
                ),
              ),
            ],

            if (actionLabel != null &&
                onAction != null) ...[
              const SizedBox(
                height: 16,
              ),

              ElevatedButton(
                onPressed: onAction,
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.black,
                  foregroundColor:
                      Colors.white,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child:
                    Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}