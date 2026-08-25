import 'package:flutter/material.dart';
import 'product_filters.dart';
import '../../../models/product_model.dart';
import '../../../services/product_service.dart';
import '../../../widgets/product_card.dart';
 
const double kMobileBreakpoint = 600;
const Color kAccent = Color(0xFFB8956A);
 
class ProductGrid extends StatefulWidget {
  /// 'all' | 'men' | 'women' | 'kids' | 'beauty' — set by the parent tab.
  final String gender;
 
  const ProductGrid({super.key, required this.gender});
 
  @override
  State<ProductGrid> createState() => _ProductGridState();
}
 
class _ProductGridState extends State<ProductGrid> {
  late ProductFilters _filters = ProductFilters(gender: widget.gender);
  late Future<List<ProductModel>> _future;
 
  static const _categories = ['Saree', 'Shirt', 'T Shirts', 'Pant', 'Kids'];
 
  // label, min, max(nullable = no upper bound) — original fixed order
  static const _priceRangesOriginal = [
    ['Under ₹199', 0.0, 199.0],
    ['₹200 - ₹499', 200.0, 499.0],
    ['₹500 - ₹999', 500.0, 999.0],
    ['₹1000 & Above', 1000.0, null],
  ];
 
  // Current display order — selected range moves to the front
  late List<List<dynamic>> _priceRanges = List.of(_priceRangesOriginal);
 
  @override
  void initState() {
    super.initState();
    _fetch();
  }
 
  @override
  void didUpdateWidget(covariant ProductGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender) {
      _filters = _filters.copyWith(gender: widget.gender);
      _fetch();
    }
  }
 
  void _fetch() {
    setState(() {
      _future = ProductService.getProducts(filters: _filters.toQueryParams());
    });
  }
 
  void _applyFilter(ProductFilters newFilters) {
    setState(() => _filters = newFilters);
    _fetch();
  }
 
  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SortSheet(
        currentSort: _filters.sortBy,
        onSelect: (sort) => _applyFilter(_filters.copyWith(sortBy: sort)),
      ),
    );
  }
 
  // Price — tap toggles directly on the chip bar (no sheet)
  // Selected range moves to the front; deselecting restores original order.
  void _togglePriceRange(double min, double? max) {
    final isSame = _filters.minPrice == min && _filters.maxPrice == max;
 
    setState(() {
      if (isSame) {
        _priceRanges = List.of(_priceRangesOriginal);
      } else {
        final selectedRange = _priceRangesOriginal.firstWhere(
          (r) => r[1] == min && r[2] == max,
        );
        _priceRanges = [
          selectedRange,
          ..._priceRangesOriginal.where((r) => r[0] != selectedRange[0]),
        ];
      }
    });
 
    _applyFilter(_filters.copyWith(
      minPrice: isSame ? null : min,
      maxPrice: isSame ? null : max,
      clearPrice: isSame,
    ));
  }
 
  // ── Category dropdown sheet — single-select, partial-match on backend ──
  void _openCategorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CategorySheet(
        categories: _categories,
        currentCategory: _filters.category,
        onSelect: (cat) => _applyFilter(_filters.copyWith(
          category: cat,
          clearCategory: cat == null,
        )),
      ),
    );
  }
 
  String _categoryLabel(String key) {
    // key is stored lowercase e.g. "t shirts" -> display "T Shirts"
    return _categories.firstWhere(
      (c) => c.toLowerCase() == key,
      orElse: () => key,
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) _buildFilterBar(),
        const SizedBox(height: 12),
        _buildGrid(),
      ],
    );
  }
 
  // ── Horizontal scrollable filter bar — Myntra style ─────────────────────
  Widget _buildFilterBar() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Sort
          _chip(
            label: 'Sort',
            icon: Icons.swap_vert_rounded,
            active: _filters.sortBy != SortOption.recent,
            onTap: _openSortSheet,
          ),
          const SizedBox(width: 8),
 
          // Category — single chip, opens dropdown sheet
          _chip(
            label: _filters.category == null
                ? 'Categories'
                : _categoryLabel(_filters.category!),
            icon: Icons.category_outlined,
            active: _filters.category != null,
            onTap: _openCategorySheet,
          ),
          const SizedBox(width: 8),
 
          // Price ranges — individual chips, tap toggles directly
          ..._priceRanges.map((r) {
            final label = r[0] as String;
            final min = r[1] as double;
            final max = r[2] as double?;
            final selected = _filters.minPrice == min && _filters.maxPrice == max;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _chip(
                label: label,
                active: selected,
                onTap: () => _togglePriceRange(min, max),
              ),
            );
          }),
 
          if (!_filters.isDefault) ...[
            const SizedBox(width: 4),
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() => _priceRanges = List.of(_priceRangesOriginal));
                  _applyFilter(ProductFilters(gender: widget.gender));
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Clear all',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      decoration: TextDecoration.underline,
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
 
  Widget _chip({
    required String label,
    IconData? icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? kAccent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? kAccent : const Color(0xFFDDDDDD),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: active ? Colors.white : Colors.black54),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : Colors.black87,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 2),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 16, color: active ? Colors.white : Colors.black45),
            ],
          ],
        ),
      ),
    );
  }
 
  Widget _buildGrid() {
    return FutureBuilder<List<ProductModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: Text('Something went wrong')),
          );
        }
        final products = snapshot.data ?? [];
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: Text('No products found')),
          );
        }
        final width = MediaQuery.of(context).size.width;
        // Fixed card width target — GridView auto-fits as many columns as
        // fit that width, so desktop gets more (smaller) columns instead
        // of the same 2 huge cards used on mobile.
        final maxExtent = width < kMobileBreakpoint ? 200.0 : 240.0;
 
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.62,
          ),
          itemCount: products.length,
          itemBuilder: (context, i) => ProductCard(product: products[i]),
        );
      },
    );
  }
}
 
// ── Sort bottom sheet — matches the Myntra screenshot exactly ────────────
class _SortSheet extends StatelessWidget {
  final SortOption currentSort;
  final ValueChanged<SortOption> onSelect;
 
  const _SortSheet({required this.currentSort, required this.onSelect});
 
  static const _options = [
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Sort',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ..._options.map((opt) {
              final selected = opt == currentSort;
              return InkWell(
                onTap: () {
                  onSelect(opt);
                  Navigator.pop(context);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Text(
                    ProductFilters.sortLabel(opt),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? kAccent : Colors.black87,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
 
// ── Category bottom sheet — Myntra-style chip grid + Clear All / Apply ───
class _CategorySheet extends StatefulWidget {
  final List<String> categories;
  final String? currentCategory; // stored as lowercase key
  final ValueChanged<String?> onSelect;
 
  const _CategorySheet({
    required this.categories,
    required this.currentCategory,
    required this.onSelect,
  });
 
  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}
 
class _CategorySheetState extends State<_CategorySheet> {
  late String? _selected = widget.currentCategory;
 
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Categories',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, size: 22),
                  ),
                ],
              ),
            ),
 
            // Chip grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.categories.map((cat) {
                  final key = cat.toLowerCase();
                  final selected = _selected == key;
                  return GestureDetector(
                    onTap: () => setState(() {
                      // tap again to deselect
                      _selected = selected ? null : key;
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? kAccent.withOpacity(0.12) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected ? kAccent : Colors.black26,
                          width: selected ? 1.4 : 1,
                        ),
                      ),
                      child: Text(
                        cat,
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
 
            // Clear All / Apply Filters
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Clear All',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
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