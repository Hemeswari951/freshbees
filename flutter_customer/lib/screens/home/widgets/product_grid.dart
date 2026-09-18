import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'product_filters.dart';
import '../../../models/product_model.dart';
import '../../../services/api_service.dart';
import '../../../services/product_service.dart';
import '../../../services/wishlist_service.dart';
import '../../../widgets/product_card.dart';

const double kMobileBreakpoint = 600;
const Color kAccent = Color(0xFFB8956A);

class ProductGrid extends StatefulWidget {
  /// Main category / category coming from parent tab.
  ///
  /// Supported:
  /// all
  /// men
  /// women
  /// kids
  /// beauty
  final String category;
  final String? searchQuery;
  final XFile? searchImage;
  final int? shopId;

  const ProductGrid({
    super.key,
    required this.category,
    this.searchQuery,
    this.searchImage,
    this.shopId,

  });

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  late ProductFilters _filters;

  late Future<List<ProductModel>> _future;

  // ------------------------------------------------------------
  // Wishlist — same pattern as ProductListScreen
  // ------------------------------------------------------------

   final Set<String> _wishlistIds = {}; // <-- CHANGED from int to String

  bool get _isLoggedIn {
    final token = ApiService.getToken();
    return token != null && token.isNotEmpty;
  }

  // ------------------------------------------------------------
  // Sub categories
  // ------------------------------------------------------------

  static const List<String> _categories = [
    'Saree',
    'Shirt',
    'T Shirts',
    'Pant',
    'Kids',
  ];

   // Add this directly below static const List<String> _categories = [...];

//new
 static const List<String> _colors = [
    'Black', 'White', 'Red', 'Blue', 'Green', 'Yellow', 'Pink', 'Brown'
  ];

  // Add this method near your _openCategorySheet() method
  void _openColorSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return _ColorSheet(
          colors: _colors,
          currentColor: _filters.color,
          onSelect: (color) {
            _applyFilter(
              _filters.copyWith(
                color: color,
                clearColor: color == null,
              ),
            );
          },
        );
      },
    );
  }




  static const List<List<dynamic>> _priceRangesOriginal = [
    ['Under ₹199', 0.0, 199.0],
    ['₹200 - ₹499', 200.0, 499.0],
    ['₹500 - ₹999', 500.0, 999.0],
    ['₹1000 & Above', 1000.0, null],
  ];

  late List<List<dynamic>> _priceRanges;

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // widget.category ("all"/"men"/"women"/"kids"/"beauty") maps directly
    // onto ProductFilters.category — the main category filter.
    _filters = ProductFilters(
      category: widget.category,
      shopId: widget.shopId, // <-- ADDED
    );

    _priceRanges = List.of(_priceRangesOriginal);

    _fetch();
    _loadWishlistIds();
  }

  // ------------------------------------------------------------
  // When parent tab changes
  // ------------------------------------------------------------

  @override
  void didUpdateWidget(covariant ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool categoryChanged = oldWidget.category != widget.category;
    final bool searchChanged =
        oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.searchImage != widget.searchImage;

    if (categoryChanged || searchChanged) {
      _filters = ProductFilters(
        category: widget.category,
      );

      _priceRanges = List.of(_priceRangesOriginal);

      _fetch();
    }
  }

  // ------------------------------------------------------------
  // FETCH PRODUCTS
  // ------------------------------------------------------------

  void _fetch() {
    final future = ProductService.getProducts(
      filters: _filters.toQueryParams(),
    );

    if (mounted) {
      setState(() {
        _future = future;
      });
    } else {
      _future = future;
    }
  }

  // ------------------------------------------------------------
  // WISHLIST
  // ------------------------------------------------------------

 /* Future<void> _loadWishlistIds() async {
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
*/

 Future<void> _loadWishlistIds() async {
    if (!_isLoggedIn) return;
    try {
      final items = await WishlistService.getWishlist();
      if (!mounted) return;
     setState(() {
        _wishlistIds
          ..clear()
          ..addAll(items.map((p) => '${p.id}_${p.productColorId ?? 0}'));
      });
    } catch (_) {}
  }


  Future<void> _toggleWishlist(ProductModel product) async {
    if (!_isLoggedIn) {
      context.push('/login');
      return;
    }
    
    final key = '${product.id}_${product.productColorId ?? 0}';
    // BUG FIX: this used to compare `product.id` (an int) against
    // `_wishlistIds`, which is a Set<String> of "productId_colorId" keys.
    // An int can never equal one of those strings, so this always
    // evaluated to false — every tap was treated as "not wishlisted yet"
    // regardless of the real state, so a color that was already wishlisted
    // (or one that had actually been added a moment ago) could get stuck
    // and never toggle off correctly. Check against the same composite
    // `key` that's used everywhere else (including the isWishlisted flag
    // passed into ProductCard below) so add/remove is always keyed by
    // product + color, not product alone.
    final wasWishlisted = _wishlistIds.contains(key);

    setState(() {
      if (wasWishlisted) {
        _wishlistIds.remove(key); // Remove specific color
      } else {
        _wishlistIds.add(key);    // Add specific color
      }
    });

   bool ok;
    try {
      ok = wasWishlisted
          ? await WishlistService.removeFromWishlist(
              product.id, 
              productColorId: product.productColorId,
            )
          : await WishlistService.addToWishlist(
              product.id,
              productColorId: product.productColorId,
            );
    } catch (_) {
      ok = false;
    }

    if (!ok && mounted) {
      setState(() {
        if (wasWishlisted) {
          _wishlistIds.add(key); // Revert specific color
        } else {
          _wishlistIds.remove(key); // Revert specific color
        }
      });
    }
  }
  // ------------------------------------------------------------
  // NAVIGATION
  // ------------------------------------------------------------

  void _openProduct(ProductModel product) {
    context.push('/products/${product.id}');
  }

  // ------------------------------------------------------------
  // APPLY FILTER
  // ------------------------------------------------------------

  void _applyFilter(ProductFilters newFilters) {
    setState(() {
      _filters = newFilters;
    });

    _fetch();
  }

  // ============================================================
  // SORT
  // ============================================================

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return _SortSheet(
          currentSort: _filters.sortBy,
          onSelect: (sort) {
            _applyFilter(
              _filters.copyWith(
                sortBy: sort,
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // PRICE FILTER
  // ============================================================

  void _togglePriceRange(
    double min,
    double? max,
  ) {
    final bool isSame =
        _filters.minPrice == min &&
        _filters.maxPrice == max;

    if (isSame) {
      setState(() {
        _priceRanges = List.of(_priceRangesOriginal);
      });

      _applyFilter(
        _filters.copyWith(
          clearPrice: true,
        ),
      );

      return;
    }

    final selectedRange = _priceRangesOriginal.firstWhere(
      (range) =>
          range[1] == min &&
          range[2] == max,
    );

    setState(() {
      _priceRanges = [
        selectedRange,
        ..._priceRangesOriginal.where(
          (range) => range[0] != selectedRange[0],
        ),
      ];
    });

    _applyFilter(
      _filters.copyWith(
        minPrice: min,
        maxPrice: max,
      ),
    );
  }

  // ============================================================
  // CATEGORY FILTER (sub category sheet)
  // ============================================================

  void _openCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (_) {
        return _CategorySheet(
          categories: _categories,
          currentCategory: _filters.subCategory,
          onSelect: (category) {
            _applyFilter(
              _filters.copyWith(
                subCategory: category,
                clearSubCategory: category == null,
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // CATEGORY LABEL
  // ============================================================

  String _categoryLabel(String key) {
    return _categories.firstWhere(
      (category) =>
          category.toLowerCase() == key.toLowerCase(),
      orElse: () => key,
    );
  }

  // ============================================================
  // CLEAR ALL
  // ============================================================

  void _clearAllFilters() {
    setState(() {
      _priceRanges = List.of(_priceRangesOriginal);

      _filters = ProductFilters(
        category: widget.category,
        shopId: widget.shopId, // <-- ADDED
      );
    });

    _fetch();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isMobile =
        MediaQuery.of(context).size.width < kMobileBreakpoint;

    // Image search returns a single best-match product — a sort/filter
    // bar over one result doesn't mean anything, so it's hidden rather
    // than shown-but-useless.
    final bool showFilterBar = isMobile && widget.searchImage == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showFilterBar)
          _buildFilterBar(),

        const SizedBox(height: 12),

        _buildGrid(),
      ],
    );
  }

  // ============================================================
  // FILTER BAR
  // ============================================================

  Widget _buildFilterBar() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // ------------------------------------------------------
          // SORT
          // ------------------------------------------------------

          _chip(
            label: 'Sort',
            icon: Icons.swap_vert_rounded,
            active:
                _filters.sortBy != SortOption.recent,
            onTap: _openSortSheet,
          ),

          const SizedBox(width: 8),

          // ------------------------------------------------------
          // CATEGORY (sub category)
          // ------------------------------------------------------

          _chip(
            label: _filters.subCategory == null
                ? 'Categories'
                : _categoryLabel(
                    _filters.subCategory!,
                  ),
            icon: Icons.category_outlined,
            active:
                _filters.subCategory != null,
            onTap: _openCategorySheet,
          ),

          const SizedBox(width: 8),


          _chip(
            label: _filters.color ?? 'Color',
            icon: Icons.palette_outlined, // Uses a palette icon
            active: _filters.color != null,
            onTap: _openColorSheet,
          ),
          const SizedBox(width: 8),


          // ------------------------------------------------------
          // PRICE
          // ------------------------------------------------------

          ..._priceRanges.map(
            (range) {
              final String label =
                  range[0] as String;

              final double min =
                  range[1] as double;

              final double? max =
                  range[2] as double?;

              final bool selected =
                  _filters.minPrice == min &&
                  _filters.maxPrice == max;

              return Padding(
                padding:
                    const EdgeInsets.only(
                  right: 8,
                ),
                child: _chip(
                  label: label,
                  active: selected,
                  onTap: () {
                    _togglePriceRange(
                      min,
                      max,
                    );
                  },
                ),
              );
            },
          ),

          // ------------------------------------------------------
          // CLEAR ALL
          // ------------------------------------------------------

          if (!_filters.isDefault) ...[
            const SizedBox(width: 4),

            Center(
              child: GestureDetector(
                onTap: _clearAllFilters,
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 8,
                  ),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      decoration:
                          TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CHIP
  // ============================================================

  Widget _chip({
    required String label,
    IconData? icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color:
              active ? kAccent : Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? kAccent
                : const Color(0xFFDDDDDD),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: active
                    ? Colors.white
                    : Colors.black54,
              ),
              const SizedBox(width: 4),
            ],

            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color: active
                    ? Colors.white
                    : Colors.black87,
              ),
            ),

            if (icon != null) ...[
              const SizedBox(width: 2),

              Icon(
                Icons
                    .keyboard_arrow_down_rounded,
                size: 16,
                color: active
                    ? Colors.white
                    : Colors.black45,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT GRID
  // ============================================================

  Widget _buildGrid() {
    return FutureBuilder<List<ProductModel>>(
      future: _future,
      builder: (
        context,
        snapshot,
      ) {
        // ------------------------------------------------------
        // LOADING
        // ------------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding:
                EdgeInsets.symmetric(
              vertical: 60,
            ),
            child: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        // ------------------------------------------------------
        // ERROR
        // ------------------------------------------------------

        if (snapshot.hasError) {
          return Padding(
            padding:
                const EdgeInsets.symmetric(
              vertical: 60,
            ),
            child: Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons
                        .error_outline,
                    size: 42,
                    color: Colors.grey,
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  const Text(
                    'Something went wrong',
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  TextButton(
                    onPressed: _fetch,
                    child:
                        const Text(
                      'Retry',
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final products =
            snapshot.data ?? [];

        // ------------------------------------------------------
        // EMPTY
        // ------------------------------------------------------

        if (products.isEmpty) {
          final String message = widget.searchImage != null
              ? "We couldn't find a matching product for that photo"
              : (widget.searchQuery != null
                  ? 'No products found for "${widget.searchQuery}"'
                  : 'No products found');

          return Padding(
            padding:
                const EdgeInsets.symmetric(
              vertical: 60,
            ),
            child: Center(
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons
                        .inventory_2_outlined,
                    size: 45,
                    color: Colors.grey,
                  ),

                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ------------------------------------------------------
        // GRID
        // ------------------------------------------------------
        //
        // Uses LayoutBuilder (instead of MediaQuery.of(context).size.width)
        // to size against the space this widget actually has, and guards
        // against a transient 0/invalid width — e.g. during a window
        // resize on web (handleMetricsChanged) or a page-transition frame
        // — which previously crashed with
        // "crossAxisExtent > 0.0 is not true".

        return LayoutBuilder(
          builder: (context, gridConstraints) {
            if (!gridConstraints.maxWidth.isFinite ||
                gridConstraints.maxWidth <= 0) {
              return const SizedBox.shrink();
            }

            final width = gridConstraints.maxWidth;

            final maxExtent =
                width < kMobileBreakpoint ? 200.0 : 240.0;

            // Never let maxCrossAxisExtent exceed the available width —
            // that's what forces crossAxisExtent down to <= 0 on very
            // narrow/transient widths.
            final safeMaxExtent =
                maxExtent > width ? width : maxExtent;

            return GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),

              gridDelegate:
                  SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: safeMaxExtent,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.62,
              ),

              itemCount: products.length,

             /* itemBuilder: (context, index) {
                final product = products[index];

                return ProductCard(
                  product: product,
                  isWishlisted:
                      _wishlistIds.contains(product.id),
                  onWishlistTap: () =>
                      _toggleWishlist(product),
                  onTap: () => _openProduct(product),
                );
              },*/

               itemBuilder: (context, index) {
                final product = products[index];

                return ProductCard(
                  product: product,
                  // Pass the active color filter to the ProductCard
                  color: _filters.color, 
                  isWishlisted: _wishlistIds.contains('${product.id}_${product.productColorId ?? 0}'),
                  onWishlistTap: () => _toggleWishlist(product),
                  onTap: () => _openProduct(product),
                );
              },

            );
          },
        );
      },
    );
  }
}

// ============================================================================
// SORT SHEET
// ============================================================================

class _SortSheet extends StatelessWidget {
  final SortOption currentSort;
  final ValueChanged<SortOption>
      onSelect;

  const _SortSheet({
    required this.currentSort,
    required this.onSelect,
  });

  static const List<SortOption>
      _options = [
    SortOption.priceLowToHigh,
    SortOption.priceHighToLow,
    SortOption.popularity,
    SortOption.discount,
    SortOption.recent,
    SortOption.customerRating,
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                12,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  const Text(
                    'Sort',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  GestureDetector(
                    onTap: () =>
                        Navigator.pop(
                      context,
                    ),
                    child:
                        const Icon(
                      Icons.close,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
            ),

            // --------------------------------------------------
            // OPTIONS
            // --------------------------------------------------

            ..._options.map(
              (option) {
                final selected =
                    option ==
                        currentSort;

                return InkWell(
                  onTap: () {
                    onSelect(option);

                    Navigator.pop(
                      context,
                    );
                  },
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Text(
                      ProductFilters
                          .sortLabel(
                        option,
                      ),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            selected
                                ? FontWeight
                                    .w700
                                : FontWeight
                                    .w400,
                        color: selected
                            ? kAccent
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// CATEGORY SHEET
// ============================================================================

class _CategorySheet
    extends StatefulWidget {
  final List<String> categories;
  final String? currentCategory;
  final ValueChanged<String?>
      onSelect;

  const _CategorySheet({
    required this.categories,
    required this.currentCategory,
    required this.onSelect,
  });

  @override
  State<_CategorySheet>
      createState() =>
          _CategorySheetState();
}

class _CategorySheetState
    extends State<_CategorySheet> {
  late String? _selected;

  @override
  void initState() {
    super.initState();

    _selected =
        widget.currentCategory;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 8,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HEADER
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                20,
                8,
                20,
                16,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),

                  GestureDetector(
                    onTap: () =>
                        Navigator.pop(
                      context,
                    ),
                    child:
                        const Icon(
                      Icons.close,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // CATEGORY CHIPS
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    widget.categories.map(
                  (category) {
                    final key =
                        category.toLowerCase();

                    final selected =
                        _selected == key;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selected =
                              selected
                                  ? null
                                  : key;
                        });
                      },
                      child:
                          Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration:
                            BoxDecoration(
                          color: selected
                              ? kAccent
                                  .withOpacity(
                                  0.12,
                                )
                              : Colors.white,

                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),

                          border:
                              Border.all(
                            color: selected
                                ? kAccent
                                : Colors.black26,
                            width: selected
                                ? 1.4
                                : 1,
                          ),
                        ),

                        child: Text(
                          category,
                          style:
                              TextStyle(
                            fontSize: 14,
                            fontWeight:
                                selected
                                    ? FontWeight
                                        .w700
                                    : FontWeight
                                        .w600,
                            color: selected
                                ? kAccent
                                : Colors
                                    .black87,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Divider(
              height: 1,
            ),

            const SizedBox(
              height: 12,
            ),

            // --------------------------------------------------
            // BUTTONS
            // --------------------------------------------------

            Padding(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
              ),
              child: Row(
                children: [
                  // CLEAR
                  Expanded(
                    child:
                        OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selected =
                              null;
                        });

                        widget.onSelect(
                          null,
                        );

                        Navigator.pop(
                          context,
                        );
                      },
                      style:
                          OutlinedButton
                              .styleFrom(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                        side:
                            const BorderSide(
                          color:
                              Colors.black26,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        'Clear All',
                        style:
                            TextStyle(
                          color:
                              Colors.black87,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  // APPLY
                  Expanded(
                    flex: 2,
                    child:
                        ElevatedButton(
                      onPressed: () {
                        widget.onSelect(
                          _selected,
                        );

                        Navigator.pop(
                          context,
                        );
                      },
                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            kAccent,
                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            12,
                          ),
                        ),
                      ),
                      child:
                          const Text(
                        'Apply Filters',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSheet extends StatefulWidget {
  final List<String> colors;
  final String? currentColor;
  final ValueChanged<String?> onSelect;

  const _ColorSheet({
    required this.colors,
    required this.currentColor,
    required this.onSelect,
  });

  @override
  State<_ColorSheet> createState() => _ColorSheetState();
}

class _ColorSheetState extends State<_ColorSheet> {
  late String? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentColor;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Colors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.colors.map((color) {
                  final key = color.toLowerCase();
                  final selected = _selected == key;

                  return GestureDetector(
                    onTap: () => setState(() => _selected = selected ? null : key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? kAccent.withOpacity(0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? kAccent : Colors.black26,
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Text(
                        color,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                          color: selected ? kAccent : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _selected = null);
                        widget.onSelect(null);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.black26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Clear All', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSelect(_selected);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}