import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/t_colors.dart';
import '../../services/product_service.dart';

/// Shows the product the way an admin needs to review it.
///
/// Layout:
/// - Desktop (wide): thumbnails listed left→right ABOVE a big image; click
///   a thumbnail to change the big image below it. Details sit to the right.
/// - Mobile (narrow): gallery is a swipeable PageView (next/prev), with a
///   thumbnail strip underneath for quick jumps. Details stack below.
///
/// Right-side detail order: name → sub name (category) → active/inactive
/// status → ratings summary → price (with discount) → colors
/// (shown as each color's own product photo) → size (tap to select, price
/// updates if that size has its own price) → product specifications
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
/// NOTE: this screen is FULLY READ-ONLY on the admin side. The admin
/// backend only exposes list-all-products and get-product-by-id — there
/// is no status-update endpoint here, so unlike the shop owner's version
/// of this screen, there is no activate/deactivate button. The status is
/// shown as a plain pill for visibility only.
class ProductViewScreen extends StatefulWidget {
  final int productId;

  const ProductViewScreen({super.key, required this.productId});

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
        _isActive = product['isActive'] ?? true;
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

  // The variant the admin has currently SELECTED by tapping a size chip
  // (or the auto-selected default — see _defaultSizeSelection).
  Map<String, dynamic>? get _selectedVariant {
    if (_selectedSizeIndex == null) return null;
    final variants = _activeVariants;
    if (_selectedSizeIndex! < 0 || _selectedSizeIndex! >= variants.length)
      return null;
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

  // Whether the product is currently active (visible to customers) or
  // inactive (hidden). Defaults to true if the backend hasn't sent the
  // field for some reason. Display-only on the admin side — see class note.
  bool _isActive = true;

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
  // already-selected size just keeps it selected.
  void _onSizeTap(int index) {
    setState(() => _selectedSizeIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: TColors.ink.withOpacity(0.7)),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final product = _product!;

    // Base product price/mrp/discount.
    double price = (product['price'] as num).toDouble();
    double? mrp = product['mrp'] != null
        ? (product['mrp'] as num).toDouble()
        : null;
    int discountPercent = product['discountPercent'] as int? ?? 0;

    // The selected size (default = first size) may carry its own
    // effective price/mrp — see Approach 1 in the backend. When present,
    // it overrides the base price shown, same as tapping a size on a
    // real customer product page can change the shown price.
    final selected = _selectedVariant;
    if (selected != null) {
      final effPrice = selected['effectivePrice'];
      final effMrp = selected['effectiveMrp'];
      final effDiscount = selected['variantDiscountPercent'];
      if (effPrice != null) price = (effPrice as num).toDouble();
      if (effMrp != null) {
        mrp = (effMrp as num).toDouble();
      } else if (selected['effectivePrice'] != null) {
        mrp = null; // effective price given but no mrp -> no strike-through
      }
      if (effDiscount != null) discountPercent = effDiscount as int;
    }

    final items = _galleryItems;

    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: TColors.cream,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5), // bottom shadow
                ),
              ],
            ),
            child: Row(
              children: [
                _ShadowIconButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),

                const Spacer(),

                Text(
                  _isActive ? "Active" : "Inactive",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isActive ? TColors.green : Colors.red,
                  ),
                ),

                const SizedBox(width: 15),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isActive ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(_isActive ? Icons.block : Icons.check_circle),
                  label: Text(
                    _isActive ? 'Deactivate Product' : 'Activate Product',
                  ),
                  onPressed: () async {
                    final confirmed = await _showStatusDialog(!_isActive);

                    if (confirmed != true) return;
                    try {
                      await ProductService.updateProductStatus(
                        widget.productId,
                        !_isActive,
                      );

                      if (!mounted) return;

                      setState(() {
                        _isActive = !_isActive;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _isActive
                                ? 'Product activated successfully'
                                : 'Product deactivated successfully',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width >= 640 ? 32 : 16,
              vertical: 10,
            ),
            child: LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 640;
                final gallery = wide
                    ? _desktopGallery(items)
                    : _mobileGallery(items);
                final details = _detailsSection(price, mrp, discountPercent);

                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 480, child: gallery),
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
        ],
      ),
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
                                      ? TColors.ink
                                      : TColors.ink.withOpacity(0.3),
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
                    color: TColors.terracotta.withOpacity(0.45),
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
          errorBuilder: (_, __, ___) => Container(color: TColors.blush),
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
    color: TColors.blush,
    alignment: Alignment.center,
    child: const Icon(Icons.checkroom, size: 56, color: TColors.inkSoft),
  );

  // ── Details column ────────────────────────────────────────────────────
  Widget _detailsSection(double price, double? mrp, int discountPercent) {
    final product = _product!;

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
            color: TColors.ink,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 5),
        // Sub name (category) — regular weight, softer gray, more legible
        // than the previous heavy 45% opacity mute.
        Text(
          product['subCategory'] as String? ?? '',
          style: TextStyle(
            fontSize: 14.5,
            color: TColors.ink.withOpacity(0.6),
            fontWeight: FontWeight.w400,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),

        const SizedBox(height: 16),
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
                  color: TColors.green,
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
                  color: TColors.ink.withOpacity(0.55),
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
              color: TColors.ink.withOpacity(0.5),
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
                color: TColors.ink,
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
                    color: TColors.ink.withOpacity(0.4),
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
          Text(
            'COLORS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: TColors.ink,
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
                        width: 65,
                        height: 70,
                        decoration: BoxDecoration(
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: TColors.terracotta.withOpacity(0.45),
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
                                    Container(color: TColors.blush),
                              )
                            : Container(color: TColors.blush),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['colorName'] as String? ?? '',
                        style: TextStyle(
                          fontSize: 10,
                          color: TColors.ink.withOpacity(active ? 0.9 : 0.5),
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
          (product['description'] as String?)?.trim().isNotEmpty == true
              ? product['description'] as String
              : 'No description added yet.',
          style: const TextStyle(
            fontSize: 13.5,
            color: TColors.ink,
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

  // ── Size chart (read-only for stock) ──────────────────────────────────
  // Tap the size itself to SELECT it (updates price above if this size has
  // its own price/mrp). Size 0 is selected by default, exactly like the
  // color swatch above defaults to index 0. Every chip carries its own
  // border now — selected gets a bolder/darker one, the rest get a soft
  // neutral outline so unselected sizes still read as tappable chips.
  Widget _sizeSection() {
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
                color: TColors.ink,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              'Total: $totalStock pcs',
              style: TextStyle(
                fontSize: 11.5,
                color: TColors.ink.withOpacity(0.5),
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
            final stock = (v['stock'] as num).toInt();
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
                          ? TColors.terracotta.withOpacity(0.18)
                          : const Color.fromARGB(
                              255,
                              246,
                              243,
                              241,
                            ).withOpacity(0.5),
                      border: Border.all(
                        color: selected
                            ? const Color.fromARGB(93, 15, 12, 10)
                            : TColors.ink.withOpacity(0.18),
                        width: selected ? 1.6 : 1.0,
                      ),
                    ),
                    child: Text(
                      v['size'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: TColors.ink,
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
                          ? TColors.ink.withOpacity(0.4)
                          : (lowStock ? TColors.gold : TColors.green),
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

  // Status UPdation Dialog

  Future<bool?> _showStatusDialog(bool makeActive) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(makeActive ? 'Activate Product' : 'Deactivate Product'),
          content: Text(
            makeActive
                ? 'Are you sure you want to activate this product?'
                : 'Are you sure you want to deactivate this product?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(makeActive ? 'Activate' : 'Deactivate'),
            ),
          ],
        );
      },
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
            color: TColors.ink.withOpacity(0.45),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          entry.value,
          style: const TextStyle(
            fontSize: 14,
            color: TColors.ink,
            fontWeight: FontWeight.w500,
          ),
        ),
        Divider(color: Colors.grey.withOpacity(0.45), thickness: 1, height: 20),
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
            style: TextStyle(fontSize: 13, color: TColors.ink.withOpacity(0.5)),
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
                              color: TColors.ink,
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
                              color: TColors.gold,
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
                          color: TColors.ink.withOpacity(0.4),
                        ),
                      ),
                    ],
                    if (comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        comment,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: TColors.ink,
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
      color: TColors.ink,
      letterSpacing: 0.3,
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Small reusable icon-only button with a soft shadow — used for the
// back button so it doesn't carry an outline or text label.
// ─────────────────────────────────────────────────────────────
class _ShadowIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ShadowIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(child: Icon(icon, color: TColors.ink, size: 22)),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final url in widget.imageUrls) {
        precacheImage(NetworkImage(url), context);
      }
    });
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
            child: Icon(Icons.broken_image_outlined, color: TColors.inkSoft),
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
              color: TColors.blush,
              alignment: Alignment.center,
              child: const Icon(
                Icons.image_not_supported_outlined,
                size: 40,
                color: TColors.inkSoft,
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
