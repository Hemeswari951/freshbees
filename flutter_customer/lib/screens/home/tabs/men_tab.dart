import 'package:flutter/material.dart';

/// Content shown when the "Men" toggle is selected on Home.
/// Replace the placeholder below with your real "Men" category content.
class MenTab extends StatelessWidget {
  const MenTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Men toggle selected',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}