import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../services/tryon_profile_service.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFE8E0D6);
  static const Color _softBg = Color(0xFFF2ECE4);

  // ============================================================
  // STATE
  // ============================================================

  List<TryOnProfile> _profiles = [];

  bool _loadingProfiles = true;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  // ============================================================
  // LOAD TRY-ON PROFILES
  // ============================================================

  Future<void> _loadProfiles() async {
    if (mounted) {
      setState(() {
        _loadingProfiles = true;
        _profileError = null;
      });
    }

    try {
      final profiles = await TryOnProfileService.getProfiles();

      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _loadingProfiles = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _profiles = [];
        _loadingProfiles = false;
        _profileError =
            e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // OPEN PROFILE
  // ============================================================

  void _openProfile(TryOnProfile profile) {
    context.push(
      '/virtual-tryon/photo',
      extra: profile,
    );
  }

  // ============================================================
  // ADD PROFILE
  // ============================================================

  Future<void> _addProfile() async {
    await context.push('/virtual-tryon/add-profile');

    // Reload after returning from Add Profile
    await _loadProfiles();
  }

  // ============================================================
  // VIEW ALL
  // ============================================================

  void _viewAllProfiles() {
    context.push('/virtual-tryon/select-profile');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        color: _accent,
        onRefresh: _loadProfiles,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),

              const SizedBox(height: 24),

              _buildQuickActions(),

              const SizedBox(height: 28),

              _buildTryOnProfilesSection(),

              const SizedBox(height: 28),

              _buildAccountSection(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _softBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: _accent,
              size: 28,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: FutureBuilder<String?>(
              future: ApiService.getUserName(),
              builder: (context, snapshot) {
                final name =
                    snapshot.data?.trim().isNotEmpty == true
                        ? snapshot.data!
                        : 'Welcome';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WELCOME BACK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Colors.black45,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 3),

                    const Text(
                      'Discover fashion made for you.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK ACTIONS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Colors.black45,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                icon: Icons.shopping_bag_outlined,
                title: 'My Orders',
                subtitle: 'Track orders',
                onTap: () {
                  context.go(
                    '/profile/details?section=orders',
                  );
                },
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _quickActionCard(
                icon: Icons.location_on_outlined,
                title: 'Address',
                subtitle: 'Saved addresses',
                onTap: () {
                  context.go(
                    '/profile/details?section=saved-address',
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _softBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _accent,
                size: 22,
              ),
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TRY-ON PROFILES
  // ============================================================

  Widget _buildTryOnProfilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'YOUR TRY-ON PROFILES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.black45,
                ),
              ),
            ),

            if (_profiles.isNotEmpty)
              InkWell(
                onTap: _viewAllProfiles,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        _buildProfilesContent(),
      ],
    );
  }

  // ============================================================
  // PROFILE CONTENT
  // ============================================================

  Widget _buildProfilesContent() {
    if (_loadingProfiles) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            color: _accent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_profileError != null) {
      return _buildProfileError();
    }

    // No profiles
    if (_profiles.isEmpty) {
      return _buildNoProfiles();
    }

    // Show maximum 3 profiles + Add Profile
    final visibleProfiles = _profiles.take(3).toList();

    return SizedBox(
      height: 125,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleProfiles.length + 1,
        separatorBuilder: (_, __) =>
            const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == visibleProfiles.length) {
            return _buildAddProfileCard();
          }

          return _buildProfileCard(
            visibleProfiles[index],
          );
        },
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard(TryOnProfile profile) {
    return InkWell(
      onTap: () => _openProfile(profile),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: profile.isDefault
                ? _accent
                : _border,
            width: profile.isDefault ? 1.2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProfileAvatar(profile),

            const SizedBox(height: 8),

            Text(
              profile.profileName.isNotEmpty
                  ? profile.profileName
                  : 'Profile',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (profile.isDefault) ...[
              const SizedBox(height: 3),
              const Text(
                'Default',
                style: TextStyle(
                  fontSize: 9,
                  color: _accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROFILE AVATAR
  // ============================================================

  Widget _buildProfileAvatar(TryOnProfile profile) {
    final photoUrl = profile.photoUrl;

    if (photoUrl != null &&
        photoUrl.trim().isNotEmpty) {
      final imageUrl = ApiService.imageUrl(photoUrl);

      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: _border,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return _defaultProfileIcon();
            },
          ),
        ),
      );
    }

    return _defaultProfileIcon();
  }

  Widget _defaultProfileIcon() {
    return Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        color: _softBg,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_outline,
        color: _accent,
        size: 25,
      ),
    );
  }

  // ============================================================
  // ADD PROFILE CARD
  // ============================================================

  Widget _buildAddProfileCard() {
    return InkWell(
      onTap: _addProfile,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 95,
        decoration: BoxDecoration(
          color: _softBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _border,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: _accent,
              size: 27,
            ),

            SizedBox(height: 8),

            Text(
              'Add Profile',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NO PROFILES
  // ============================================================

  Widget _buildNoProfiles() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_add_alt_1_outlined,
            size: 34,
            color: _accent,
          ),

          const SizedBox(height: 10),

          const Text(
            'Create your first try-on profile',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Add a profile to make virtual try-on easier.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black45,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: _addProfile,
              icon: const Icon(
                Icons.add,
                size: 17,
              ),
              label: const Text(
                'Add Profile',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildProfileError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.black45,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _profileError!,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ),

          TextButton(
            onPressed: _loadProfiles,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCOUNT SECTION
  // ============================================================

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACCOUNT',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: Colors.black45,
          ),
        ),

        const SizedBox(height: 12),

        _accountItem(
          icon: Icons.person_outline,
          title: 'Personal Details',
          subtitle: 'Manage your profile information',
          onTap: () {
             context.push('/virtual-tryon/style-profile');
          },
        ),

        _accountItem(
          icon: Icons.credit_card_outlined,
          title: 'Saved Cards',
          subtitle: 'Manage your saved payment methods',
          onTap: () {
            context.go(
              '/profile/details?section=saved-cards',
            );
          },
        ),

        _accountItem(
          icon: Icons.location_on_outlined,
          title: 'Saved Addresses',
          subtitle: 'Manage your delivery addresses',
          onTap: () {
            context.go(
              '/profile/details?section=saved-address',
            );
          },
        ),
      ],
    );
  }

  Widget _accountItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _softBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: _accent,
                size: 21,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}