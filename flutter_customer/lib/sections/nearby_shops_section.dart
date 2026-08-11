import 'package:flutter/material.dart';

import '../widgets/app_colors.dart';
import '../widgets/nearby_shop_card.dart';
import '../widgets/section_header.dart';

class NearbyShopsSection extends StatelessWidget {
  const NearbyShopsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Temporary Dummy Data
    // Later this will come from ShopService API
    final shops = [
      {
        "shopName": "Lakshmi Boutique",
        "ownerName": "Lakshmi",
        "address": "Coimbatore",
        "image": "",
      },
      {
        "shopName": "Sri Fashion",
        "ownerName": "Priya",
        "address": "Tiruppur",
        "image": "",
      },
      {
        "shopName": "Elegant Wear",
        "ownerName": "Meena",
        "address": "Erode",
        "image": "",
      },
      {
        "shopName": "Royal Textiles",
        "ownerName": "Karthik",
        "address": "Salem",
        "image": "",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Nearby Shops",
          onSeeAll: () {
            // TODO: Navigate to All Shops Screen
          },
        ),

        const SizedBox(height: 10),

        SizedBox(
          height: 235,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.paddingMD,
            ),
            scrollDirection: Axis.horizontal,
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index];

              return NearbyShopCard(
                shopName: shop["shopName"]!,
                ownerName: shop["ownerName"]!,
                address: shop["address"]!,
                imageUrl: shop["image"],
                onTap: () {
                  // TODO:
                  // Navigate to Shop Details Screen
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