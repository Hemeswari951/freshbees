import 'package:flutter/material.dart';
import '../../../widgets/app_colors.dart';

class HomeGreeting extends StatelessWidget {
  final String userName;

  const HomeGreeting({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.paddingMD,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            "Hello, $userName 👋",
            style: AppColors.title,
          ),

          const SizedBox(height: 6),

          Text(
            "Discover beautiful collections\nfrom nearby boutiques.",
            style: AppColors.body,
          ),
        ],
      ),
    );
  }
}