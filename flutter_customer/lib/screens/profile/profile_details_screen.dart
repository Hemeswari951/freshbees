import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/profile_section.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';

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
      appBar: AppBar(
        backgroundColor: _Palette.surface,
        surfaceTintColor: _Palette.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _Palette.ink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isDesktop ? 'My Account' : _selectedSection.label,
          style: const TextStyle(
            color: _Palette.ink,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: content for the selected section.
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _buildContent(_selectedSection),
                    ),
                  ),
                  const VerticalDivider(width: 1, color: _Palette.line),
                  // Right: toggle list of every section.
                  _buildRightToggleList(),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: _buildContent(_selectedSection),
              ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // RIGHT SIDE TOGGLE (desktop only)
  // -------------------------------------------------------------------
  Widget _buildRightToggleList() {
    return Container(
      width: 260,
      color: _Palette.surface,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: ProfileSection.values.length,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (context, index) {
          final section = ProfileSection.values[index];
          final isSelected = section == _selectedSection;
          return InkWell(
            onTap: () => _selectSection(section),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? _Palette.accentSoft : Colors.transparent,
                border: Border(
                  left: BorderSide(
                    color: isSelected ? _Palette.accent : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
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
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? _Palette.ink : _Palette.ink.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
        return _buildOverview();
      case ProfileSection.orders:
        return _placeholder(section);
      case ProfileSection.coupons:
        return _placeholder(section);
      case ProfileSection.savedCards:
        return _placeholder(section);
      case ProfileSection.savedAddress:
        return _placeholder(section);
      case ProfileSection.helpCenter:
        return _placeholder(section);
      case ProfileSection.notificationSettings:
        return _placeholder(section);
      case ProfileSection.faqs:
        return _placeholder(section);
      case ProfileSection.aboutUs:
        return _placeholder(section);
      case ProfileSection.termsPolicies:
        return _placeholder(section);
    }
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, $_userName',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _Palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This is your account overview.',
            style: TextStyle(color: _Palette.muted, fontSize: 13),
          ),
          const SizedBox(height: 24),
          // TODO: recent orders summary, quick stats, etc.
        ],
      ),
    );
  }

  // Temporary placeholder so every tab renders something meaningful while
  // you build out the real screens one by one.
  Widget _placeholder(ProfileSection section) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _Palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${section.label} content goes here.',
            style: const TextStyle(color: _Palette.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}