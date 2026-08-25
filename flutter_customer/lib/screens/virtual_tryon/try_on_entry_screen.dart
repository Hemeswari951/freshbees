import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';

class TryOnEntryScreen extends StatefulWidget {
  const TryOnEntryScreen({super.key});

  @override
  State<TryOnEntryScreen> createState() => _TryOnEntryScreenState();
}

class _TryOnEntryScreenState extends State<TryOnEntryScreen> {
  @override
  void initState() {
    super.initState();

    _checkTryOnEntry();
  }

  Future<void> _checkTryOnEntry() async {
    // Small delay so the entry screen does not feel abrupt.
    await Future.delayed(const Duration(milliseconds: 200));

    if (!mounted) return;

    // ==========================================
    // 1. CHECK LOGIN
    // ==========================================

    final token = ApiService.getToken();

    if (token == null || token.isEmpty) {
      context.go('/login?redirect=/trial');
      return;
    }

    // ==========================================
    // 2. CHECK STYLE PROFILE
    // ==========================================

    try {
      final response = await ApiService.get('/style-profile');

      if (!mounted) return;

      final profile = response['data'];

      // ==========================================
      // PROFILE EXISTS
      // → GO DIRECTLY TO PHOTO PAGE
      // ==========================================

      if (profile != null) {
        context.go('/virtual-tryon/select-profile');
        return;
      }

      // ==========================================
      // PROFILE DOES NOT EXIST
      // → OPEN STYLE PROFILE
      // ==========================================

      context.go('/virtual-tryon/style-profile');
    } catch (e) {
      debugPrint('Try-On Entry Error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load your style profile. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}