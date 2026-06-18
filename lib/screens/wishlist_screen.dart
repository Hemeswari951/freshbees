import 'package:flutter/material.dart';
import 'main_scaffold.dart'; // for AppColors

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text('Your wishlist is empty', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}