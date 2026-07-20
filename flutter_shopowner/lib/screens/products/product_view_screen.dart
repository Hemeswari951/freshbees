import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/app_colors.dart';
import '../../services/product_service.dart';

/// Shows the product the way a shop owner needs to review it — gallery on
/// one side (with 360° spin merged right into the image sequence), and
/// name / price / color / size-stock / description on the other. Below
/// that: read-only ratings & reviews (no "add review" — this is the shop
/// owner portal, not the customer app). Edit button sits in the app bar.
///
/// Layout:
/// - Desktop (wide): thumbnails listed left→right ABOVE a big image; click
///   a thumbnail to change the big image below it. Details sit to the right.
/// - Mobile (narrow): gallery is a swipeable PageView (next/prev), with a
///   thumbnail strip underneath for quick jumps. Details stack below.
///
/// NOTE: Only the "details" panel (name / price / colors / size chart) was
/// restyled to match the Myntra-style reference — circular size selector
/// with per-size stock pills, "MORE COLORS" label above color swatches.
/// The gallery (left side / image logic, 360 spin, zoom) is UNCHANGED.
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
  int? _selectedVariantIndex;
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
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _colors =>
      (_product?['colors'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

  Map<String, dynamic>? get _activeColor =>
      _colors.isNotEmpty ? _colors[_activeColorIndex.clamp(0, _colors.length - 1)] : null;

  List<Map<String, dynamic>> get _activeImages =>
      (_activeColor?['images'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

  List<Map<String, dynamic>> get _activeVariants =>
      (_activeColor?['variants'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

  /// Builds the gallery sequence: normal photos in order, with any group of
  /// images tagged type: '360' collapsed into ONE spin item, inserted right
  /// where the first 360-frame appears in the original order. That's what
  /// makes the 360 view sit "in between" the regular photos instead of
  /// living behind a separate toggle.
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
        items.add(_GalleryItem.photo(url, type));
      }
    }
    // Needs 2+ frames to actually spin — drop it otherwise.
    items.removeWhere((it) => it.kind == _GalleryKind.spin && (it.spinUrls?.length ?? 0) < 2);
    return items;
  }

  void _selectColor(int index) {
    setState(() {
      _activeColorIndex = index;
      _selectedIndex = 0;
      _selectedVariantIndex = null;
    });
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  Color _parseHex(String? hex, {Color fallback = AppColors.blush}) {
    if (hex == null || hex.isEmpty) return fallback;
    var h = hex.replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    try {
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  (String, _StatusKind, Color) _stockPill(String status) {
    switch (status) {
      case 'Out of stock':
        return ('Out of stock', _StatusKind.cancelled, AppColors.red);
      case 'Only few left':
        return ('Only few left', _StatusKind.pending, AppColors.gold);
      default:
        return ('In stock', _StatusKind.done, AppColors.green);
    }
  }

  void _onEditTap() {
    if (widget.onEdit != null) {
      widget.onEdit!(widget.productId);
      return;
    }
    // Adjust this route name to whatever your admin/shop-owner router uses.
    Navigator.pushNamed(context, '/shop-owner/products/edit', arguments: widget.productId).then((changed) {
      if (changed == true) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('Product view', style: TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 16)),
            Text('This is how customers see it', style: TextStyle(fontSize: 11.5, color: AppColors.inkSoft, fontWeight: FontWeight.w400)),
          ],
        ),
        actions: [
          if (!_loading && _error == null && _product != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit product',
              onPressed: _onEditTap,
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: const TextStyle(color: AppColors.inkSoft), textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        _AppButton(label: 'Try again', onPressed: _load),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final product = _product!;
    final price = (product['price'] as num).toDouble();
    final mrp = product['mrp'] != null ? (product['mrp'] as num).toDouble() : null;
    final discountPercent = product['discountPercent'] as int? ?? 0;
    final overallStatus = product['stockStatus'] as String? ?? 'In stock';
    final items = _galleryItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 640;
            // ── Left side (gallery) — UNCHANGED, same as before ──────────
            final gallery = wide ? _desktopGallery(items) : _mobileGallery(items);
            // ── Right side (details) — restyled to match reference ───────
            final details = _detailsSection(price, mrp, discountPercent, overallStatus);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 380, child: gallery),
                      const SizedBox(width: 28),
                      Expanded(child: details),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      gallery,
                      const SizedBox(height: 22),
                      details,
                    ],
                  ),
                const SizedBox(height: 28),
                _ratingsSection(),
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Desktop: thumbnails left→right on top, big image below them ──────────
  // (UNCHANGED — image/gallery concept left exactly as-is)
  Widget _desktopGallery(List<_GalleryItem> items) {
    final selected = items.isEmpty ? 0 : _selectedIndex.clamp(0, items.length - 1);
    return _SectionPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          SizedBox(
            height: 64,
            child: items.isEmpty
                ? const SizedBox()
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _thumbnail(items[i], i, i == selected),
                  ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: items.isEmpty ? _emptyImagePlaceholder() : _bigDisplay(items[selected]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile: swipeable gallery (next/prev), thumbnail strip underneath ────
  // (UNCHANGED — image/gallery concept left exactly as-is)
  Widget _mobileGallery(List<_GalleryItem> items) {
    return _SectionPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: items.isEmpty
                  ? _emptyImagePlaceholder()
                  : Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          itemCount: items.length,
                          onPageChanged: (i) => setState(() => _selectedIndex = i),
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
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: active ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: active ? Colors.white : Colors.white.withOpacity(0.6),
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
                itemBuilder: (context, i) => _thumbnail(items[i], i, i == _selectedIndex),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _thumbnail(_GalleryItem item, int index, bool active) {
    final thumbUrl = item.kind == _GalleryKind.spin ? item.spinUrls!.first : item.url!;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        if (_pageController.hasClients) {
          _pageController.animateToPage(index, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: active ? AppColors.terracotta : AppColors.line, width: active ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(thumbUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.blush)),
            if (item.kind == _GalleryKind.spin)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.threed_rotation, size: 9, color: Colors.white),
                      SizedBox(width: 2),
                      Text('360°', style: TextStyle(fontSize: 7.5, color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              )
            else if ((item.photoType ?? 'other') != 'other')
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Text(
                    item.photoType![0].toUpperCase() + item.photoType!.substring(1),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
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

  // ── Details: name, price, color, size + stock, description ───────────────
  // Restyled to match the Myntra-style reference screenshot.
  Widget _detailsSection(double price, double? mrp, int discountPercent, String overallStatus) {
    final product = _product!;
    final (label, kind, color) = _stockPill(overallStatus);

    return _SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product['brand'] as String? ?? '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.terracotta)),
          const SizedBox(height: 4),
          Text(
            product['name'] as String,
            style: const TextStyle(fontFamily: 'Fraunces', fontSize: 21, fontWeight: FontWeight.w600, color: AppColors.ink),
          ),
          const SizedBox(height: 6),
          Text(product['category'] as String? ?? 'Uncategorized', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
          const SizedBox(height: 14),

          // Price row: ₹price  MRP(strikethrough)  (xx% OFF)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'JetBrainsMono')),
              if (mrp != null && mrp > price) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('MRP ₹${mrp.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, decoration: TextDecoration.lineThrough)),
                ),
              ],
              if (discountPercent > 0) ...[
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text('($discountPercent% OFF)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.terracotta)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          const Text('inclusive of all taxes', style: TextStyle(fontSize: 11.5, color: AppColors.green, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _StatusBadge(text: label, kind: kind),
          const SizedBox(height: 22),

          // ── MORE COLORS ────────────────────────────────────────────────
          if (_colors.isNotEmpty) ...[
            const Text('MORE COLORS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: 0.3)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_colors.length, (i) {
                final c = _colors[i];
                final active = i == _activeColorIndex;
                return GestureDetector(
                  onTap: () => _selectColor(i),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _parseHex(c['colorHex'] as String?),
                      shape: BoxShape.circle,
                      border: Border.all(color: active ? AppColors.terracotta : AppColors.line, width: active ? 3 : 1.5),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 22),
          ],

          _sizeStockSection(),
          const SizedBox(height: 22),

          _sectionTitle('Product details'),
          const SizedBox(height: 8),
          Text(
            (product['description'] as String?)?.trim().isNotEmpty == true
                ? product['description'] as String
                : 'No description added yet.',
            style: const TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ── Size chart + stock (per size, for the selected color) ────────────────
  // Restyled as circular size buttons with a stock pill underneath each
  // (matches the "SELECT SIZE" row in the reference screenshot). Sizes with
  // zero stock render greyed-out with a strike-through look.
  Widget _sizeStockSection() {
    final variants = _activeVariants;
    if (variants.isEmpty) return const SizedBox.shrink();
    final totalStock = variants.fold<int>(0, (sum, v) => sum + (v['stock'] as num).toInt());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('SELECT SIZE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: 0.3)),
            Row(
              children: [
                Text('Total: $totalStock pcs', style: const TextStyle(fontSize: 11.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                const Text('SIZE CHART', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.terracotta)),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, size: 14, color: AppColors.terracotta),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: List.generate(variants.length, (i) {
            final v = variants[i];
            final stock = (v['stock'] as num).toInt();
            final outOfStock = stock <= 0;
            final lowStock = stock > 0 && stock <= 5;
            final selected = _selectedVariantIndex == i;

            return GestureDetector(
              onTap: outOfStock ? null : () => setState(() => _selectedVariantIndex = i),
              child: Opacity(
                opacity: outOfStock ? 0.4 : 1,
                child: Column(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.terracotta : AppColors.white,
                        border: Border.all(
                          color: selected
                              ? AppColors.terracotta
                              : (outOfStock ? AppColors.line : AppColors.ink.withOpacity(0.35)),
                          width: selected ? 0 : 1.2,
                        ),
                      ),
                      child: Text(
                        v['size'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.ink,
                          decoration: outOfStock ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (outOfStock)
                      const Text('Out of stock', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft))
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: lowStock ? AppColors.gold : AppColors.greenSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$stock left',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            color: lowStock ? Colors.white : const Color(0xFF2F5A44),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ── Ratings & reviews — read-only, no "add review" (shop owner portal) ───
  Widget _ratingsSection() {
    final reviews = (_product?['reviews'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];
    final double avgRating = _product?['avgRating'] != null
        ? (_product!['avgRating'] as num).toDouble()
        : (reviews.isNotEmpty ? reviews.map((r) => (r['rating'] as num).toDouble()).reduce((a, b) => a + b) / reviews.length : 0.0);
    final int reviewCount = _product?['reviewCount'] as int? ?? reviews.length;

    return _SectionPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _sectionTitle('Ratings & reviews'),
              const Spacer(),
              if (reviewCount > 0) ...[
                const Icon(Icons.star_rounded, size: 18, color: AppColors.gold),
                const SizedBox(width: 4),
                Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(width: 4),
                Text('($reviewCount)', style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No reviews yet.', style: TextStyle(fontSize: 13, color: AppColors.inkSoft)),
            )
          else
            Column(
              children: List.generate(reviews.length, (i) {
                final r = reviews[i];
                final rating = (r['rating'] as num?)?.toDouble() ?? 0;
                final name = r['customerName'] as String? ?? 'Customer';
                final comment = r['comment'] as String? ?? '';
                final date = r['date'] as String? ?? '';
                return Container(
                  margin: EdgeInsets.only(bottom: i == reviews.length - 1 ? 0 : 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.blush.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (s) => Icon(
                                s < rating.round() ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 14,
                                color: AppColors.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (date.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(date, style: const TextStyle(fontSize: 10.5, color: AppColors.inkSoft)),
                      ],
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(comment, style: const TextStyle(fontSize: 12.5, color: AppColors.ink, height: 1.4)),
                      ],
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: const TextStyle(fontFamily: 'Fraunces', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink));
}

// ─────────────────────────────────────────────────────────────
// Gallery item model — a photo, or a collapsed group of 360° frames.
// (UNCHANGED)
// ─────────────────────────────────────────────────────────────

enum _GalleryKind { photo, spin }

class _GalleryItem {
  final _GalleryKind kind;
  final String? url;
  final String? photoType;
  final List<String>? spinUrls;

  _GalleryItem.photo(this.url, this.photoType)
      : kind = _GalleryKind.photo,
        spinUrls = null;

  _GalleryItem.spin(this.spinUrls)
      : kind = _GalleryKind.spin,
        url = null,
        photoType = null;
}

/// 360° spin viewer. Rendered as one item inside the gallery sequence
/// (thumbnail strip / swipe order) rather than behind a separate toggle.
/// Drag left/right to control; auto-spins after 2 seconds of no touch.
/// (UNCHANGED)
class Product360AutoViewer extends StatefulWidget {
  final List<String> imageUrls;
  final bool autoPlay;
  const Product360AutoViewer({required this.imageUrls, this.autoPlay = true, super.key});

  @override
  State<Product360AutoViewer> createState() => _Product360AutoViewerState();
}

class _Product360AutoViewerState extends State<Product360AutoViewer> {
  int _frame = 0;
  double _dragBuffer = 0;
  bool _touched = false;
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
      _touched = true;
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
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.blush),
          AnimatedSwitcher(
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
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(12)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.threed_rotation, size: 12, color: Colors.white),
                SizedBox(width: 4),
                Text('360° — drag to rotate', style: TextStyle(fontSize: 9.5, color: Colors.white, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
          if (!_touched)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(20)),
                  child: const Text('Auto-spinning — drag to control', style: TextStyle(fontSize: 10.5, color: Colors.white)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pinch/scroll-to-zoom on a single product photo, with a fullscreen
/// expand button for an even closer look. (UNCHANGED)
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
        pageBuilder: (_, __, ___) => _FullscreenZoomView(imageUrl: widget.imageUrl),
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
              child: const Icon(Icons.image_not_supported_outlined, size: 40, color: AppColors.inkSoft),
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
              decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.open_in_full, size: 15, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fullscreen popup — pinch or drag to zoom further, tap X to close.
/// (UNCHANGED)
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
              child: Center(child: Image.network(imageUrl, fit: BoxFit.contain)),
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
// (UNCHANGED)
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