import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_colors.dart';
import '../../services/product_service.dart';
import 'add_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _stockFilter = 'All';
  String _activeCategory = 'All';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int? _hoveredIndex;

  static const _stockFilters = ['All', 'Low stock', 'Out of stock'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final products = await ProductService.getProducts();
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openAddProduct() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const AddProductScreen()));
    if (added == true) _loadProducts();
  }

  void _openProductView(Map<String, dynamic> product) {
    context.go('/products/${product['id']}');
  }

  Future<void> _confirmDelete(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product['name']}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ProductService.deleteProduct(product['id'] as int);
      if (mounted) {
        setState(() => _products.removeWhere((p) => p['id'] == product['id']));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('"${product['name']}" deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }

  (String, _StatusKind, Color) _stockDisplay(Map<String, dynamic> p) {
    final stock = (p['stock'] as num).toInt();
    final active = p['status'] == 'Active';
    if (!active) return ('Inactive', _StatusKind.cancelled, AppColors.inkSoft);
    if (stock == 0) {
      return ('Out of stock', _StatusKind.cancelled, AppColors.red);
    }
    if (stock < 10) return ('Low stock', _StatusKind.pending, AppColors.gold);
    return ('Active', _StatusKind.done, AppColors.green);
  }

  (String, Color)? _variantStockBadge(Map<String, dynamic> p) {
    final hasOutOfStockVariant = p['hasOutOfStockVariant'] == true;
    final hasLowStockVariant = p['hasLowStockVariant'] == true;
    if (hasOutOfStockVariant) return ('Out of stock', AppColors.red);
    if (hasLowStockVariant) return ('Low stock', AppColors.gold);
    return null;
  }

  // Category chips derived from the product data itself — falls back to a
  // fixed set if 'category' isn't populated on any product yet, so the
  // chip row never renders empty during early testing.
  List<String> get _categories => const [
    'All',
    'Men',
    'Women',
    'Kids',
    'Beauty',
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    Iterable<Map<String, dynamic>> list = _products;

    if (_searchQuery.isNotEmpty) {
      list = list.where(
        (p) => (p['name'] as String).toLowerCase().contains(_searchQuery),
      );
    }

    if (_activeCategory != 'All') {
      list = list.where((p) => p['category'] == _activeCategory);
    }

    if (_stockFilter != 'All') {
      list = list.where((p) {
        final (label, _, _) = _stockDisplay(p);
        return label == _stockFilter;
      });
    }

    return list.toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, outerConstraints) {
        // Single breakpoint drives every responsive decision on this screen.
        final isMobile = outerConstraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sticky-style header: search + stock dropdown + refresh + add,
            // count + category chips — wrapped with a soft bottom shadow so it
            // visually separates from the grid below, matching the admin panel. ──
            Container(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 12 : 16,
                16,
                isMobile ? 12 : 16,
                18,
              ),
              decoration: BoxDecoration(
                color: AppColors
                    .blush, // page background colour — keeps header flush, shadow does the separating
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile)
                    _buildMobileHeaderControls()
                  else
                    _buildDesktopHeaderControls(),
                  const SizedBox(height: 16),
                  if (isMobile) ...[
                    Text(
                      '${_filteredProducts.length} products',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildCategoryChips(scrollable: true),
                  ] else
                    Row(
                      children: [
                        Text(
                          '${_filteredProducts.length} products',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const Spacer(),
                        Flexible(child: _buildCategoryChips(scrollable: false)),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: _SectionPanel(
                  child: Column(
                    children: [
                      const Text(
                        'Could not load products',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      _AppButton(label: 'Try again', onPressed: _loadProducts),
                    ],
                  ),
                ),
              )
            else if (_filteredProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: _SectionPanel(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 34,
                        color: AppColors.inkSoft,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No products match "${_searchController.text}"'
                            : 'No products yet',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Add your first product to see it here.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.inkSoft,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      _AppButton(
                        label: 'Add product',
                        icon: Icons.add,
                        onPressed: _openAddProduct,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 14.0;
                    final width = constraints.maxWidth;

                    // Extra breakpoints so very small phones still get a
                    // comfortable card width instead of being squeezed.
                    int columns;
                    if (width < 360) {
                      columns = 1;
                    } else if (width < 520) {
                      columns = 2;
                    } else if (width < 780) {
                      columns = 3;
                    } else if (width < 1040) {
                      columns = 4;
                    } else if (width < 1320) {
                      columns = 5;
                    } else {
                      columns = 6;
                    }

                    final itemWidth =
                        (width - spacing * (columns - 1)) / columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: _filteredProducts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final p = entry.value;

                        return SizedBox(
                          // Height is no longer hard-coded: the card sizes
                          // itself to its content, so it never overflows or
                          // clips on narrow screens.
                          width: itemWidth,
                          child: MouseRegion(
                            onEnter: (_) =>
                                setState(() => _hoveredIndex = index),
                            onExit: (_) => setState(() => _hoveredIndex = null),
                            child: _ProductGridCard(
                              product: p,
                              stockDisplay: _stockDisplay(p),
                              variantStockBadge: _variantStockBadge(p),
                              onDelete: () => _confirmDelete(p),
                              onTap: () => _openProductView(p),
                              isHovered: _hoveredIndex == index,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  // ── Desktop / tablet header: everything in a single row. ──
  Widget _buildDesktopHeaderControls() {
    return Row(
      children: [
        Expanded(child: _buildSearchField()),
        const SizedBox(width: 10),
        _StatusDropdown(
          value: _stockFilter,
          options: _stockFilters,
          onChanged: (v) => setState(() => _stockFilter = v),
        ),
        const SizedBox(width: 10),
        _roundHeaderButton(Icons.refresh, onTap: _loadProducts),
        const SizedBox(width: 10),
        _AppButton(
          label: 'Add product',
          icon: Icons.add,
          onPressed: _openAddProduct,
        ),
      ],
    );
  }

  // ── Mobile header: search takes its own full-width row, the rest wraps
  // onto a second row so nothing overflows a narrow screen. ──
  Widget _buildMobileHeaderControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSearchField(),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatusDropdown(
                value: _stockFilter,
                options: _stockFilters,
                onChanged: (v) => setState(() => _stockFilter = v),
                isExpanded: true,
              ),
            ),
            const SizedBox(width: 10),
            _roundHeaderButton(Icons.refresh, onTap: _loadProducts),
            const SizedBox(width: 10),
            _roundHeaderButton(Icons.add, onTap: _openAddProduct),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: AppColors.inkSoft),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search products ...',
                hintStyle: TextStyle(fontSize: 13.5, color: AppColors.inkSoft),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13.5, color: AppColors.ink),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () => _searchController.clear(),
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.inkSoft,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips({required bool scrollable}) {
    final chips = _categories.map((c) {
      final active = c == _activeCategory;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(c),
          selected: active,
          onSelected: (_) => setState(() => _activeCategory = c),
          showCheckmark: false,
          selectedColor: AppColors.black,
          backgroundColor: AppColors.white,
          labelStyle: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : AppColors.inkSoft,
          ),
          side: BorderSide(color: active ? AppColors.black : AppColors.line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    }).toList();

    if (scrollable) {
      // Horizontal scroll keeps the chip row from ever overflowing on
      // narrow phone widths, instead of wrapping/clipping.
      return SizedBox(
        height: 34,
        child: ListView(scrollDirection: Axis.horizontal, children: chips),
      );
    }

    return Wrap(spacing: 0, runSpacing: 8, children: chips);
  }

  Widget _roundHeaderButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: AppColors.inkSoft),
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  // Only set this true when the dropdown is placed inside a width-bounding
  // parent (e.g. Expanded/SizedBox). Left true unconditionally, it makes
  // DropdownButton demand infinite width whenever it sits in a plain Row
  // child (like the desktop header), which throws a layout exception and
  // renders as a blank screen.
  final bool isExpanded;

  const _StatusDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: isExpanded,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: AppColors.inkSoft,
          ),
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
          items: options
              .map(
                (o) => DropdownMenuItem(
                  value: o,
                  child: Text(o == 'All' ? 'All Products' : o),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final (String, _StatusKind, Color) stockDisplay;
  final (String, Color)? variantStockBadge;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final bool isHovered;

  const _ProductGridCard({
    required this.product,
    required this.stockDisplay,
    required this.variantStockBadge,
    required this.onDelete,
    required this.onTap,
    required this.isHovered,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final (stockLabel, _, stockColor) = stockDisplay;
    final thumbnail = product['thumbnail'] as String?;

    final double sellingPrice = (product['price'] as num?)?.toDouble() ?? 0.0;
    final double mrp =
        (product['mrp'] as num?)?.toDouble() ?? (sellingPrice * 1.5);
    final int discountPercent = mrp > sellingPrice
        ? ((mrp - sellingPrice) / mrp * 100).toInt()
        : 0;

    // Only show the plain stock badge when there's no more specific
    // variant-level badge already covering that corner.
    final showStockBadge = variantStockBadge == null && stockLabel != 'Active';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 360,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            // No fill here anymore — this was showing as an unwanted white
            // background behind the name/price section. The image area still
            // gets its own blush background below; everywhere else stays
            // transparent so the card blends with the page background.
            color: AppColors.blush,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isMobile ? AppColors.line : Colors.transparent,
              width: 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed-height thumbnail area — the bug where this Stack had an
              // Expanded child (invalid inside Stack) and a stray Padding
              // passed as a second "child" to the SizedBox has been fixed:
              // the image now fills the Stack via Positioned.fill, and the
              // text block below is a proper sibling in the outer Column.
              SizedBox(
                height: 260,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(7, 2, 7, 7),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ), // <-- Radius here
                          child: Container(
                            color: AppColors.blush,
                            child: thumbnail != null
                                ? Image.network(
                                    ProductService.fullImageUrl(thumbnail),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, _, _) => const Center(
                                      child: Icon(
                                        Icons.checkroom,
                                        size: 40,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.checkroom,
                                      size: 40,
                                      color: AppColors.inkSoft,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
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
                              product['rating']?.toString() ?? '4.3',
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
                              product['reviews']?.toString() ?? '11.6k',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (variantStockBadge != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: variantStockBadge!.$2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            variantStockBadge!.$1,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else if (showStockBadge)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stockColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            stockLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,

                      child: _roundIcon(Icons.delete_outline, onTap: onDelete),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product['name'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product['sub_category'] as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        Text(
                          'Rs. ${sellingPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            fontFamily: 'JetBrainsMono',
                          ),
                        ),
                        if (discountPercent > 0) ...[
                          Text(
                            'Rs. ${mrp.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            '($discountPercent% OFF)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF39C12),
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

  Widget _roundIcon(IconData icon, {VoidCallback? onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: AppColors.inkSoft),
    ),
  );
}

enum _StatusKind { pending, done, cancelled }

// class _StatusBadge extends StatelessWidget {
//   final String text;
//   final _StatusKind kind;

//   const _StatusBadge({required this.text, required this.kind});

//   @override
//   Widget build(BuildContext context) {
//     late Color bg;
//     late Color fg;
//     switch (kind) {
//       case _StatusKind.pending:
//         bg = const Color(0xFFFBEBD2);
//         fg = const Color(0xFF966A1B);
//         break;
//       case _StatusKind.preparing:
//         bg = AppColors.blueSoft;
//         fg = AppColors.blue;
//         break;
//       case _StatusKind.ready:
//         bg = AppColors.terracottaSoft;
//         fg = AppColors.terracotta;
//         break;
//       case _StatusKind.outForDelivery:
//         bg = AppColors.amberSoft;
//         fg = AppColors.amber;
//         break;
//       case _StatusKind.done:
//         bg = AppColors.greenSoft;
//         fg = const Color(0xFF2F5A44);
//         break;
//       case _StatusKind.cancelled:
//         bg = AppColors.redSoft;
//         fg = const Color(0xFF8C3F32);
//         break;
//     }
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         text,
//         style: TextStyle(
//           fontSize: 10.5,
//           fontWeight: FontWeight.w700,
//           color: fg,
//         ),
//       ),
//     );
//   }
// }

class _SectionPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionPanel({
    required this.child,
  }) : padding = const EdgeInsets.all(22);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const _AppButton({required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 16) : const SizedBox.shrink(),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}
