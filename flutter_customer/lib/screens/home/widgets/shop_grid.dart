import 'package:flutter/material.dart';

import '../../../models/shop_model.dart';
import 'shop_card.dart';

class ShopGrid extends StatelessWidget {
  final List<ShopModel> shops;
  final Function(ShopModel) onShopTap;
  final String category;
  final int? maxItems; // Limit items for home preview (e.g. max 4)

  const ShopGrid({
    super.key,
    required this.shops,
    required this.onShopTap,
    required this.category,
    this.maxItems,
  });

  @override
  Widget build(BuildContext context) {
    final displayShops = maxItems != null && shops.length > maxItems!
        ? shops.take(maxItems!).toList()
        : shops;

    if (displayShops.isEmpty) {
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
        final double availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : 0;

        final bool isDesktop = availableWidth >= 768;
        final int visibleCards = isDesktop ? 4 : 2;
        const double spacing = 16;
        const double fallbackCardWidth = 140;

        final double rawCardWidth =
            (availableWidth - (spacing * (visibleCards - 1))) / visibleCards;

        final double cardWidth =
            rawCardWidth.isFinite && rawCardWidth > 0
                ? rawCardWidth
                : fallbackCardWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              displayShops.length,
              (index) {
                final ShopModel shop = displayShops[index];

                return Padding(
                  padding: EdgeInsets.only(
                    right: index == displayShops.length - 1 ? 0 : spacing,
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