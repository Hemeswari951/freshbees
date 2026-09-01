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
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

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
  }

  void _handleMouseExit(_) {
    if (!mounted || !_hovered) return;

    setState(() {
      _hovered = false;
    });
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

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),

          decoration: BoxDecoration(
            color: AppColors.card,

            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 2,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
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

                      child: product.thumbnail.isNotEmpty
                          ? Image.network(
                              imageUrl,
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
              // PRODUCT DETAILS
              // =============================================================

              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  14,
                  12,
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