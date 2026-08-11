import 'package:flutter/material.dart';

import 'app_colors.dart';

class CategoryCard extends StatelessWidget {
  final String categoryName;
  final String? imageUrl;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.categoryName,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppColors.radiusMD),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 14),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.lightShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return const Icon(
                            Icons.checkroom_rounded,
                            size: 34,
                            color: AppColors.primary,
                          );
                        },
                      )
                    : const Icon(
                        Icons.checkroom_rounded,
                        size: 34,
                        color: AppColors.primary,
                      ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              categoryName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppColors.caption,
            ),
          ],
        ),
      ),
    );
  }
}