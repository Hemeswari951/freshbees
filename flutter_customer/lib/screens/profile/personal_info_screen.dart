import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../services/tryon_profile_service.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';
import '../../models/tryon_profile_model.dart';

class PersonalInfoScreen extends StatefulWidget {
  final TryOnProfile? selectedProfile;

  const PersonalInfoScreen({super.key, this.selectedProfile});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // ============================================================
  // COLORS (unchanged - your existing theme)
  // ============================================================

  static const Color _bg = Color(0xFFF6F6F7);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _cardBg = Colors.white;
  static const Color _border = Color(0xFFE8E0D6);
  static const Color _softBg = Color(0xFFF2ECE4);
  static const Color _text = Color(0xFF1A1A1D);
  // static const Color _muted = Color(0xFF8A8A8E);

  // ============================================================
  // STATE
  // ============================================================

  List<TryOnProfile> _profiles = [];
  bool _loadingProfiles = true;
  String? _profileError;

  ProfileModel? _customerProfile;
  bool _loadingCustomerProfile = true;
  String? _customerProfileError;

  TryOnProfile? get _selectedTryOnProfile => widget.selectedProfile;

  bool get _isMainCustomerSelected => widget.selectedProfile == null;

  // ============================================================
  // FORMAT HELPERS
  // ============================================================

  String _displayValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Not added';
    }
    return value;
  }

  String _listValue(List<String> values) {
    if (values.isEmpty) {
      return 'Not added';
    }
    return values.join(', ');
  }

  String _locationValue(ProfileModel profile) {
    final parts = <String>[];

    if (profile.city != null && profile.city!.trim().isNotEmpty) {
      parts.add(profile.city!.trim());
    }

    if (profile.state != null && profile.state!.trim().isNotEmpty) {
      parts.add(profile.state!.trim());
    }

    if (parts.isEmpty) {
      return 'Not added';
    }

    return parts.join(', ');
  }

  String _formatDateOfBirth(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Not added';
  }

  try {
    final date = DateTime.parse(value);

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  } catch (_) {
    return value;
  }
}
  @override
  void initState() {
    super.initState();
    _loadCustomerProfile();
    _loadProfiles();
  }

  // ============================================================
  // LOAD CUSTOMER PROFILE
  // ============================================================

  Future<void> _loadCustomerProfile() async {
    if (mounted) {
      setState(() {
        _loadingCustomerProfile = true;
        _customerProfileError = null;
      });
    }

    try {
      final profile = await ProfileService.getProfile();

      if (!mounted) return;

      setState(() {
        _customerProfile = profile;
        _loadingCustomerProfile = false;
      });
    } catch (e) {
      debugPrint('CUSTOMER PROFILE ERROR: $e');

      if (!mounted) return;

      setState(() {
        _customerProfile = null;
        _loadingCustomerProfile = false;
        _customerProfileError = e.toString().replaceFirst('Exception: ', '');
      });
    }
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
        _profileError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ============================================================
  // OPEN PROFILE
  // ============================================================

  void _openProfile(TryOnProfile profile) {
    context.push('/profile/my-profile', extra: profile);
  }

  // ============================================================
  // ADD PROFILE
  // ============================================================

  Future<void> _addProfile() async {
    await context.push('/virtual-tryon/add-profile');

    if (!mounted) return;

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
    return Container(
      color: _bg,
      child: RefreshIndicator(
        color: _accent,
        onRefresh: () async {
          await Future.wait([_loadCustomerProfile(), _loadProfiles()]);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isMainCustomerSelected) ...[
                _buildWelcomeSection(),

                const SizedBox(height: 24),

                _buildQuickActions(),

                const SizedBox(height: 28),

                _buildCustomerDetailsSection(),

                const SizedBox(height: 28),

                _buildTryOnProfilesSection(),

                const SizedBox(height: 28),

                _buildAccountSection(),
              ] else ...[
                _buildTryOnProfileDetails(),
              ],

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
            decoration: const BoxDecoration(
              color: _softBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline, color: _accent, size: 28),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
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
                  _customerProfile?.fullName.trim().isNotEmpty == true
                      ? _customerProfile!.fullName.trim()
                      : 'Welcome',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),

                const SizedBox(height: 3),

                const Text(
                  'Discover fashion made for you.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
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
        _sectionTitle('QUICK ACTIONS'),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                icon: Icons.shopping_bag_outlined,
                title: 'My Orders',
                subtitle: 'Track orders',
                onTap: () {
                  context.go('/profile/details?section=orders');
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
                  context.go('/profile/details?section=saved-address');
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
              child: Icon(icon, color: _accent, size: 22),
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
                    style: const TextStyle(fontSize: 10, color: Colors.black45),
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
  // CUSTOMER (MAIN PROFILE) DETAILS  -- new concept from colleague
  // ============================================================

  Widget _buildCustomerDetailsSection() {
    if (_loadingCustomerProfile) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
        ),
      );
    }

    if (_customerProfileError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.black45),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _customerProfileError!,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: _loadCustomerProfile,
              child: const Text('Retry', style: TextStyle(color: _accent)),
            ),
          ],
        ),
      );
    }

    final profile = _customerProfile;

    if (profile == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('PERSONAL DETAILS')),

            TextButton(
              onPressed: () {
                context.push('/profile/personal-details');
              },
              child: const Text('Edit', style: TextStyle(color: _accent)),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              _detailRow(
                icon: Icons.person_outline,
                label: 'Name',
                value: profile.fullName,
              ),
              _detailDivider(),
              _detailRow(
                icon: Icons.wc_outlined,
                label: 'Gender',
                value: _displayValue(profile.gender),
              ),
              _detailDivider(),
              _detailRow(
                icon: Icons.cake_outlined,
                label: 'Date of Birth',
                value: _formatDateOfBirth(profile.dateOfBirth),
              ),
              _detailDivider(),
              _detailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: _displayValue(profile.phone),
              ),
              _detailDivider(),
              _detailRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: _displayValue(profile.email),
              ),
              _detailDivider(),
              _detailRow(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: _locationValue(profile),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _buildStyleDetails(profile),
      ],
    );
  }

  Widget _buildStyleDetails(ProfileModel profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('MY STYLE')),

            TextButton(
              onPressed: () {
                context.push('/virtual-tryon/style-profile?source=tryon');
              },
              child: const Text('Edit', style: TextStyle(color: _accent)),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              _detailRow(
                icon: Icons.checkroom_outlined,
                label: 'Usual Size',
                value: _displayValue(profile.apparelSize),
              ),
              _detailDivider(),
              _detailRow(
                icon: Icons.straighten_outlined,
                label: 'Fit Preference',
                value: _displayValue(profile.fitPreference),
              ),
              _detailDivider(),
              _detailRow(
                icon: Icons.palette_outlined,
                label: 'Preferred Colors',
                value: _listValue(profile.preferredColors),
              ),
              _detailDivider(),
              _detailRow(
                icon: Icons.style_outlined,
                label: 'Preferred Styles',
                value: _listValue(profile.preferredStyles),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TRY-ON PROFILE DETAILS (when a profile is selected) -- new concept
  // ============================================================

  Widget _buildTryOnProfileDetails() {
  final profile = _selectedTryOnProfile;

  if (profile == null) {
    return const SizedBox.shrink();
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ==========================================
      // PROFILE HEADER
      // ==========================================

      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.profileName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  profile.relationship,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
            ),
          ),

          TextButton(
  onPressed: () async {
    final updated = await context.push(
      '/virtual-tryon/add-profile',
      extra: profile,
    );

    if (updated == true && mounted) {
      await _loadProfiles();
    }
  },
  child: const Text(
    'Edit',
    style: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _accent,
    ),
  ),
),
        ],
      ),

      const SizedBox(height: 20),

      // ==========================================
      // PROFILE DETAILS
      // ==========================================

      const Text(
        'PROFILE DETAILS',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Colors.black45,
        ),
      ),

      const SizedBox(height: 8),

      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          children: [
            _detailRow(
              icon: Icons.person_outline,
              label: 'Name',
              value: _displayValue(profile.profileName),
            ),

            _detailDivider(),

            _detailRow(
              icon: Icons.people_outline,
              label: 'Relationship',
              value: _displayValue(profile.relationship),
            ),

            _detailDivider(),

            _detailRow(
              icon: Icons.wc_outlined,
              label: 'Gender',
              value: _displayValue(profile.gender),
            ),

            _detailDivider(),

            _detailRow(
              icon: Icons.cake_outlined,
              label: 'Date of Birth',
              value: _formatDateOfBirth(
                profile.dateOfBirth,
              ),
            ),

            _detailDivider(),

            _detailRow(
              icon: Icons.checkroom_outlined,
              label: 'Size',
              value: _displayValue(profile.size),
            ),

            _detailDivider(),

            _detailRow(
              icon: Icons.height,
              label: 'Height',
              value: profile.height != null
                  ? '${profile.height} cm'
                  : 'Not added',
            ),

            _detailDivider(),

            _detailRow(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: profile.weight != null
                  ? '${profile.weight} kg'
                  : 'Not added',
            ),
          ],
        ),
      ),

      const SizedBox(height: 28),

      // ==========================================
      // TRY-ON PROFILE STYLE
      // ==========================================

      _buildTryOnStyleDetails(profile),
    ],
  );
}

  Widget _buildTryOnStyleDetails(TryOnProfile profile) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: TryOnProfileService.getProfileStyle(profileId: profile.profileId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('MY STYLE'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                  ),
                ),
              ),
            ],
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          final label = snapshot.hasError ? 'Edit' : 'Add';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _sectionTitle('MY STYLE')),
                  TextButton(
                    onPressed: () async {
                      final updated = await context.push(
                        '/virtual-tryon/style-profile',
                        extra: profile,
                      );

                      if (updated == true && mounted) {
                        setState(() {});
                      }
                    },
                    child: Text(label, style: const TextStyle(color: _accent)),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              _styleEmptyCard(),
            ],
          );
        }

        final style = snapshot.data!;

        final apparelSize = style['apparel_size']?.toString();
        final fitPreference = style['fit_preference']?.toString();

        final colors = style['preferred_colors'] is List
            ? (style['preferred_colors'] as List).map((e) => e.toString()).toList()
            : <String>[];

        final styles = style['preferred_styles'] is List
            ? (style['preferred_styles'] as List).map((e) => e.toString()).toList()
            : <String>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _sectionTitle('MY STYLE')),

                TextButton(
                  onPressed: () async {
                    final updated = await context.push(
                      '/virtual-tryon/style-profile',
                      extra: profile,
                    );

                    if (updated == true && mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text('Edit', style: TextStyle(color: _accent)),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _detailRow(
                    icon: Icons.checkroom_outlined,
                    label: 'Usual Size',
                    value: apparelSize != null && apparelSize.isNotEmpty
                        ? apparelSize
                        : 'Not added',
                  ),
                  _detailDivider(),
                  _detailRow(
                    icon: Icons.straighten_outlined,
                    label: 'Fit Preference',
                    value: fitPreference != null && fitPreference.isNotEmpty
                        ? fitPreference
                        : 'Not added',
                  ),
                  _detailDivider(),
                  _detailRow(
                    icon: Icons.palette_outlined,
                    label: 'Preferred Colors',
                    value: colors.isNotEmpty ? colors.join(', ') : 'Not added',
                  ),
                  _detailDivider(),
                  _detailRow(
                    icon: Icons.style_outlined,
                    label: 'Preferred Styles',
                    value: styles.isNotEmpty ? styles.join(', ') : 'Not added',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _styleEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: const Text(
        'No style preferences added yet.',
        style: TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  // ============================================================
  // TRY ON PROFILES (unchanged from your original)
  // ============================================================

  Widget _buildTryOnProfilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('YOUR TRY-ON PROFILES')),

            if (_profiles.isNotEmpty)
              InkWell(
                onTap: _viewAllProfiles,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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

  Widget _buildProfilesContent() {
    if (_loadingProfiles) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: _accent, strokeWidth: 2),
        ),
      );
    }

    if (_profileError != null) {
      return _buildProfileError();
    }

    if (_profiles.isEmpty) {
      return _buildNoProfiles();
    }

    final visibleProfiles = _profiles.take(3).toList();

    return SizedBox(
      height: 125,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: visibleProfiles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == visibleProfiles.length) {
            return _buildAddProfileCard();
          }

          return _buildProfileCard(visibleProfiles[index]);
        },
      ),
    );
  }

  Widget _buildProfileCard(TryOnProfile profile) {
    return InkWell(
      onTap: () => _openProfile(profile),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: profile.isDefault ? _accent : _border,
            width: profile.isDefault ? 1.2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProfileAvatar(profile),

            const SizedBox(height: 8),

            Text(
              profile.profileName.isNotEmpty ? profile.profileName : 'Profile',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
  // AVATAR
  // ============================================================

  Widget _buildProfileAvatar(TryOnProfile profile) {
    final photoUrl = profile.photoUrl;

    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      final imageUrl = ApiService.imageUrl(photoUrl);

      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _border),
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
      decoration: const BoxDecoration(color: _softBg, shape: BoxShape.circle),
      child: const Icon(Icons.person_outline, color: _accent, size: 25),
    );
  }

  // ============================================================
  // ADD PROFILE
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
          border: Border.all(color: _border),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: _accent, size: 27),

            SizedBox(height: 8),

            Text(
              'Add Profile',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _text,
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
          const Icon(Icons.person_add_alt_1_outlined, size: 34, color: _accent),

          const SizedBox(height: 10),

          const Text(
            'Create your first try-on profile',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 4),

          const Text(
            'Add a profile to make virtual try-on easier.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.black45),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: _addProfile,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('Add Profile'),
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
          const Icon(Icons.error_outline, color: Colors.black45),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              _profileError!,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ),

          TextButton(
            onPressed: _loadProfiles,
            child: const Text('Retry', style: TextStyle(color: _accent)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCOUNT
  // ============================================================

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('ACCOUNT'),

        const SizedBox(height: 12),

        _accountItem(
          icon: Icons.credit_card_outlined,
          title: 'Saved Cards',
          subtitle: 'Manage your saved payment methods',
          onTap: () {
            context.go('/profile/details?section=saved-cards');
          },
        ),

        _accountItem(
          icon: Icons.location_on_outlined,
          title: 'Saved Addresses',
          subtitle: 'Manage your delivery addresses',
          onTap: () {
            context.go('/profile/details?section=saved-address');
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
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
                child: Icon(icon, color: _accent, size: 21),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

              const Icon(Icons.chevron_right, size: 20, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SHARED DETAIL ROW / DIVIDER (new concept, styled with your colors)
  // ============================================================

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _softBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: _accent),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: _text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: _border),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Colors.black45,
      ),
    );
  }
}