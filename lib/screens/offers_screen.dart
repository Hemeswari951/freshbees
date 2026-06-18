import 'package:flutter/material.dart';
import 'main_scaffold.dart'; // for AppColors

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_offer_outlined, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          Text('Offers coming soon', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}