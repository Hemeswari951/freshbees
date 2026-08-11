import 'package:flutter/material.dart';

/// Content shown when the "Beauty" toggle is selected on Home.
/// Replace the placeholder below with your real "Beauty" category content.
class BeautyTab extends StatelessWidget {
  const BeautyTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Beauty toggle selected',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}