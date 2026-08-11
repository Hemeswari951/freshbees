// Admin Products Screen

import 'package:flutter/material.dart';
import '../../widgets/t_colors.dart';
import '../../services/product_service.dart';
import 'product_view_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin — All Products screen
// Pulls every product from every shop directly from the admin products
// endpoint (GET /api/admin/products) — no more fetching every shop one by
// one and flattening client-side, the backend does that join now.
// ─────────────────────────────────────────────────────────────────────────────
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool _isLoading = true;
  String? _error;
  int? _hoveredIndex;

  // Every product, every shop — already flat, already tagged with shop
  // context (shopId/shopName) by the backend.
  List<Map<String, dynamic>> _allProducts = [];

  String _search = '';
  String _statusFilter = 'All';

  String _genderFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  // ── Load: one call, backend already joins shop + stock + thumbnail ────────
  Future<void> _loadAllProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await ProductService.getAllProducts();
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── Filters ─────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredProducts {
    return _allProducts.where((p) {
      // ⚠️ NOTE: the admin backend doesn't have a generic "gender" field —
      // this matches against categoryName as the closest available column.
      // If Men/Women/Kids/Beauty is actually a separate top-level category
      // in your categories table, swap this to whatever field represents
      // that (and add it to findAllProductsAdmin's SELECT if it's missing).
      final matchGender =
          _genderFilter == 'All' || p['categoryName'] == _genderFilter;

      final matchStatus =
          _statusFilter == 'All' ||
          (_statusFilter == 'Active' && (p['isActive'] ?? true)) ||
          (_statusFilter == 'Inactive' && !(p['isActive'] ?? true));

      final matchSearch =
          _search.isEmpty ||
          (p['productName'] as String? ?? '').toLowerCase().contains(
            _search.toLowerCase(),
          ) ||
          (p['shopName'] as String? ?? '').toLowerCase().contains(
            _search.toLowerCase(),
          );
      return matchGender && matchStatus && matchSearch;
    }).toList();
  }

  // Uses the backend's own has_out_of_stock flag (true if ANY variant of
  // the product is at 0) rather than recomputing from a single stock
  // number — more accurate for multi-size/multi-color products.
  int get _outOfStockCount =>
      _allProducts.where((p) => p['hasOutOfStock'] == true).length;

  int get _inactiveProductsCount =>
      _allProducts.where((p) => (p['isActive'] ?? true) == false).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 34,
                color: TColors.brownLight,
              ),
              const SizedBox(height: 10),
              const Text(
                'Could not load products',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: TColors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: TColors.brownLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _loadAllProducts,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    final products = _filteredProducts;

    return RefreshIndicator(
      onRefresh: _loadAllProducts,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: TColors.cream,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(children: [_statsRow(), _controlsRow()]),
            ),
          ),
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  _allProducts.isEmpty
                      ? 'No products yet'
                      : 'No products found',
                  style: const TextStyle(
                    fontSize: 13,
                    color: TColors.brownLight,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  int columns;
                  if (width < 520) {
                    columns = 2;
                  } else if (width < 780) {
                    columns = 3;
                  } else {
                    columns = 4;
                  }
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 30,
                      mainAxisSpacing: 30,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _productCard(products[i], i),
                      childCount: products.length,
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ── Header stats ────────────────────────────────────────────────────────
  Widget _statsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          _statCard(
            'Total products',
            '${_allProducts.length}',
            Icons.inventory_2_outlined,
            const Color(0xFFE1F5EE),
            const Color(0xFF1D9E75),
          ),
          const SizedBox(width: 12),

          _statCard(
            'Out of stock',
            '$_outOfStockCount',
            Icons.remove_shopping_cart_outlined,
            const Color(0xFFFCEBEB),
            const Color(0xFFA32D2D),
          ),
          const SizedBox(width: 12),

          _statCard(
            'Inactive Products',
            '$_inactiveProductsCount',
            Icons.visibility_off_outlined,
            const Color(0xFFFFF4E5),
            const Color(0xFFE67E22),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color bg,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: TColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: TColors.black,
                    ),
                  ),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: TColors.brownLight,
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

  // ── Search + filters ────────────────────────────────────────────────────
  Widget _controlsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    onChanged: (val) => setState(() => _search = val),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search products ...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor: TColors.white,
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: TColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: TColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: TColors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              _statusDropdown(),

              const SizedBox(width: 10),

              IconButton(
                onPressed: _loadAllProducts,
                icon: const Icon(Icons.refresh, size: 18, color: TColors.black),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${_filteredProducts.length} products',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TColors.black,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                children: [
                  'All',
                  'Men',
                  'Women',
                  'Kids',
                  'Beauty',
                ].map(_genderChip).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Products')),
            DropdownMenuItem(value: 'Active', child: Text('Active')),
            DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _statusFilter = value);
            }
          },
        ),
      ),
    );
  }

  Widget _genderChip(String label) {
    final active = _genderFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _genderFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? TColors.black : TColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? TColors.black : TColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? TColors.white : TColors.brown,
          ),
        ),
      ),
    );
  }

  // ── Product card (Matches ShopOwner styling + Right-aligned stock tag) ──
  Widget _productCard(Map<String, dynamic> p, int index) {
    final int stock = (p['stock'] as num?)?.toInt() ?? 0;
    final bool outOfStock = p['hasOutOfStock'] == true;
    final bool lowStock = !outOfStock && p['hasLowStock'] == true;

    // --- Rating / Price logic ---
    // avgRating/reviews aren't returned by the admin list endpoint yet
    // (no ratings join there) — keep the same placeholder fallback
    // behavior as before until that's added.
    final double rating = (p['avgRating'] as num?)?.toDouble() ?? 4.3;
    final String reviews = p['reviews']?.toString() ?? '11.6k';
    final double sellingPrice = (p['price'] as num?)?.toDouble() ?? 0.0;
    final double mrp = (p['mrp'] as num?)?.toDouble() ?? (sellingPrice * 1.5);
    final int discountPercent =
        (p['discountPercent'] as num?)?.toInt() ??
        (mrp > sellingPrice ? (((mrp - sellingPrice) / mrp) * 100).toInt() : 0);

    // --- Metadata logic ---
    final String? imagePath = p['image'] as String?;
    final String imageUrl = imagePath != null
        ? ProductService.fullImageUrl(imagePath)
        : '';
    final String shopName = p['shopName'] as String? ?? 'Unknown Shop';
    final int shopId = p['shopId'] as int? ?? 0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hoveredIndex = index);
      },
      onExit: (_) {
        setState(() => _hoveredIndex = null);
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductViewScreen(productId: p['productId']),
            ),
          );
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            boxShadow: _hoveredIndex == index
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base Image
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                      // color: TColors.cream,
                      alignment: Alignment.center,
                      child: imagePath != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.checkroom_outlined,
                                size: 40,
                                color: TColors.brownLight,
                              ),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            )
                          : const Icon(
                              Icons.checkroom_outlined,
                              size: 40,
                              color: TColors.brownLight,
                            ),
                    ),

                    // White Rating & Reviews pill
                    Positioned(
                      bottom: 15,
                      left: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
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
                            const Icon(
                              Icons.star,
                              size: 11,
                              color: Colors.teal,
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 1,
                              height: 10,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              reviews,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Low Stock Tag
                    if (lowStock)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE05656),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Only $stock left',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: TColors.white,
                            ),
                          ),
                        ),
                      ),

                    // Out of Stock Overlay
                    if (outOfStock)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          color: const Color(0xFFE05656),
                          child: const Text(
                            'OUT OF STOCK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: TColors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Text Details Section
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Name
                    Text(
                      p['productName'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: TColors.black,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Product Category
                    Text(
                      p['subCategory'] as String? ?? 'Uncategorized',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: TColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Shop Name (Restored - highly recommended for Admin screen)
                    /*Row(
                    children: [
                      const Icon(Icons.storefront_outlined, size: 11, color: TColors.brownLight),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: TColors.brownLight),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),*/

                    // Myntra-style Pricing Row
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        Text(
                          'Rs. ${sellingPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: TColors.black,
                          ),
                        ),
                        if (discountPercent > 0) ...[
                          Text(
                            'Rs. ${mrp.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            '($discountPercent% OFF)',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color.fromARGB(255, 46, 114, 52),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
