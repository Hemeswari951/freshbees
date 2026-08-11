import 'package:flutter/material.dart';

import '../widgets/app_colors.dart';
import '../widgets/category_card.dart';
import '../widgets/section_header.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporary categories
    final categories = [
      {
        "name": "Sarees",
        "image": "",
      },
      {
        "name": "Kurtis",
        "image": "",
      },
      {
        "name": "Salwars",
        "image": "",
      },
      {
        "name": "Men",
        "image": "",
      },
      {
        "name": "Kids",
        "image": "",
      },
      {
        "name": "Bridal",
        "image": "",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Categories",
          onSeeAll: () {
            // TODO: Navigate to Categories Screen
          },
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.paddingMD,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, index) {
              final category = categories[index];

              return CategoryCard(
                categoryName: category["name"]!,
                imageUrl: category["image"],
                onTap: () {
                  // TODO: Navigate to Category Products Screen
                },
              );
            },
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}