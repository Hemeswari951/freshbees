import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_colors.dart';
import '../../services/product_service.dart';
import 'add_product_screen.dart';

/// Shows the product the way a shop owner needs to review it.
///
/// Layout:
/// - Desktop (wide): thumbnails listed left→right ABOVE a big image; click
///   a thumbnail to change the big image below it. Details sit to the right.
/// - Mobile (narrow): gallery is a swipeable PageView (next/prev), with a
///   thumbnail strip underneath for quick jumps. Details stack below.
///
/// Right-side detail order: name → sub name (category) → ratings summary →
/// price (with discount) → colors (shown as each color's own product photo)
/// → size (tap to select, price updates if that size has its own price) →
/// small pencil icon per size to adjust stock → product specifications
/// (Myntra-style two-column grid) → full product description → ratings &
/// reviews list at the very bottom.
///
/// No borders/boxed cards, no background behind product photos — just the
/// image on the page's own white background, separated purely by spacing.
///
/// DEFAULT SELECTION: exactly like colors default to the first one, the
/// first SIZE for the active color is auto-selected too — on initial load,
/// and again whenever the owner switches color (each color gets its own
/// default size selection, since sizes/stock differ per color).
///
/// Size selection vs stock editing are DELIBERATELY separate gestures:
///  - Tapping the size itself just SELECTS it — exactly like the real
///    customer-facing product page, where selecting a size can reveal a
///    different effective price for that size (per-size price override).
///  - A small pencil icon on the corner of each size chip is the ONLY way
///    to open the stock editor — so adjusting stock never gets confused
///    with "the shop owner picked this size to buy it".
class ProductViewScreen extends StatefulWidget {
  final int productId;

  /// Optional override for what happens when "Edit" is tapped. If not
  /// provided, defaults to pushing the named route below with the
  /// productId as argument — adjust the route name to match your app.
  final void Function(int productId)? onEdit;

  const ProductViewScreen({super.key, required this.productId, this.onEdit});

  @override
  State<ProductViewScreen> createState() => _ProductViewScreenState();
}

class _ProductViewScreenState extends State<ProductViewScreen> {
  Map<String, dynamic>? _product;
  bool _loading = true;
  String? _error;

  int _activeColorIndex = 0;
  int _selectedIndex = 0; // index within _galleryItems

  // Which size is currently SELECTED — defaults to the FIRST size of
  // whichever color is active, exactly like the color swatch above it
  // defaults to the first color. Null only ever happens transiently
  // (e.g. a color with zero sizes) — see _defaultSizeSelection().
  int? _selectedSizeIndex;

  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final product = await ProductService.getProductDetail(widget.productId);
      setState(() {
        _product = product;
        _loading = false;
      });
      // Once data is in, default-select size 0 for whatever color is
      // currently active — same idea as the color swatch defaulting to
      // index 0 on first load.
      _defaultSizeSelection();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // Selects the first size for the active color, if one exists.
  // Called on initial load and every time the active color changes.
  void _defaultSizeSelection() {
    final variants = _activeVariants;
    setState(() => _selectedSizeIndex = variants.isNotEmpty ? 0 : null);
  }

  List<Map<String, dynamic>> get _colors =>
      (_product?['colors'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      [];

  Map<String, dynamic>? get _activeColor => _colors.isNotEmpty
      ? _colors[_activeColorIndex.clamp(0, _colors.length - 1)]
      : null;

  List<Map<String, dynamic>> get _activeImages =>
      (_activeColor?['images'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      [];

  List<Map<String, dynamic>> get _activeVariants =>
      (_activeColor?['variants'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      [];

  // The variant the owner has currently SELECTED by tapping a size chip
  // (or the auto-selected default — see _defaultSizeSelection).
  Map<String, dynamic>? get _selectedVariant {
    if (_selectedSizeIndex == null) return null;
    final variants = _activeVariants;
    if (_selectedSizeIndex! < 0 || _selectedSizeIndex! >= variants.length) {
      return null;
    }
    return variants[_selectedSizeIndex!];
  }

  List<Map<String, dynamic>> get _reviews =>
      (_product?['reviews'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      [];

  double get _avgRating => _product?['avgRating'] != null
      ? (_product!['avgRating'] as num).toDouble()
      : (_reviews.isNotEmpty
            ? _reviews
                      .map((r) => (r['rating'] as num).toDouble())
                      .reduce((a, b) => a + b) /
                  _reviews.length
            : 0.0);

  int get _reviewCount => _product?['reviewCount'] as int? ?? _reviews.length;

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

    add('Fabric', p['fabric']);
    add('Pattern', p['pattern']);
    add('Fit', p['fitType']);
    add('Sleeve', p['sleeveType']);
    add('Neck', p['neckType']);
    add('Occasion', p['occasion']);
    add('Brand', p['brand']);
    add('Sub-category', p['subCategory']);
    add('Wash care', p['washCare']);
    add('Country of origin', p['countryOfOrigin']);
    return entries;
  }

  List<String> get _tags =>
      (_product?['tags'] as List?)?.map((e) => e.toString()).toList() ?? [];

  List<Map<String, dynamic>> get _extraAttributes =>
      (_product?['attributes'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList() ??
      [];

  /// Builds the gallery sequence for the active color: photos in order,
  /// with any group of images tagged type: '360' collapsed into ONE spin
  /// item, inserted right where the first 360-frame appears — so it sits
  /// in the list like any other photo, just interactive.
  List<_GalleryItem> get _galleryItems {
    final items = <_GalleryItem>[];
    List<String>? spinList;
    for (final img in _activeImages) {
      final type = img['type'] as String? ?? 'other';
      final url = ProductService.fullImageUrl(img['url'] as String);
      if (type == '360') {
        spinList ??= <String>[];
        if (spinList.isEmpty) items.add(_GalleryItem.spin(spinList));
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
  String? _colorCoverUrl(Map<String, dynamic> color) {
    final images =
        (color['images'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    if (images.isEmpty) return null;
    final nonSpin = images.firstWhere(
      (img) => (img['type'] as String? ?? 'other') != '360',
      orElse: () => images.first,
    );
    return ProductService.fullImageUrl(nonSpin['url'] as String);
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
  // already-selected size just keeps it selected (no "deselect" state,
  // since "nothing selected" isn't a real state here once data has
  // loaded and sizes exist).
  void _onSizeTap(int index) {
    setState(() => _selectedSizeIndex = index);
  }

  (String, _StatusKind) _stockPill(String status) {
    switch (status) {
      case 'Out of stock':
        return ('Out of stock', _StatusKind.cancelled);
      case 'Only few left':
        return ('Only few left', _StatusKind.pending);
      default:
        return ('In stock', _StatusKind.done);
    }
  }

  void _onEditTap() {
    if (widget.onEdit != null) {
      widget.onEdit!(widget.productId);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddProductScreen(product: _product ?? {'id': widget.productId}),
      ),
    ).then((updated) {
      if (updated != null) _load();
    });
  }

  // ── Stock editing — ONLY reachable via the small pencil icon on a size
  // chip, never via a plain tap on the size itself (that's reserved for
  // selection, see _onSizeTap). Updates local state optimistically, calls
  // the real adjustVariantStock endpoint with a DELTA (not an absolute
  // value), then refetches the product so the source-of-truth data
  // (_product) reflects the new stock on the next rebuild.
  Future<void> _openStockEditor(Map<String, dynamic> variant) async {
    // ⚠️ Confirm your API's variant id key — this assumes `id`.
    final variantId = variant['id'] as int;
    final originalStock = (variant['stock'] as num).toInt();

    final result = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _StockEditorSheet(
        colorName: _activeColor?['colorName'] as String? ?? '',
        size: variant['size'] as String,
        initialStock: originalStock,
      ),
    );
    if (result == null || result == originalStock) {
      return; // cancelled or unchanged
    }

    final delta = result - originalStock;

    // Optimistic update so the sheet closing feels instant.
    setState(() => variant['stock'] = result);

    try {
      await ProductService.adjustVariantStock(variantId, delta);
      // Refetch so _product (the real source of truth) has the updated
      // stock — the `variant` map here is just a throwaway copy from the
      // getter and won't be visible on the next rebuild otherwise.
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => variant['stock'] = originalStock);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not update stock: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: AppColors.inkSoft),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  _AppButton(label: 'Try again', onPressed: _load),
                ],
              ),
            ),
          )
        : _buildContent();
  }

  Widget _buildContent() {
    final product = _product!;
    final overallStatus = product['stockStatus'] as String? ?? 'In stock';

    double price = (product['price'] as num).toDouble();
    double? mrp = product['mrp'] != null
        ? (product['mrp'] as num).toDouble()
        : null;
    int discountPercent = product['discountPercent'] as int? ?? 0;

    final selected = _selectedVariant;
    if (selected != null) {
      final effPrice = selected['effectivePrice'];
      final effMrp = selected['effectiveMrp'];
      final effDiscount = selected['variantDiscountPercent'];
      if (effPrice != null) price = (effPrice as num).toDouble();
      if (effMrp != null) {
        mrp = (effMrp as num).toDouble();
      } else if (selected['effectivePrice'] != null) {
        mrp = null;
      }
      if (effDiscount != null) discountPercent = effDiscount as int;
    }

    final items = _galleryItems;

    return Column(
      children: [
        // ── Custom back header — context.go() doesn't push to the stack,
        // so we can't rely on Navigator.pop(); go back to the list route
        // directly instead. ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.ink),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/products');
                  }
                },
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Product view',
                      style: TextStyle(
                        fontFamily: 'Fraunces',
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'This is how customers see it',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.inkSoft,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.ink),
                tooltip: 'Edit product',
                onPressed: _onEditTap,
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final wide = c.maxWidth >= 640;
                    final gallery = wide
                        ? _desktopGallery(items)
                        : _mobileGallery(items);
                    final details = _detailsSection(
                      price,
                      mrp,
                      discountPercent,
                      overallStatus,
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
              ),
            ),
          ),
        ),
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
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                                      : AppColors.ink.withValues(alpha: 0.3),
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
              separatorBuilder: (_, _) => const SizedBox(width: 8),
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
                    color: AppColors.terracotta.withValues(alpha: 0.45),
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
          errorBuilder: (_, _, _) => Container(color: AppColors.blush),
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
  Widget _detailsSection(
    double price,
    double? mrp,
    int discountPercent,
    String overallStatus,
  ) {
    final product = _product!;
    final (label, kind) = _stockPill(overallStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name — bold, dark, tighter than before (Myntra-style brand/name line)
        Text(
          product['name'] as String,
          style: const TextStyle(
            fontFamily: 'Fraunces',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 5),
        // Sub name (category) — regular weight, softer gray, more legible
        // than the previous heavy 45% opacity mute.
        Text(
          product['subCategory'] as String,
          style: TextStyle(
            fontSize: 14.5,
            color: AppColors.ink.withValues(alpha: 0.6),
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        // Ratings summary — green pill badge + count, matching the
        // Myntra "4.4 ★ | 679 Ratings" treatment.
        if (_reviewCount > 0)
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
                      _avgRating.toStringAsFixed(1),
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
                '$_reviewCount ${_reviewCount == 1 ? 'Rating' : 'Ratings'}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.ink.withValues(alpha: 0.55),
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
              color: AppColors.ink.withValues(alpha: 0.5),
            ),
          ),
        Divider(color: Colors.grey.withValues(alpha: 0.45), thickness: 1, height: 20),
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
                    color: AppColors.ink.withValues(alpha: 0.4),
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
            color: const Color.fromARGB(255, 2, 103, 41).withValues(alpha: 0.85),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        // _StatusBadge(text: label, kind: kind),
        // const SizedBox(height: 24),

        // Colors — shown as each color's own product photo, not a dot
        if (_colors.isNotEmpty) ...[
          Text(
            'MORE COLORS',
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
              separatorBuilder: (_, _) => const SizedBox(width: 10),
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
                          // borderRadius: BorderRadius.circular(12),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: AppColors.terracotta.withValues(
                                      alpha: 0.45,
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
                                errorBuilder: (_, _, _) =>
                                    Container(color: AppColors.blush),
                              )
                            : Container(color: AppColors.blush),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['colorName'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.ink.withValues(alpha: active ? 0.9 : 0.5),
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

        _sizeStockSection(),
        Divider(color: Colors.grey.withValues(alpha: 0.45), thickness: 1, height: 20),
        const SizedBox(height: 24),

        _sectionTitle('PRODUCT DETAILS'),
        const SizedBox(height: 10),
        Text(
          (product['description'] as String?)?.trim().isNotEmpty == true
              ? product['description'] as String
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

        _ratingsAndReviews(),
      ],
    );
  }

  // ── Size chart + stock (per size, for the selected color) ────────────────
  // Tap the size itself to SELECT it (updates price above if this size has
  // its own price/mrp). Tap the small pencil icon in the corner to open the
  // stock stepper for that size — these are two separate gestures on
  // purpose, see the class doc comment. Size 0 is selected by default,
  // exactly like the color swatch above defaults to index 0.
  Widget _sizeStockSection() {
    final variants = _activeVariants;
    if (variants.isEmpty) return const SizedBox.shrink();
    final totalStock = variants.fold<int>(
      0,
      (sum, v) => sum + (v['stock'] as num).toInt(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
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
                color: AppColors.ink.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Tap a size to select it · tap the pencil to update stock',
          style: TextStyle(
            fontSize: 10.5,
            color: AppColors.ink.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: List.generate(variants.length, (i) {
            final v = variants[i];
            final stock = (v['stock'] as num).toInt();
            final outOfStock = stock <= 0;
            final lowStock = stock > 0 && stock <= 5;
            final selected = _selectedSizeIndex == i;

            return GestureDetector(
              onTap: () => _onSizeTap(i),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? AppColors.terracotta.withValues(alpha: 0.18)
                              : const Color.fromARGB(
                                  255,
                                  246,
                                  243,
                                  241,
                                ).withValues(alpha: 0.5),
                          border: selected
                              ? Border.all(
                                  color: const Color.fromARGB(93, 15, 12, 10),
                                  width: 1.6,
                                )
                              : null,
                        ),
                        child: Text(
                          v['size'] as String,
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
                      // Small pencil icon — the ONLY way to open the stock
                      // editor. Its own GestureDetector so tapping it
                      // never triggers the size-select behaviour above.
                      Positioned(
                        right: -4,
                        bottom: -4,
                        child: GestureDetector(
                          onTap: () => _openStockEditor(v),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.black,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.edit,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    outOfStock ? 'Out of stock' : '$stock left',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: outOfStock
                          ? AppColors.ink.withValues(alpha: 0.4)
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
    // Build one flat list of label/value pairs from both the fixed
    // schema fields (_specifications) and any free-form EAV attributes,
    // so they render in the same grid without the caller needing to
    // know which source each one came from.
    final pairs = <MapEntry<String, String>>[
      ..._specifications,
      ..._extraAttributes
          .where((a) => (a['label'] as String? ?? '').trim().isNotEmpty)
          .map(
            (a) => MapEntry(a['label'] as String, a['value'] as String? ?? ''),
          ),
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
            color: AppColors.ink.withValues(alpha: 0.45),
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
        Divider(color: Colors.grey.withValues(alpha: 0.45), thickness: 1, height: 20),
      ],
    );
  }

  // ── Ratings & reviews — read-only, shown at the very end of the details.
  Widget _ratingsAndReviews() {
    final reviews = _reviews;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('RATINGS & REVIEWS'),
        const SizedBox(height: 14),
        if (reviews.isEmpty)
          Text(
            'No reviews yet.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.ink.withValues(alpha: 0.5),
            ),
          )
        else
          Column(
            children: List.generate(reviews.length, (i) {
              final r = reviews[i];
              final rating = (r['rating'] as num?)?.toDouble() ?? 0;
              final name = r['customerName'] as String? ?? 'Customer';
              final comment = r['comment'] as String? ?? '';
              final date = r['date'] as String? ?? '';
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == reviews.length - 1 ? 0 : 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (star) => Icon(
                              star < rating.round()
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 14,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.ink.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        comment,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
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
// Stock editor bottom sheet — −/+ stepper for one color+size.
// Pops with the new stock value, or null if cancelled/unchanged.
// ─────────────────────────────────────────────────────────────

class _StockEditorSheet extends StatefulWidget {
  final String colorName;
  final String size;
  final int initialStock;

  const _StockEditorSheet({
    required this.colorName,
    required this.size,
    required this.initialStock,
  });

  @override
  State<_StockEditorSheet> createState() => _StockEditorSheetState();
}

class _StockEditorSheetState extends State<_StockEditorSheet> {
  late int _stock = widget.initialStock;
  bool _saving = false;

  void _step(int delta) {
    setState(() => _stock = (_stock + delta).clamp(0, 9999));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    // Small delay just so the button shows a spinner briefly; the actual
    // network call happens back in the parent after this sheet pops.
    await Future.delayed(const Duration(milliseconds: 120));
    if (mounted) Navigator.of(context).pop(_stock);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Text(
            '${widget.colorName} · Size ${widget.size}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Update stock for this size',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.ink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icon: Icons.remove,
                onTap: _stock > 0 ? () => _step(-1) : null,
              ),
              SizedBox(
                width: 90,
                child: Text(
                  '$_stock',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
              ),
              _StepButton(icon: Icons.add, onTap: () => _step(1)),
            ],
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? AppColors.blush.withValues(alpha: 0.6)
              : AppColors.blush.withValues(alpha: 0.25),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.ink : AppColors.ink.withValues(alpha: 0.3),
        ),
      ),
    );
  }
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
          errorBuilder: (_, _, _) => const Center(
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
        pageBuilder: (_, _, _) =>
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
            errorBuilder: (_, _, _) => Container(
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const _AppButton({required this.label, this.onPressed}) : icon = null;

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
