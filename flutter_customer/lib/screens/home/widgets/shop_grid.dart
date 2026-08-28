import 'package:flutter/material.dart';

import '../../../models/shop_model.dart';
import 'shop_card.dart';

class ShopGrid extends StatelessWidget {
  final List<ShopModel> shops;
  final Function(ShopModel) onShopTap;
  final String category;

  const ShopGrid({
    super.key,
    required this.shops,
    required this.onShopTap,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    if (shops.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No shops found.',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth;

        // ==========================================================
        // DESKTOP → 4 CARDS
        // MOBILE  → 2 CARDS
        // ==========================================================

        final bool isDesktop = availableWidth >= 768;

        final int visibleCards = isDesktop ? 4 : 2;

        const double spacing = 16;

        final double cardWidth =
            (availableWidth -
                    (spacing * (visibleCards - 1))) /
                visibleCards;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              shops.length,
              (index) {
                final ShopModel shop = shops[index];

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == shops.length - 1 ? 0 : spacing,
                  ),
                  child: ShopCard(
                    shop: shop,
                    width: cardWidth,
                    category: category,
                    onTap: () => onShopTap(shop),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}