import 'package:flutter/material.dart';
import '../main_scaffold.dart'; // for AppColors

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Center(child: Text('Settings Screen - To be implemented', style: TextStyle(color: AppColors.textSecondary))),
    );
  }
}