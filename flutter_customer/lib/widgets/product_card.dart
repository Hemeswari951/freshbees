import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../services/api_service.dart';
import 'app_colors.dart';

class ProductCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final imageUrl =
        "${ApiService.serverUrl}${product.thumbnail}";

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusMD),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppColors.radiusMD),
          boxShadow: AppColors.lightShadow,
          border: Border.all(
            color: AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Product Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppColors.radiusMD),
                  ),
                  child: SizedBox(
                    height: 135,
                    width: double.infinity,
                    child: product.thumbnail.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return _placeholder();
                            },
                          )
                        : _placeholder(),
                  ),
                ),

                /// Discount Badge
                if (product.discountPercent > 0)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius:
                            BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${product.discountPercent}% OFF",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                /// Wishlist Icon
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: onWishlistTap,
                    child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? Colors.red : AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
                ),
              ],
            ),

            /// Product Details
          
            Padding(
                padding: const EdgeInsets.all(
                  AppColors.paddingSM,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppColors.productTitle,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      product.shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppColors.caption,
                    ),

                    // const SizedBox(height: 6),

                    // Text(
                    //   product.brandName,
                    //   maxLines: 1,
                    //   overflow: TextOverflow.ellipsis,
                    //   style: AppColors.caption,
                    // ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Text(
                          "₹${product.price.toStringAsFixed(0)}",
                          style: AppColors.price,
                        ),

                        const SizedBox(width: 6),

                        if (product.mrp != null)
                          Text(
                            "₹${product.mrp!.toStringAsFixed(0)}",
                            style:
                                AppColors.caption.copyWith(
                              decoration: TextDecoration
                                  .lineThrough,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      product.stockStatus,
                      style: TextStyle(
                        color: product.stockStatus ==
                                "In Stock"
                            ? Colors.green
                            : product.stockStatus ==
                                    "Only Few Left"
                                ? Colors.orange
                                : Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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