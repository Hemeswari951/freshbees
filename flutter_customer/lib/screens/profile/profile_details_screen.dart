import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import '../../models/profile_section.dart';
import '../../services/api_service.dart';
import 'orders_screen.dart';
import 'saved_addresses_screen.dart';
import 'saved_cards_screen.dart';
import 'overview_screen.dart';

import 'notifications_screen.dart';
import 'coupons_screen.dart';
import 'help_centre_screen.dart';
import 'faq_screen.dart';
import 'about_us_screen.dart';
import 'terms_policies_screen.dart';

// Same palette style as your mobile ProfileScreen — kept local to this file.
class _Palette {
  static const Color ink = Color(0xFF1A1A1D);
  static const Color surface = Colors.white;
  static const Color canvas = Color(0xFFF6F6F7);
  static const Color muted = Color(0xFF8A8A8E);
  static const Color line = Color(0xFFE7E7E9);
  static const Color accent = Color(0xFF17B978);
  static const Color accentSoft = Color(0xFFE4F7EE);
}

/// Breakpoint shared with the header's desktop nav. Below this, we render
/// content-only (no right toggle) since the mobile ProfileScreen already
/// gives users a way to pick a section before landing here.
const double kDesktopBreakpoint = 900;

class ProfileDetailsScreen extends StatefulWidget {
  /// Which section to open on. Comes from the `section` query param —
  /// see app_router.dart wiring below.
  final ProfileSection initialSection;

  const ProfileDetailsScreen({super.key, required this.initialSection});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late ProfileSection _selectedSection;
  String _userName = 'User';
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
    _loadUserName();
  }

  // If someone deep-links to a different section while this screen is
  // already open (e.g. header click while ProfileDetailsScreen is active),
  // go_router rebuilds this widget with a new `initialSection` — didUpdateWidget
  // catches that and updates the selection instead of ignoring it.
  @override
  void didUpdateWidget(covariant ProfileDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSection != widget.initialSection) {
      setState(() => _selectedSection = widget.initialSection);
    }
  }

  Future<void> _loadUserName() async {
    final name = await ApiService.getUserName();
    if (mounted) {
      setState(() => _userName = name ?? 'User');
    }
  }

  void _selectSection(ProfileSection section) {
    setState(() => _selectedSection = section);
    // Keep the URL in sync so refresh / back-button / share-link still
    // lands on the right tab, without pushing a new route each click.
    context.go('/profile/details?section=${section.slug}');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= kDesktopBreakpoint;

    return Scaffold(
      backgroundColor: _Palette.canvas,
      body: SafeArea(
        child: isDesktop
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: profile header + toggle list.
                    _buildRightToggleList(),

                    const SizedBox(width: 24),

                    // Right: content for the selected section.
                    Expanded(flex: 3, child: _buildContent(_selectedSection)),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildContent(_selectedSection),
              ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // RIGHT SIDE: profile header + TOGGLE (desktop only)
  // -------------------------------------------------------------------
  Widget _buildRightToggleList() {
    return Container(
      width: 260,
      color: _Palette.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile image + username, above the section toggle.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _Palette.accentSoft,
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: _Palette.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _Palette.ink,
                        ),
                      ),
                      if (_userEmail != null)
                        Text(
                          _userEmail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: _Palette.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: _Palette.line),
          const SizedBox(height: 8),
          // Section toggle — Column instead of ListView so the whole
          // page (left content + right toggle) shares one scroll.
          Column(
            children: List.generate(ProfileSection.values.length, (index) {
              final section = ProfileSection.values[index];
              final isSelected = section == _selectedSection;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: InkWell(
                  onTap: () => _selectSection(section),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _Palette.accentSoft
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? _Palette.accent
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          section.icon,
                          size: 18,
                          color: isSelected ? _Palette.accent : _Palette.ink,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            section.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? _Palette.ink
                                  : _Palette.ink.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // CONTENT SWITCH — replace each placeholder with your real widgets
  // (e.g. wire OrdersScreen's body in here, not the whole Scaffold).
  // -------------------------------------------------------------------
  Widget _buildContent(ProfileSection section) {
    switch (section) {
      case ProfileSection.overview:
        return const OverviewScreen();
      case ProfileSection.orders:
        return const OrdersScreen();
      case ProfileSection.coupons:
        return const CouponsScreen();
      case ProfileSection.savedCards:
        return const SavedCardsScreen();
      case ProfileSection.savedAddress:
        return const SavedAddressesScreen();
      case ProfileSection.helpCenter:
        return const HelpCentreScreen();
      case ProfileSection.notificationSettings:
        return const NotificationsScreen();
      case ProfileSection.faqs:
        return const FaqScreen();

      case ProfileSection.aboutUs:
        return const AboutUsScreen();

      case ProfileSection.termsPolicies:
        return const TermsPoliciesScreen();
    }
  }
}
