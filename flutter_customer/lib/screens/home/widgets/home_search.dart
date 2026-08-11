import 'package:flutter/material.dart';
import '../../../widgets/app_colors.dart';

class HomeSearch extends StatelessWidget {
  final VoidCallback? onTap;

  const HomeSearch({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.paddingMD,
        vertical: AppColors.paddingSM,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppColors.radiusMD),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppColors.radiusMD),
            border: Border.all(
              color: AppColors.border,
            ),
            boxShadow: AppColors.lightShadow,
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),

              Icon(
                Icons.search_rounded,
                color: AppColors.textSecondary,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  "Search for sarees, kurtis, shirts...",
                  style: AppColors.body,
                ),
              ),

              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}