import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';
import 'app_colors.dart';

/// Product card for the CUSTOMER portal — styling ported over 1:1 from
/// the ADMIN portal's `_productCard` (ProductsScreen) so both portals
/// look identical: image fills the top area, a white rating pill sits
/// bottom-left over the image, low-stock / out-of-stock tags overlay
/// the image, and the text block below uses the same Myntra-style
/// price row (price, struck-through MRP, "(X% OFF)").
///
/// Card shape is a plain square — no border, no rounded corners.
///
/// Two things were kept from the ORIGINAL customer card because the
/// admin card doesn't need them at all:
///   1. The wishlist heart (top-right, over the image). Tapping it is
///      handled entirely by the parent (ProductListScreen) — it checks
///      login state, sends guests to the login page, and only calls
///      ProductService's wishlist methods for logged-in users.
///   2. Hover elevation now also works here (StatefulWidget + MouseRegion),
///      matching the admin grid's hover behaviour on desktop/web.
///
/// NOTE: the admin card reads `avgRating` / `reviews` from its raw
/// product Map, with a fallback of 4.3 / '11.6k' when the backend
/// hasn't joined ratings yet. `ProductModel` here doesn't currently
/// expose rating fields, so the same fallback constants are used below.
/// If/when ProductModel gets `avgRating` / `reviewCount`, swap the two
/// `_fallbackRating` / `_fallbackReviews` lines for the real fields.
class ProductCard extends StatefulWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  /// Whether this product is currently in the customer's wishlist —
  /// controls whether the heart renders filled (red) or outlined.
  final bool isWishlisted;

  /// Called when the heart icon is tapped. Left null on call sites that
  /// don't wire up the wishlist (heart just renders outlined and static).
  final VoidCallback? onWishlistTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.isWishlisted = false,
    this.onWishlistTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  static const double _fallbackRating = 4.3;
  static const String _fallbackReviews = '11.6k';

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    final imageUrl = product.thumbnail.isNotEmpty
        ? "${ApiService.serverUrl}${product.thumbnail}"
        : '';

    final String status = product.stockStatus;
    final bool outOfStock = status.toLowerCase().contains('out');
    final bool lowStock =
        !outOfStock &&
        (status.toLowerCase().contains('few') ||
            status.toLowerCase().contains('low'));

    final double sellingPrice = product.price;
    final double mrp = product.mrp ?? (sellingPrice * 1.5);
    final int discountPercent = product.discountPercent > 0
        ? product.discountPercent
        : (mrp > sellingPrice
              ? (((mrp - sellingPrice) / mrp) * 100).toInt()
              : 0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            // Square card — no border, no rounded corners.
            color: AppColors.card,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 2,
                      spreadRadius: 1,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : AppColors.lightShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Base image
                    Container(
                      padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                      alignment: Alignment.center,
                      child: product.thumbnail.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => _placeholder(),
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
                          : _placeholder(),
                    ),

                    // White rating & reviews pill (bottom-left)
                    Positioned(
                      bottom: 15,
                      left: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cream.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _fallbackRating.toStringAsFixed(1),
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
                              _fallbackReviews,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Wishlist heart (top-right) — customer-only addition,
                    // admin card has no equivalent. Login check + API call
                    // happens in the parent's onWishlistTap callback.
                    Positioned(
                      top: 20,
                      right: 15,
                      child: GestureDetector(
                        onTap: widget.onWishlistTap,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            color: AppColors.cream,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
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

                    // Low stock tag
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
                            status.isNotEmpty ? status : 'Only Few Left',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Out of stock overlay
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
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Text details section
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product name
                    Text(
                      product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),

                    // Shop name (admin shows subCategory here — customer
                    // keeps shopName since that's what ProductModel has)
                    Text(
                      product.shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppColors.caption,
                    ),
                    const SizedBox(height: 4),

                    // Myntra-style pricing row
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 5,
                      children: [
                        Text(
                          "₹${sellingPrice.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (discountPercent > 0) ...[
                          Text(
                            "₹${mrp.toStringAsFixed(0)}",
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