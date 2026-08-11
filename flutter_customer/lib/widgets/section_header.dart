import 'package:flutter/material.dart';
import 'app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.paddingMD,
        vertical: AppColors.paddingSM,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: AppColors.sectionTitle,
          ),

          const Spacer(),

          InkWell(
            onTap: onSeeAll,
            borderRadius:
                BorderRadius.circular(AppColors.radiusSM),
            child: Row(
              children: [
                Text(
                  "See All",
                  style: AppColors.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(width: 4),

                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}