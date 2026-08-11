import 'package:flutter/material.dart';

/// Content shown when the "All" toggle is selected on Home.
/// Replace the placeholder below with your real "All" category content.
class AllTab extends StatelessWidget {
  const AllTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'All toggle selected',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }
}