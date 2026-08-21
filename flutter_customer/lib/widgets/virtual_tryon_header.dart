import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VirtualTryOnHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const VirtualTryOnHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: const Color(0xFFFAF7F2),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack ?? () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 20,
              color: Colors.black,
            ),
          ),

          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),

          // Keeps title centered
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}