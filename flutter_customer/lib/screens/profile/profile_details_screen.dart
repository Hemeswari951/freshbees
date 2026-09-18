import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_colors.dart';

import '../../models/profile_section.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

import 'personal_info_screen.dart';
import 'orders_screen.dart';
import 'coupons_screen.dart';
import 'saved_cards_screen.dart';
import 'saved_addresses_screen.dart';
import 'notifications_settings_screen.dart';
import 'help_centre_screen.dart';
import 'faq_screen.dart';
import 'about_us_screen.dart';
import 'terms_policies_screen.dart';

const double kDesktopBreakpoint = 900;

class ProfileDetailsScreen extends StatefulWidget {
  final ProfileSection initialSection;

  const ProfileDetailsScreen({super.key, required this.initialSection});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late ProfileSection _selectedSection;

  String _userName = 'User';

  @override
  void initState() {
    super.initState();

    _selectedSection = widget.initialSection;

    _loadUserDetails();
  }

  @override
  void didUpdateWidget(covariant ProfileDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialSection != widget.initialSection) {
      setState(() {
        _selectedSection = widget.initialSection;
      });
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      final name = await ApiService.getUserName();

      if (!mounted) return;

      setState(() {
        _userName = name?.trim().isNotEmpty == true ? name!.trim() : 'User';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _userName = 'User';
      });
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();

    if (!mounted) return;

    context.go('/home');
  }

  void _selectSection(ProfileSection section) {
    if (_selectedSection == section) return;

    setState(() {
      _selectedSection = section;
    });

    context.go('/profile/details?section=${section.slug}');
  }

  // Shared decoration so every card (content card + header card +
  // each nav-link card) looks identical — used on DESKTOP (rounded corners).
  BoxDecoration get _cardDecoration => BoxDecoration(
    color: AppColors.cardColor,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: AppColors.line),
  );

  // Same card look but with NO border radius — used on MOBILE only
  // (header card + content card).
  BoxDecoration get _mobileCardDecoration => BoxDecoration(
    color: AppColors.cardColor,
    border: Border.all(color: AppColors.line),
  );

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= kDesktopBreakpoint;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildContentCard(_selectedSection)),
          const SizedBox(width: 16),

          SizedBox(width: 300, child: _buildNavigationPanel()),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fixed mobile header
        _buildMobileHeader(),

        const SizedBox(height: 5),

        // Only content scrolls
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              decoration: _mobileCardDecoration,
              padding: const EdgeInsets.all(20),
              child: _buildContent(_selectedSection),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE HEADER — back button + selected section name, same
  // card background as the content below it, no border radius
  // ============================================================

  Widget _buildMobileHeader() {
    return Container(
      width: double.infinity,
      decoration: _mobileCardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          ),

          Text(
            _selectedSection.label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEFT SIDE — CONTENT AS ONE SINGLE CARD
  // ============================================================

  Widget _buildContentCard(ProfileSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDesktopHeader(section),

        const SizedBox(height: 10), // same gap style as the nav panel

        Container(
          width: double.infinity,
          decoration: _cardDecoration,
          padding: const EdgeInsets.all(20),
          child: _buildContent(section),
        ),
      ],
    );
  }

  // ============================================================
  // DESKTOP HEADER — its own card, title only, no back button
  // ============================================================

  Widget _buildDesktopHeader(ProfileSection section) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Text(
        section.label,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
    );
  }

  // ============================================================
  // RIGHT SIDE — NAVIGATION PANEL (header card + gap + link cards)
  // ============================================================

  Widget _buildNavigationPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildProfileHeaderCard(),

        const SizedBox(height: 10), // gap between header and link list

        Column(
          children: List.generate(ProfileSection.values.length, (index) {
            final section = ProfileSection.values[index];
            final isLast = index == ProfileSection.values.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: _buildNavigationItemCard(section),
            );
          }),
        ),

        const SizedBox(height: 10),
        // ============================================================
        // LOGOUT — BELOW ALL NAVIGATION LINKS
        // ============================================================
        _buildLogoutCard(),
      ],
    );
  }

  Widget _buildLogoutCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: _logout,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.line),
          ),
          child: const Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red),

              SizedBox(width: 12),

              Expanded(
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ============================================================
  // PROFILE HEADER — its own card: icon + "Hello, <name>"
  // ============================================================

  Widget _buildProfileHeaderCard() {
    return Container(
      decoration: _cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: AppColors.accentSoft,
            child: const Icon(Icons.person, color: AppColors.accent, size: 26),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Hello, $_userName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVIGATION ITEM — each one is its own separate card
  // ============================================================

  Widget _buildNavigationItemCard(ProfileSection section) {
    final selected = section == _selectedSection;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _selectSection(section),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                section.icon,
                size: 18,
                color: selected ? AppColors.accent : AppColors.ink,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  section.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent(ProfileSection section) {
    switch (section) {
      case ProfileSection.personalInfo:
        return const PersonalInfoScreen();

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
        return const NotificationsSettingsScreen();

      case ProfileSection.faqs:
        return const FaqScreen();

      case ProfileSection.aboutUs:
        return const AboutUsScreen();

      case ProfileSection.termsPolicies:
        return const TermsPoliciesScreen();
    }
  }
}
