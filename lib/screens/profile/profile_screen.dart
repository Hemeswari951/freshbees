import 'package:flutter/material.dart';
import '../main_scaffold.dart'; // for AppColors, MainScaffold
import '../Login/login_screen.dart';
import '../wishlist_screen.dart';
import 'orders_screen.dart';
import 'coupons_screen.dart';
import 'manage_account_screen.dart';
import 'settings_screen.dart';

/// Login state is just a simple local flag for now - swap this for
/// your real auth result once OTP/login is fully wired up.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;

  // Demo values - replace with real user data once available.
  final String _name = 'Surya';
  final String _email = 'surya@example.com';

  static const List<String> _secondaryLinks = [
    'FAQs', 'About Us', 'Terms of Use', 'Privacy Policy', 'Grievance Redressal',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Profile', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeaderBanner(),

          // Basic + Size details only show once logged in.
          if (_isLoggedIn) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildDetailsRow(),
            ),
            const SizedBox(height: 16),
          ],

          _buildSectionDivider(),
          _buildMenuSection(),

          if (_isLoggedIn) ...[
            _buildSectionDivider(),
            _buildLogoutCard(),
          ],

          _buildSectionDivider(),
          _buildSecondaryLinksSection(),
          _buildAppVersionFooter(),
        ],
      ),
    );
  }

  // ---------------- Banner + overlapping round avatar + login/signup or name ----------------
  Widget _buildHeaderBanner() {
    return SizedBox(
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(height: 110, width: double.infinity, color: AppColors.banner),
          Positioned(
            top: 68,
            left: 16,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, // round avatar
                    color: AppColors.card,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Icon(Icons.person_rounded, size: 46, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _isLoggedIn
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_name, style: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text(_email, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: _goToLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cta, // distinct CTA color, not the same as accent
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text(
                            'LOG IN / SIGN UP',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.4),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Left: basic details, Right: size details ----------------
  Widget _buildDetailsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _detailsCard('Basic Details', [
            'Name: $_name',
            'Email: $_email',
            'Phone: -',
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _detailsCard('Size Details', [
            'Height: -',
            'Weight: -',
            'Top Size: -',
          ]),
        ),
      ],
    );
  }

  Widget _detailsCard(String title, List<String> lines) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(line, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // Light gray full-width bar used to separate sections, like the reference UI.
  Widget _buildSectionDivider() => Container(height: 10, color: AppColors.background);

  // ---------------- Menu: Orders, Wishlist, Coupons (+ Account/Settings if logged in) ----------------
  Widget _buildMenuSection() {
    final items = <_MenuItem>[
      _MenuItem(Icons.shopping_bag_outlined, 'Orders', 'Check your order status', () => const OrdersScreen()),
      // Same exact composition the footer uses for its Wishlist tab,
      // so clicking Wishlist here shows the identical page.
      _MenuItem(
        Icons.favorite_border_rounded,
        'Wishlist',
        'Your most loved styles',
        () => const MainScaffold(currentIndex: 2, body: WishlistScreen()),
      ),
      _MenuItem(Icons.local_offer_outlined, 'Coupons', 'View available offers', () => const CouponsScreen()),
      if (_isLoggedIn)
        _MenuItem(Icons.manage_accounts_outlined, 'Manage Account', 'Update your profile details', () => const ManageAccountScreen()),
      if (_isLoggedIn)
        _MenuItem(Icons.settings_outlined, 'Settings', 'App preferences & more', () => const SettingsScreen()),
    ];

    return Material(
      color: AppColors.card,
      child: Column(
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              _menuTile(items[i]),
              if (i < items.length - 1) Divider(height: 1, indent: 64, endIndent: 16, color: AppColors.background),
            ],
          );
        }),
      ),
    );
  }

  Widget _menuTile(_MenuItem item) {
    return ListTile(
      onTap: () => _handleMenuTap(item),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(item.icon, color: AppColors.textSecondary, size: 26),
      title: Text(item.label, style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(item.subtitle, style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 22),
    );
  }

  // Not logged in -> always go to login, regardless of which item was tapped.
  // Logged in -> go to that item's actual page.
  void _handleMenuTap(_MenuItem item) {
    if (!_isLoggedIn) {
      _goToLogin();
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => item.pageBuilder()));
  }

  void _goToLogin() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  // ---------------- Logout ----------------
  Widget _buildLogoutCard() {
    return Material(
      color: AppColors.card,
      child: ListTile(
        onTap: () => setState(() => _isLoggedIn = false),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: const Icon(Icons.logout_rounded, color: Color(0xFFD94F4F), size: 24),
        title: const Text('Log Out', style: TextStyle(color: Color(0xFFD94F4F), fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ---------------- Secondary links (FAQs, About Us, etc.) ----------------
  Widget _buildSecondaryLinksSection() {
    return Material(
      color: AppColors.card,
      child: Column(
        children: List.generate(_secondaryLinks.length, (i) {
          return Column(
            children: [
              ListTile(
                onTap: () {
                  // TODO: navigate to ${_secondaryLinks[i]}
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                title: Text(
                  _secondaryLinks[i].toUpperCase(),
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.6),
                ),
              ),
              if (i < _secondaryLinks.length - 1) Divider(height: 1, indent: 16, color: AppColors.background),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildAppVersionFooter() {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text('APP VERSION 1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 0.8)),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget Function() pageBuilder;
  _MenuItem(this.icon, this.label, this.subtitle, this.pageBuilder);
}