import 'package:flutter/material.dart';
import 'main_scaffold.dart'; // for AppColors

class BagScreen extends StatelessWidget {
  const BagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text('Your bag is empty', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}