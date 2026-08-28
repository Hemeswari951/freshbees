import 'package:flutter/material.dart';

import '../../../models/shop_model.dart';

class ShopCard extends StatelessWidget {
  final ShopModel shop;
  final VoidCallback onTap;
  final double width;
  final String category;

  const ShopCard({
    super.key,
    required this.shop,
    required this.onTap,
    required this.width,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // BANNER + LOGO
              // =====================================================

              Stack(
                clipBehavior: Clip.none,
                children: [
                  AspectRatio(
                    aspectRatio: 2.2,
                    child: _buildBanner(),
                  ),

                  // Logo overlaps the bottom-left of banner
                  Positioned(
                    left: 12,
                    bottom: -25,
                    child: _buildLogo(),
                  ),
                ],
              ),

              // Space for the overlapping logo
              const SizedBox(height: 30),

              // =====================================================
              // SHOP DETAILS
              // =====================================================

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // -------------------------------------------------
                    // SHOP NAME + RATING
                    // -------------------------------------------------

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Shop name
                        Expanded(
                          child: Text(
                            shop.shopName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Rating + count
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Color(0xFFFFB300),
                            ),

                            const SizedBox(width: 2),

                            Text(
                              shop.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(width: 3),

                            Text(
                              '(${shop.ratingCount})',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // -------------------------------------------------
                    // SELECTED CATEGORY
                    // -------------------------------------------------

                    Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
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

  // ================================================================
  // SHOP BANNER
  // ================================================================

  Widget _buildBanner() {
    if (shop.bannerUrl != null && shop.bannerUrl!.isNotEmpty) {
      return Image.network(
        shop.bannerUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _bannerPlaceholder();
        },
      );
    }

    return _bannerPlaceholder();
  }

  Widget _bannerPlaceholder() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8DFD1),
      alignment: Alignment.center,
      child: const Icon(
        Icons.storefront_outlined,
        size: 38,
        color: Colors.black26,
      ),
    );
  }

  // ================================================================
  // SHOP LOGO
  // ================================================================

  Widget _buildLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: shop.logoUrl != null && shop.logoUrl!.isNotEmpty
          ? Image.network(
              shop.logoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.storefront_outlined,
                  size: 27,
                  color: Colors.black38,
                );
              },
            )
          : const Icon(
              Icons.storefront_outlined,
              size: 27,
              color: Colors.black38,
            ),
    );
  }
}