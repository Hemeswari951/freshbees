import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../screens/product/product_details_screen.dart';
import '../services/product_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/product_card.dart';
import '../widgets/section_header.dart';

class RecommendedProductsSection extends StatelessWidget {
  const RecommendedProductsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: "Recommended For You",
          onSeeAll: () {
            // TODO: Navigate to All Products Screen
          },
        ),

        FutureBuilder<List<ProductModel>>(
          future: ProductService.getProducts(),
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Error
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    "Unable to load products",
                  ),
                ),
              );
            }

            final products = snapshot.data ?? [];

            // Empty
            if (products.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    "No Products Available",
                  ),
                ),
              );
            }

            // Product Grid
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppColors.paddingMD,
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.62,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];

                  return ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductViewScreen(
                            productId: product.id,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}