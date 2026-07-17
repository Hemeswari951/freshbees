import 'package:flutter/material.dart';
import '../../widgets/app_colors.dart';
import '../../services/product_service.dart';
import 'add_product_screen.dart';
import 'product_view_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _activeFilter = 'All';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];

  static const _filters = ['All', 'In stock', 'Low stock', 'Out of stock'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
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
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
    );
    if (added == true) _loadProducts();
  }

  // Opens the customer-facing preview (image slider, colors, sizes, price) —
  // this is what the shop owner sees when they tap a product card/row.
  void _openProductView(Map<String, dynamic> product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductViewScreen(productId: product['id'] as int)),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('"${product['name']}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${product['name']}" deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  // Stock badge is computed from live stock count, not just is_active,
  // so "Low stock" / "Out of stock" always reflect the real numbers.
  (String, _StatusKind, Color) _stockDisplay(Map<String, dynamic> p) {
    final stock = (p['stock'] as num).toInt();
    final active = p['status'] == 'Active';
    if (!active) return ('Inactive', _StatusKind.cancelled, AppColors.inkSoft);
    if (stock == 0) return ('Out of stock', _StatusKind.cancelled, AppColors.red);
    if (stock < 10) return ('Low stock', _StatusKind.pending, AppColors.gold);
    return ('Active', _StatusKind.done, AppColors.green);
  }

  List<Map<String, dynamic>> get _filteredProducts {
    if (_activeFilter == 'All') return _products;
    return _products.where((p) {
      final (label, _, _) = _stockDisplay(p);
      if (_activeFilter == 'In stock') return label == 'Active';
      return label == _activeFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toolbar
        Wrap(
          spacing: 14,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Wrap(
              spacing: 8,
              children: _filters.map((f) {
                final active = f == _activeFilter;
                return ChoiceChip(
                  label: Text(f == 'All' ? 'All (${_products.length})' : f),
                  selected: active,
                  onSelected: (_) => setState(() => _activeFilter = f),
                  selectedColor: AppColors.black,
                  backgroundColor: AppColors.white,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.inkSoft,
                  ),
                  side: BorderSide(color: active ? AppColors.black : AppColors.line),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            IconButton(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh, size: 18, color: AppColors.inkSoft),
              tooltip: 'Refresh',
            ),
            const Spacer(),
            _AppButton(label: 'Add product', icon: Icons.add, onPressed: _openAddProduct),
          ],
        ),
        const SizedBox(height: 20),

        if (_loading)
          const Padding(padding: EdgeInsets.only(top: 60), child: Center(child: CircularProgressIndicator()))
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: _SectionPanel(
              child: Column(
                children: [
                  const Text('Could not load products', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Text(_error!, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft), textAlign: TextAlign.center),
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
                  const Icon(Icons.inventory_2_outlined, size: 34, color: AppColors.inkSoft),
                  const SizedBox(height: 10),
                  const Text('No products yet', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  const Text('Add your first product to see it here.', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                  const SizedBox(height: 14),
                  _AppButton(label: 'Add product', icon: Icons.add, onPressed: _openAddProduct),
                ],
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final bool narrow = constraints.maxWidth < 700;

              if (narrow) {
                const spacing = 12.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _filteredProducts
                      .map((p) => SizedBox(
                            width: itemWidth,
                            child: _ProductGridCard(
                              product: p,
                              stockDisplay: _stockDisplay(p),
                              onDelete: () => _confirmDelete(p),
                              onTap: () => _openProductView(p),
                            ),
                          ))
                      .toList(),
                );
              }

              return _SectionPanel(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columnSpacing: 24,
                      horizontalMargin: 16,
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStateProperty.all(AppColors.white),
                      dataRowMinHeight: 60,
                      dataRowMaxHeight: 68,
                      columns: const [
                        DataColumn(label: Text('PRODUCT', style: _headStyle)),
                        DataColumn(label: Text('PRICE', style: _headStyle)),
                        DataColumn(label: Text('STOCK', style: _headStyle)),
                        DataColumn(label: Text('STATUS', style: _headStyle)),
                        DataColumn(label: Text('', style: _headStyle)),
                      ],
                      rows: _filteredProducts.map((p) {
                        final (label, kind, stockColor) = _stockDisplay(p);
                        final thumbnail = p['thumbnail'] as String?;
                        return DataRow(
                          onSelectChanged: (_) => _openProductView(p),
                          cells: [
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _thumb(thumbnail),
                              const SizedBox(width: 12),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 220),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(p['name'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.ink)),
                                    Text(p['category'] as String? ?? 'Uncategorized',
                                        style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft)),
                                  ],
                                ),
                              ),
                            ],
                          )),
                          DataCell(Text('₹${(p['price'] as num).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13.5))),
                          DataCell(Text('${p['stock']} units',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: stockColor))),
                          DataCell(_StatusBadge(text: label, kind: kind)),
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _actionIcon(Icons.delete_outline, onTap: () => _confirmDelete(p)),
                            ],
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  static const _headStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.inkSoft);
}

Widget _thumb(String? relativePath) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(10)),
    clipBehavior: Clip.antiAlias,
    alignment: Alignment.center,
    child: relativePath != null
        ? Image.network(
            ProductService.fullImageUrl(relativePath),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 16, color: AppColors.inkSoft),
          )
        : const Icon(Icons.checkroom, size: 18, color: AppColors.inkSoft),
  );
}

Widget _actionIcon(IconData icon, {VoidCallback? onTap}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 14, color: AppColors.inkSoft),
    ),
  );
}

/// Mobile-width e-commerce style product card, same visual language as
/// before but now backed by real API data.
class _ProductGridCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final (String, _StatusKind, Color) stockDisplay;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _ProductGridCard({required this.product, required this.stockDisplay, required this.onDelete, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (label, kind, stockColor) = stockDisplay;
    final thumbnail = product['thumbnail'] as String?;
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.05,
                child: Container(
                  color: AppColors.blush,
                  alignment: Alignment.center,
                  child: thumbnail != null
                      ? Image.network(
                          ProductService.fullImageUrl(thumbnail),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => const Icon(Icons.checkroom, size: 40, color: AppColors.inkSoft),
                        )
                      : const Icon(Icons.checkroom, size: 40, color: AppColors.inkSoft),
                ),
              ),
              Positioned(top: 8, left: 8, child: _StatusBadge(text: label, kind: kind)),
              Positioned(
                top: 6,
                right: 6,
                child: _roundIcon(Icons.delete_outline, onTap: onDelete),
              ),
            ],
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
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  product['category'] as String? ?? 'Uncategorized',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${(product['price'] as num).toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'JetBrainsMono'),
                ),
                const SizedBox(height: 4),
                Text('${product['stock']} units', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: stockColor)),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _roundIcon(IconData icon, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.92), shape: BoxShape.circle),
          child: Icon(icon, size: 13, color: AppColors.inkSoft),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Local replacements for what used to come from common_widgets.dart.
// Kept private (_prefixed) since only this file needs them.
// ─────────────────────────────────────────────────────────────

enum _StatusKind { pending, preparing, ready, outForDelivery, done, cancelled }

class _StatusBadge extends StatelessWidget {
  final String text;
  final _StatusKind kind;

  const _StatusBadge({required this.text, required this.kind});

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    switch (kind) {
      case _StatusKind.pending:
        bg = const Color(0xFFFBEBD2);
        fg = const Color(0xFF966A1B);
        break;
      case _StatusKind.preparing:
        bg = AppColors.blueSoft;
        fg = AppColors.blue;
        break;
      case _StatusKind.ready:
        bg = AppColors.terracottaSoft;
        fg = AppColors.terracotta;
        break;
      case _StatusKind.outForDelivery:
        bg = AppColors.amberSoft;
        fg = AppColors.amber;
        break;
      case _StatusKind.done:
        bg = AppColors.greenSoft;
        fg = const Color(0xFF2F5A44);
        break;
      case _StatusKind.cancelled:
        bg = AppColors.redSoft;
        fg = const Color(0xFF8C3F32);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        text,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionPanel({
    required this.child,
    this.padding = const EdgeInsets.all(22),
  });

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