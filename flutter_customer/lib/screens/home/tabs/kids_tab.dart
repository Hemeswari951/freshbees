import 'package:flutter/material.dart';

/// Content shown when the "Kids" toggle is selected on Home.
/// Replace the placeholder below with your real "Kids" category content.
class KidsTab extends StatelessWidget {
  const KidsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Kids toggle selected',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}