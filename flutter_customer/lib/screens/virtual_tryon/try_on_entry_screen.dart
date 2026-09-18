import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/product_model.dart';
import '../../services/api_service.dart';
import '../../services/tryon_profile_service.dart';

class TryOnEntryScreen extends StatefulWidget {
  final ProductModel? product;
  final bool skipProfileSelection;

  const TryOnEntryScreen({
    super.key,
    this.product,
    this.skipProfileSelection = false,
  });

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
  await Future.delayed(
    const Duration(milliseconds: 200),
  );

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
  // 2. CHECK STYLE PROFILE + TRY-ON PROFILES
  // ==========================================

  try {
    final response = await ApiService.get('/style-profile');

    final profiles =
        await TryOnProfileService.getProfiles();

    if (!mounted) return;

    // Main customer style profile
    final mainStyleProfile = response['data'];

    // ==========================================
    // 3. FIND PRIMARY TRY-ON PROFILE
    // ==========================================

    final primaryProfile = profiles.isNotEmpty
        ? profiles.firstWhere(
            (profile) =>
                profile.isDefault ||
                profile.relationship.toLowerCase() == 'self' ||
                profile.profileName.toLowerCase() == 'me',
            orElse: () => profiles.first,
          )
        : null;

    // ==========================================
    // 4. SKIP PROFILE SELECTION
    // ==========================================

    if (widget.skipProfileSelection &&
        primaryProfile != null) {
      if (widget.product != null) {
        context.pushReplacement(
  '/virtual-tryon/review',
  extra: {
    'product': widget.product,
    'photo': null,
    'photoUrl': primaryProfile.photoUrl,
    'selectedProfile': primaryProfile,
    'customerProfile': null,
  },
);
      } else {
        context.pushReplacement(
          '/virtual-tryon/select-profile',
        );
      }

      return;
    }

    // ==========================================
    // 5. MAIN STYLE PROFILE EXISTS
    // → GO TO SELECT PROFILE
    // ==========================================

    if (mainStyleProfile != null) {
      if (widget.product != null) {
        context.pushReplacement(
          '/virtual-tryon/select-profile',
          extra: {
            'product': widget.product,
          },
        );
      } else {
        context.pushReplacement(
          '/virtual-tryon/select-profile',
        );
      }

      return;
    }

    // ==========================================
    // 6. MAIN STYLE PROFILE DOES NOT EXIST
    // → CREATE STYLE PROFILE
    // ==========================================

    context.pushReplacement(
      '/virtual-tryon/style-profile?source=trial',
    );
  } catch (e) {
    debugPrint(
      'Try-On Entry Error: $e',
    );

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