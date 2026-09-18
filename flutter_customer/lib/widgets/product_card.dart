import 'dart:async';

import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';
import 'app_colors.dart';

/// Product card for the CUSTOMER portal.
///
/// Features:
/// - Product image
/// - Rating/review pill
/// - Wishlist heart
/// - Low-stock / out-of-stock indicators
/// - Product name
/// - Subcategory
/// - Shop name
/// - Price / MRP / discount
/// - Desktop hover elevation
class ProductCard extends StatefulWidget {
  final ProductModel product;

  final VoidCallback? onTap;

  /// Whether this product currently exists in the wishlist.
  final bool isWishlisted;
  final String? color;

  /// Image URL for every color variation the shop owner uploaded for
  /// this product (in upload order — first uploaded color first).
  ///
  /// When this has 2+ entries and the card is hovered (desktop/web),
  /// the card auto-cycles through them — same idea as Myntra's
  /// hover-preview. Pass an empty/single-item list to disable cycling
  /// (the card just falls back to `product.thumbnail`).
  final List<String> hoverImages;

  /// Called when the wishlist heart is tapped.
  final VoidCallback? onWishlistTap;

  /// True while the wishlist API request for this product is running.
  ///
  /// The parent uses this to disable the heart temporarily and prevent
  /// duplicate wishlist requests.
  final bool isWishlistUpdating;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.isWishlisted = false,
    this.onWishlistTap,
    this.isWishlistUpdating = false,
    this.color,
    this.hoverImages = const [],
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  // -------------------------------------------------------------------------
  // COLOR-VARIATION AUTO-SCROLL
  // -------------------------------------------------------------------------
  // Always plays (not just on hover) so it works on touch/mobile too —
  // exactly like Myntra's card carousel. Cycles through one image per
  // uploaded color angle, in upload order.
  Timer? _autoScrollTimer;
  int _frameIndex = 0;

  static const Duration _autoScrollFrameDuration = Duration(milliseconds: 1400);

  /// Resolved list of image URLs to cycle through (all angles of the active color).
  List<String> get _variantImageUrls {
    final product = widget.product;

    // Use the backend's new hoverImages (which contains front, back, zoom, etc.)
    final List<String> fromModel = product.hoverImages
        .where((u) => u.isNotEmpty)
        .map(
          (u) => u.startsWith('http://') || u.startsWith('https://')
              ? u
              : '${ApiService.serverUrl}$u',
        )
        .toList();

    final List<String> urls = fromModel.isNotEmpty
        ? fromModel
        : widget.hoverImages;

    if (urls.isNotEmpty) return urls;

    // Fallback to the single thumbnail
    if (product.thumbnail.isNotEmpty) {
      return ['${ApiService.serverUrl}${product.thumbnail}'];
    }

    return const [];
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();

    // Only the highlighted (hovered/pressed) card should ever cycle.
    if (!_hovered) return;

    final images = _variantImageUrls;
    if (images.length < 2) return;

    _autoScrollTimer = Timer.periodic(_autoScrollFrameDuration, (_) {
      if (!mounted) return;
      setState(() {
        _frameIndex = (_frameIndex + 1) % _variantImageUrls.length;
      });
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (!mounted) return;
    setState(() {
      _frameIndex = 0; // reset back to the main thumbnail
    });
  }

  @override
  void initState() {
    super.initState();
    // Do NOT auto-start here — starting it for every card was the bug
    // (every product began cycling images at once). Scrolling now only
    // begins once this specific card becomes the highlighted one.
  }

  @override
  void didUpdateWidget(covariant ProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Product (or its color images) changed under us — restart clean,
    // but only if this card is still the highlighted one.
    if (oldWidget.product.id != widget.product.id ||
        oldWidget.hoverImages != widget.hoverImages) {
      _frameIndex = 0;
      if (_hovered) {
        _startAutoScroll();
      }
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  // =========================================================================
  // HELPERS
  // =========================================================================

  String _formatReviewCount(int count) {
    if (count >= 1000) {
      final thousands = count / 1000;

      return '${thousands.toStringAsFixed(
        thousands >= 10 ? 0 : 1,
      )}k';
    }

    return count.toString();
  }

  // =========================================================================
  // HOVER
  // =========================================================================

  void _handleMouseEnter(_) {
    if (!mounted || _hovered) return;

    setState(() {
      _hovered = true;
    });
    _startAutoScroll();
  }

  void _handleMouseExit(_) {
    if (!mounted || !_hovered) return;

    setState(() {
      _hovered = false;
    });
    _stopAutoScroll();
  }

  // ---------------------------------------------------------------------
  // TOUCH (mobile has no mouse hover) -- long-press this card to trigger
  // the same "highlight + auto-scroll" behaviour as desktop hover.
  // ---------------------------------------------------------------------

  void _handleLongPressStart(_) {
    if (!mounted || _hovered) return;
    setState(() {
      _hovered = true;
    });
    _startAutoScroll();
  }

  void _handleLongPressEnd(_) {
    if (!mounted || !_hovered) return;
    setState(() {
      _hovered = false;
    });
    _stopAutoScroll();
  }


  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final imageUrl = product.thumbnail.isNotEmpty
        ? '${ApiService.serverUrl}${product.thumbnail}'
        : '';

    // Auto-scrolling color frames — always active (mobile + desktop),
    // not gated behind hover.
    final List<String> variantImages = _variantImageUrls;

    final String activeImageUrl =
        (variantImages.isNotEmpty && _frameIndex < variantImages.length)
            ? variantImages[_frameIndex]
            : imageUrl;

    final String status = product.stockStatus;

    final bool outOfStock =
        status.toLowerCase().contains('out');

    final bool lowStock =
        !outOfStock &&
        (status.toLowerCase().contains('few') ||
            status.toLowerCase().contains('low'));

    final double sellingPrice = product.price;

    final double mrp =
        product.mrp ?? (sellingPrice * 1.5);

    final int discountPercent =
        product.discountPercent > 0
            ? product.discountPercent
            : (mrp > sellingPrice
                  ? (((mrp - sellingPrice) / mrp) * 100)
                      .toInt()
                  : 0);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,

      onEnter: _handleMouseEnter,
      onExit: _handleMouseExit,

      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPressStart: _handleLongPressStart,
        onLongPressEnd: _handleLongPressEnd,
        onLongPressCancel: () => _handleLongPressEnd(null),

        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: _hovered ? 1.03 : 1.0,

          child: AnimatedContainer(
            duration: const Duration(
              milliseconds: 180,
            ),

            decoration: BoxDecoration(
              color: AppColors.card,

              // Visible highlight border when hovered/long-pressed.
             // border: Border.all(
             //   color: _hovered
              //      ? AppColors.primary
               //     : Colors.transparent,
              //  width: 1.5,
            //  ),

              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(
                          alpha: 0.22,
                        ),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : AppColors.lightShadow,
            ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =============================================================
              // IMAGE AREA
              // =============================================================

              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // -------------------------------------------------------
                    // PRODUCT IMAGE
                    // -------------------------------------------------------

                    Container(
                      padding:
                          const EdgeInsets.fromLTRB(
                        10,
                        18,
                        10,
                        10,
                      ),
                      alignment: Alignment.center,

                      child: activeImageUrl.isNotEmpty
                          ? AnimatedSwitcher(
                              duration: const Duration(
                                milliseconds: 250,
                              ),
                              child: Image.network(
                                activeImageUrl,
                                // Key by URL so AnimatedSwitcher treats
                                // each color-variation frame as a new
                                // widget and cross-fades between them.
                                key: ValueKey(activeImageUrl),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,

                                errorBuilder:
                                    (_, __, ___) {
                                  return _placeholder();
                                },

                                loadingBuilder:
                                    (
                                      context,
                                      child,
                                      progress,
                                    ) {
                                  if (progress == null) {
                                    return child;
                                  }

                                  return const Center(
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : _placeholder(),
                    ),

                    // -------------------------------------------------------
                    // RATING / REVIEWS
                    // -------------------------------------------------------

                    Positioned(
                      bottom: 15,
                      left: 15,

                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),

                        decoration: BoxDecoration(
                          color: AppColors.cream
                              .withValues(alpha: 0.9),
                          borderRadius:
                              BorderRadius.circular(4),
                        ),

                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              product.rating
                                  .toStringAsFixed(1),

                              style:
                                  const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.bold,
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
                              color:
                                  Colors.grey.shade400,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              _formatReviewCount(
                                product.reviewCount,
                              ),

                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // -------------------------------------------------------
                    // WISHLIST HEART
                    // -------------------------------------------------------

                    Positioned(
                      top: 20,
                      right: 15,

                      child: _buildWishlistButton(),
                    ),

                    // -------------------------------------------------------
                    // LOW STOCK
                    // -------------------------------------------------------

                    if (lowStock)
                      Positioned(
                        bottom: 8,
                        right: 8,

                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),

                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFE05656),
                            borderRadius:
                                BorderRadius.circular(4),
                          ),

                          child: Text(
                            status.isNotEmpty
                                ? status
                                : 'Only Few Left',

                            style:
                                const TextStyle(
                              fontSize: 9,
                              fontWeight:
                                  FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // -------------------------------------------------------
                    // OUT OF STOCK
                    // -------------------------------------------------------

                    if (outOfStock)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,

                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(
                            vertical: 6,
                          ),

                          color:
                              const Color(0xFFE05656),

                          child: const Text(
                            'OUT OF STOCK',

                            textAlign:
                                TextAlign.center,

                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // =============================================================
              // SCROLL DOTS (Moved outside the image stack)
              // =============================================================
              
              if (_hovered && variantImages.length > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(variantImages.length, (i) {
                      final bool active = i == _frameIndex;

                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: active ? 12 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          // Use grey since it now sits on a white background
                          color: active
                              ? AppColors.primary
                              : Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),

              // =============================================================
              // PRODUCT DETAILS
              // =============================================================

              Padding(
                // Dynamically reduce top padding if the scroll dots are taking up space above
                padding: EdgeInsets.fromLTRB(
                  14,
                  (_hovered && variantImages.length > 1) ? 4 : 12,
                  14,
                  14,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // -------------------------------------------------------
                    // PRODUCT NAME
                    // -------------------------------------------------------

                    Text(
                      product.productName,

                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // -------------------------------------------------------
                    // SUBCATEGORY
                    // -------------------------------------------------------

                    Text(
                      product.subCategory,

                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // -------------------------------------------------------
                    // SHOP NAME
                    // -------------------------------------------------------

                    Text(
                      product.shopName,

                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // -------------------------------------------------------
                    // PRICE
                    // -------------------------------------------------------

                    Wrap(
                      crossAxisAlignment:
                          WrapCrossAlignment.center,
                      spacing: 5,

                      children: [
                        Text(
                          '₹${sellingPrice.toStringAsFixed(0)}',

                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w700,
                            color:
                                AppColors.primary,
                          ),
                        ),

                        if (discountPercent > 0) ...[
                          Text(
                            '₹${mrp.toStringAsFixed(0)}',

                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Colors.grey.shade500,
                              decoration:
                                  TextDecoration
                                      .lineThrough,
                            ),
                          ),

                          Text(
                            '($discountPercent% OFF)',

                            style:
                                const TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w700,
                              color: Color.fromARGB(
                                255,
                                46,
                                114,
                                52,
                              ),
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
      ),
    );
  }

  // =========================================================================
  // WISHLIST BUTTON
  // =========================================================================

  Widget _buildWishlistButton() {
    final bool disabled =
        widget.onWishlistTap == null ||
        widget.isWishlistUpdating;

    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),

      child: InkWell(
        onTap: disabled
            ? null
            : widget.onWishlistTap,

        customBorder:
            const CircleBorder(),

        child: Container(
          width: 34,
          height: 34,

          decoration:
              const BoxDecoration(
            color: AppColors.cream,
            shape: BoxShape.circle,
          ),

          child: Center(
            child: widget.isWishlistUpdating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    widget.isWishlisted
                        ? Icons.favorite
                        : Icons.favorite_border,

                    color: widget.isWishlisted
                        ? Colors.red
                        : AppColors.primary,

                    size: 20,
                  ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // PLACEHOLDER
  // =========================================================================

  Widget _placeholder() {
    return Container(
      color: AppColors.primaryLight,

      alignment: Alignment.center,

      child: const Icon(
        Icons.checkroom,
        color: AppColors.primary,
        size: 60,
      ),
    );
  }
}