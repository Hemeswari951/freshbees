import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/app_colors.dart';
import '../../services/product_service.dart';

/// Shows the product exactly the way a CUSTOMER would see it on the
/// storefront — image slider, color swatches, size picker, price, details.
/// Opened when the shop owner taps a product card/row on the Products page,
/// so they can preview their listing before/after publishing it.
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
  int _activeImageIndex = 0;
  int? _selectedVariantIndex;
  late final PageController _pageController;

  // 'photos' = normal swipeable gallery (zoomable), '360' = auto-spin
  // built by cycling through the same photos on drag. Needs 2+ photos.
  String _galleryMode = 'photos';

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

  void _selectColor(int index) {
    setState(() {
      _activeColorIndex = index;
      _activeImageIndex = 0;
      _selectedVariantIndex = null;
    });
    _pageController.jumpToPage(0);
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: LayoutBuilder(builder: (context, c) {
            final wide = c.maxWidth >= 640;
            final gallery = _gallerySection();
            final details = _detailsSection(price, mrp, discountPercent, overallStatus);
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 340, child: gallery),
                  const SizedBox(width: 28),
                  Expanded(child: details),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                gallery,
                const SizedBox(height: 22),
                details,
              ],
            );
          }),
        ),
      ),
    );
  }

  // ── Left side: swipeable image slider + thumbnail strip ──────────────────
  Widget _gallerySection() {
    final images = _activeImages;
    final urls = images.map((m) => ProductService.fullImageUrl(m['url'] as String)).toList();

    // Real turntable sequence, tagged type: '360' by the backend, in
    // upload order — this is what makes the spin look smooth and real
    // instead of a 4-photo flip. Falls back to cycling ALL photos (old
    // behavior) only for products that don't have a dedicated spin set.
    final spinImages = images.where((m) => (m['type'] as String?) == '360').toList();
    final spinUrls = spinImages.map((m) => ProductService.fullImageUrl(m['url'] as String)).toList();
    final spinUrlsForViewer = spinUrls.length >= 2 ? spinUrls : urls;
    final has360 = spinUrlsForViewer.length >= 2;

    return _SectionPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          if (has360) ...[
            _galleryModeToggle(),
            const SizedBox(height: 10),
          ],
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: images.isEmpty
                  ? Container(
                      color: AppColors.blush,
                      alignment: Alignment.center,
                      child: const Icon(Icons.checkroom, size: 56, color: AppColors.inkSoft),
                    )
                  : (_galleryMode == '360' && has360)
                      ? Product360AutoViewer(imageUrls: spinUrlsForViewer)
                      : Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: images.length,
                              onPageChanged: (i) => setState(() => _activeImageIndex = i),
                              itemBuilder: (context, i) => _ZoomableNetworkImage(imageUrl: urls[i]),
                            ),
                            if (images.length > 1)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(images.length, (i) {
                                    final active = i == _activeImageIndex;
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
          if (images.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = i == _activeImageIndex && _galleryMode == 'photos';
                  final type = images[i]['type'] as String? ?? 'other';
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _activeImageIndex = i;
                        _galleryMode = 'photos';
                      });
                      _pageController.animateToPage(i, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                    },
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: active ? AppColors.terracotta : AppColors.line, width: active ? 2 : 1),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Image.network(
                            urls[i],
                            fit: BoxFit.cover,
                            width: 56,
                            height: 56,
                            errorBuilder: (_, __, ___) => Container(color: AppColors.blush),
                          ),
                          if (type != 'other')
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                color: Colors.black.withOpacity(0.55),
                                padding: const EdgeInsets.symmetric(vertical: 1),
                                child: Text(
                                  type[0].toUpperCase() + type.substring(1),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _galleryModeToggle() {
    Widget seg(String id, String label, IconData icon) {
      final active = _galleryMode == id;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _galleryMode = id),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: active ? AppColors.terracotta : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: active ? Colors.white : AppColors.inkSoft),
                const SizedBox(width: 5),
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : AppColors.inkSoft)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        seg('photos', 'Photos', Icons.photo_library_outlined),
        seg('360', '360°', Icons.threed_rotation),
      ]),
    );
  }
  // ── Right side: name, price, color swatches, size picker, description ────
  Widget _detailsSection(double price, double? mrp, int discountPercent, String overallStatus) {
    final product = _product!;
    final (label, kind, color) = _stockPill(overallStatus);

    return Column(
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

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink, fontFamily: 'JetBrainsMono')),
            if (mrp != null && mrp > price) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('₹${mrp.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, decoration: TextDecoration.lineThrough)),
              ),
            ],
            if (discountPercent > 0) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('$discountPercent% off',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.green)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        _StatusBadge(text: label, kind: kind),
        const SizedBox(height: 22),

        if (_colors.isNotEmpty) ...[
          Text('Color: ${_activeColor?['colorName'] ?? ''}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
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

        if (_activeVariants.isNotEmpty) ...[
          const Text('Size', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.inkSoft)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_activeVariants.length, (i) {
              final v = _activeVariants[i];
              final outOfStock = (v['stock'] as num).toInt() <= 0;
              final selected = _selectedVariantIndex == i;
              return GestureDetector(
                onTap: outOfStock ? null : () => setState(() => _selectedVariantIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.black : AppColors.blush,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: selected ? AppColors.black : AppColors.line),
                  ),
                  child: Text(
                    v['size'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: outOfStock ? AppColors.inkSoft : (selected ? Colors.white : AppColors.ink),
                      decoration: outOfStock ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 22),
        ],

        _sectionTitle('Product details'),
        const SizedBox(height: 8),
        Text(
          (product['description'] as String?)?.trim().isNotEmpty == true
              ? product['description'] as String
              : 'No description added yet.',
          style: const TextStyle(fontSize: 13.5, color: AppColors.ink, height: 1.5),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) =>
      Text(title, style: const TextStyle(fontFamily: 'Fraunces', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink));
}

/// 360° spin viewer. Prefers the dedicated turntable sequence (images
/// tagged type: '360', uploaded in order from AddProductScreen's "360°
/// spin photos" section) for a real, smooth spin — 8-30 photos recommended.
/// Falls back to cycling whatever photos exist (front/back/side/zoom) for
/// older products with no dedicated spin set — that only gives a rough
/// "see the other side" flip with just 2-4 frames, not a true spin.
/// Drag left/right to control; auto-spins after 2 seconds of no touch.
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
/// expand button for an even closer look. Used for every image in the
/// normal "Photos" gallery mode (not the 360° mode, which needs full
/// drag gestures free for spinning).
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