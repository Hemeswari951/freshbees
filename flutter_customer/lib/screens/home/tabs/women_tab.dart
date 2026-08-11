import 'package:flutter/material.dart';

/// Content shown when the "Women" toggle is selected on Home.
/// Replace the placeholder below with your real "Women" category content.
class WomenTab extends StatelessWidget {
  const WomenTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Women toggle selected',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}