import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';
import '../../widgets/app_colors.dart';
import '../auth/login_screen.dart';
// import '../auth/signup_screen.dart'; // uncomment when SignupScreen ready

/// Change this manually on each release, or wire up package_info_plus
/// if you want it to read from pubspec.yaml automatically.
const String kAppVersion = '1.0.0';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _userName = 'User';
  String _identifier = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // ApiService caches the token in memory after app restart only if
    // loadToken() has run — make sure this is also called once at app
    // startup (e.g. in main.dart) so a cold-launched app doesn't briefly
    // read AuthService.token as null.
    await AuthService.loadToken();

    final prefs = await SharedPreferences.getInstance();

    final name1 = prefs.getString('userName');
    final name2 = prefs.getString('user_name');
    final resolvedName = (name1 != null && name1.isNotEmpty)
        ? name1
        : ((name2 != null && name2.isNotEmpty) ? name2 : 'User');

    final token = AuthService.token;
    final identifier = prefs.getString('loginIdentifier') ?? '';
    final loggedIn = token != null && token.isNotEmpty;

    if (!mounted) return;
    setState(() {
      _userName = resolvedName;
      _identifier = identifier;
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    // AuthService.logout() catches its own errors internally and never
    // throws, so we can't rely on try/catch here. Explicitly force-clear
    // the token afterwards regardless of the server call's outcome —
    // clearToken() is idempotent, so calling it twice is harmless. This is
    // a safety net on top of the auth_service.dart fix (logout() should
    // now clear the token even when the server call fails).
    await AuthService.logout();
    await AuthService.clearToken();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('user_name');
    await prefs.remove('loginIdentifier');

    if (!mounted) return;

    setState(() {
      _isLoggedIn = false;
      _userName = 'User';
      _identifier = '';
      _isLoading = false;
    });
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    ).then((_) => _loadProfileData());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
              context.pop();
          },
        ),
        title: const Text('Profile'),
        elevation: 0,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: _isLoggedIn ? _buildLoggedInView() : _buildLoggedOutView(),
            ),
    );
  }

  // ---------------------------------------------------------------------
  // LOGGED OUT VIEW
  // ---------------------------------------------------------------------
  Widget _buildLoggedOutView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Empty avatar + Login/Signup button row
          Row(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.textGrey,
                child: Icon(Icons.person, size: 34, color: AppColors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Login to see your orders & wishlist',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _goToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 2,
                ),
                child: const Text(
                  'Login / Signup',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          _buildSectionCard([
            _buildTile(
              icon: Icons.favorite_border,
              title: 'Wishlist',
              onTap: _goToLogin,
            ),
            _buildTile(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.notifications_none,
              title: 'Notification Settings',
              onTap: () {},
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 16),

          _buildSectionCard([
            _buildTile(icon: Icons.quiz_outlined, title: 'FAQs', onTap: () {}),
            _buildTile(
              icon: Icons.info_outline,
              title: 'About Us',
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.description_outlined,
              title: 'Terms, License & Policies',
              onTap: () {},
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 24),

          _buildAppVersion(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // LOGGED IN VIEW
  // ---------------------------------------------------------------------
  Widget _buildLoggedInView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User name top left
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 18),

          // Profile image, centered
          Center(
            child: Stack(
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.gold,
                  child: Icon(Icons.person, size: 54, color: AppColors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.brown,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 14,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _buildSectionCard([
            _buildTile(
              icon: Icons.dashboard_outlined,
              title: 'Overview',
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.receipt_long_outlined,
              title: 'Orders',
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.favorite_border,
              title: 'Wishlist',
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.local_offer_outlined,
              title: 'Coupons',
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.help_outline,
              title: 'Help Center',
              onTap: () {},
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 16),

          _buildSectionCard([
            _buildTile(
              icon: Icons.credit_card,
              title: 'Saved Cards',
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.location_on_outlined,
              title: 'Saved Addresses',
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.notifications_none,
              title: 'Notification Settings',
              onTap: () {},
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 16),

          _buildSectionCard([
            _buildTile(icon: Icons.quiz_outlined, title: 'FAQs', onTap: () {}),
            _buildTile(
              icon: Icons.info_outline,
              title: 'About Us',
              onTap: () {},
            ),
            _buildTile(
              icon: Icons.description_outlined,
              title: 'Terms, License & Policies',
              onTap: () {},
              showDivider: false,
            ),
          ]),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildAppVersion(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SHARED WIDGETS
  // ---------------------------------------------------------------------
  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      // ClipRRect + Material (with matching radius) gives ListTile a proper
      // clipped Material ancestor, so ink splashes render correctly instead
      // of throwing "ListTile background color or ink splashes may be
      // invisible". The outer Container stays unclipped so the shadow shows.
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: AppColors.white,
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.brown),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: AppColors.textGrey,
          ),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildAppVersion() {
    return Center(
      child: Text(
        'App Version $kAppVersion',
        style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
      ),
    );
  }
}
