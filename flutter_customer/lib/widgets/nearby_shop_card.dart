import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'app_colors.dart';

class NearbyShopCard extends StatelessWidget {
  final String shopName;
  final String ownerName;
  final String address;
  final String? imageUrl;
  final VoidCallback? onTap;

  const NearbyShopCard({
    super.key,
    required this.shopName,
    required this.ownerName,
    required this.address,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image =
        imageUrl != null && imageUrl!.isNotEmpty
            ? "${ApiService.serverUrl}$imageUrl"
            : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusMD),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
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
            /// Shop Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppColors.radiusMD),
              ),
              child: SizedBox(
                height: 130,
                width: double.infinity,
                child: image != null
                    ? Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return _placeholder();
                        },
                      )
                    : _placeholder(),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppColors.paddingSM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppColors.productTitle,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    ownerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppColors.caption,
                  ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppColors.caption,
                        ),
                      ),
                    ],
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
        Icons.storefront,
        size: 50,
        color: AppColors.primary,
      ),
    );
  }
}