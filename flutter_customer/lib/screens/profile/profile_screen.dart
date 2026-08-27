import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
 
import '../../services/auth_service.dart';
import '../../models/profile_section.dart';
 
/// Change this manually on each release, or wire up package_info_plus
/// if you want it to read from pubspec.yaml automatically.
const String kAppVersion = '1.0.0';
 
// ---------------------------------------------------------------------------
// Palette — light, classic. Single accent color for interactive/positive
// touches; kept local so it doesn't collide with the app-wide AppColors.
// ---------------------------------------------------------------------------
class _Palette {
  static const Color ink = Color(0xFF1A1A1D);
  static const Color surface = Colors.white;
  static const Color canvas = Color(0xFFF6F6F7);
  static const Color muted = Color(0xFF8A8A8E);
  static const Color line = Color(0xFFE7E7E9);
  static const Color accent = Color(0xFF17B978); // emerald
  static const Color accentSoft = Color(0xFFE4F7EE);
  static const Color danger = Color(0xFFE5484D);
}
 
/// A shopping profile under the main account — the main account itself is
/// always index 0 and marked as Admin.
class _SubAccount {
  final String name;
  final bool isAdmin;
  const _SubAccount({required this.name, this.isAdmin = false});
}
 
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
 
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
 
class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String _userName = 'User';
 
  // TODO: replace with real sub-accounts from your backend once that API
  // exists. For now the main account (Admin) is seeded from _userName and
  // additions are local-only (not persisted).
  final List<_SubAccount> _subAccounts = [];
  int _selectedAccountIndex = 0;
 
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
    await AuthService.loadTokens();
 
    final prefs = await SharedPreferences.getInstance();
 
    // ApiService only ever writes the 'user_name' key (see setToken()),
    // so that's the single source of truth here.
    final storedName = prefs.getString('user_name');
    final resolvedName = (storedName != null && storedName.isNotEmpty)
        ? storedName
        : 'User';
 
    final token = AuthService.token;
    final loggedIn = token != null && token.isNotEmpty;
 
    if (!mounted) return;
    setState(() {
      _userName = resolvedName;
      _isLoggedIn = loggedIn;
      _isLoading = false;
      // Seed the sub-accounts row with the main (Admin) account. Keep any
      // additional local sub-accounts the user already added this session.
      if (_subAccounts.isEmpty) {
        _subAccounts.add(_SubAccount(name: resolvedName, isAdmin: true));
      } else {
        _subAccounts[0] = _SubAccount(name: resolvedName, isAdmin: true);
      }
    });
  }
 
  Future<void> _addSubAccount() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add shopping profile'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Name (e.g. Surya)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            style: TextButton.styleFrom(foregroundColor: _Palette.muted),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => context.pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.ink,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
 
    if (name != null && name.isNotEmpty && mounted) {
      setState(() {
        _subAccounts.add(_SubAccount(name: name));
        _selectedAccountIndex = _subAccounts.length - 1;
      });
    }
  }
 
  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
 
    // AuthService.logout() clears the local token FIRST (before the
    // network call), so the app is "logged out" instantly regardless of
    // network state. clearToken() is idempotent, so calling it again here
    // is a harmless safety net.
    await AuthService.logout();
    await AuthService.clearTokens();
 
    if (!mounted) return;
 
    setState(() {
      _isLoggedIn = false;
      _userName = 'User';
      _isLoading = false;
    });
  }
 
  // Uses go_router (context.push) instead of the raw Navigator, so this
  // stays consistent with the rest of the app (e.g. CustomerHeader),
  // correctly registers with go_router's history/back-stack, updates the
  // URL on web, and supports a redirect-back-here query param.
  Future<void> _goToLogin() async {
    await context.push('/login?redirect=/profile');
    if (mounted) _loadProfileData();
  }
 
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            style: TextButton.styleFrom(foregroundColor: _Palette.muted),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: _Palette.danger),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _handleLogout();
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.canvas,
      // Standard, clearly-separate AppBar — its own distinct header strip
      // instead of the back button floating over a colored hero section.
      appBar: AppBar(
        backgroundColor: _Palette.surface,
        surfaceTintColor: _Palette.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _Palette.ink),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // No history to pop (e.g. opened via direct link/refresh) —
              // fall back to a known safe destination.
              context.go('/profile');
            }
          },
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: _Palette.ink,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _Palette.accent),
            )
          : SafeArea(
              child: RefreshIndicator(
                color: _Palette.accent,
                onRefresh: _loadProfileData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: _isLoggedIn
                      ? _buildLoggedInView()
                      : _buildLoggedOutView(),
                ),
              ),
            ),
    );
  }
 
  // ---------------------------------------------------------------------
  // AVATAR / IDENTITY CARD — light card, no black background, sits under
  // the AppBar as its own clearly separate block.
  // ---------------------------------------------------------------------
  Widget _buildLoggedOutIdentityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Palette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _Palette.accentSoft,
              border: Border.all(color: _Palette.accent, width: 1.6),
            ),
            child: const Icon(
              Icons.person_outline,
              color: _Palette.accent,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'You\'re not logged in',
            style: TextStyle(
              color: _Palette.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Login to track orders, save your wishlist\n& unlock member offers',
            style: TextStyle(color: _Palette.muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.ink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.arrow_forward, size: 17),
              label: const Text(
                'Login / Signup',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  /// Compact, stylized greeting — replaces the boxed identity card for the
  /// logged-in view. Small avatar + "Welcome back" eyebrow + name with a
  /// gradient accent underline, instead of a full profile card.
  Widget _buildWelcomeHeader() {
    return Text(
      'Welcome ${_userName}',
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: _Palette.ink,
      ),
    );
  }
 
  // ---------------------------------------------------------------------
  // SUB-ACCOUNTS — "Shopping for X" row with switchable profile avatars
  // and an Add button, e.g. for a shared family/household account.
  // ---------------------------------------------------------------------
  Widget _buildSubAccountsSection() {
    if (_subAccounts.isEmpty) return const SizedBox.shrink();
 
    final activeName = _subAccounts[_selectedAccountIndex].name;
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shopping for $activeName',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _Palette.ink,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _subAccounts.length + 1, // +1 for the Add tile
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              if (index == _subAccounts.length) {
                return _addAccountTile();
              }
              final account = _subAccounts[index];
              final isSelected = index == _selectedAccountIndex;
              return _subAccountTile(
                account: account,
                isSelected: isSelected,
                onTap: () => setState(() => _selectedAccountIndex = index),
              );
            },
          ),
        ),
      ],
    );
  }
 
  Widget _subAccountTile({
    required _SubAccount account,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final initial = account.name.trim().isNotEmpty
        ? account.name.trim()[0].toUpperCase()
        : '?';
 
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Palette.accentSoft,
                    border: Border.all(
                      color: isSelected ? _Palette.accent : _Palette.line,
                      width: isSelected ? 2.4 : 1.4,
                    ),
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _Palette.accent,
                    ),
                  ),
                ),
                if (account.isAdmin)
                  Positioned(
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _Palette.ink,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _Palette.surface, width: 1.5),
                      ),
                      child: const Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              account.name.trim().split(RegExp(r'\s+')).first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _Palette.ink : _Palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  Widget _addAccountTile() {
    return GestureDetector(
      onTap: _addSubAccount,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _Palette.canvas,
                border: Border.all(
                  color: _Palette.muted.withOpacity(0.4),
                  width: 1.4,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Icon(Icons.add, color: _Palette.muted, size: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _Palette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  // ---------------------------------------------------------------------
  // LOGGED OUT VIEW
  // ---------------------------------------------------------------------
  Widget _buildLoggedOutView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLoggedOutIdentityCard(),
        const SizedBox(height: 28),
        _sectionLabel('EXPLORE'),
        const SizedBox(height: 12),
        _menuGrid([
          _MenuEntry(Icons.favorite_border, 'Wishlist', _goToLogin),
          _MenuEntry(Icons.help_outline, 'Help Center', () {}),
          _MenuEntry(Icons.notifications_none, 'Notifications', () {}),
        ]),
        const SizedBox(height: 28),
        _sectionLabel('MORE'),
        const SizedBox(height: 12),
        _infoCard(
          Icons.quiz_outlined,
          'FAQs',
          () => _goToSection(ProfileSection.faqs),
        ),
 
        const SizedBox(height: 10),
 
        _infoCard(
          Icons.info_outline,
          'About Us',
          () => _goToSection(ProfileSection.aboutUs),
        ),
 
        const SizedBox(height: 10),
 
        _infoCard(
          Icons.description_outlined,
          'Terms, License & Policies',
          () => _goToSection(ProfileSection.termsPolicies),
        ),
        const SizedBox(height: 28),
        _buildAppVersion(),
      ],
    );
  }
 
  Future<void> _goToSection(ProfileSection section) async {
    await context.push('/profile/details?section=${section.slug}');
  }
 
  // ---------------------------------------------------------------------
  // LOGGED IN VIEW
  // ---------------------------------------------------------------------
  Widget _buildLoggedInView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildWelcomeHeader(),
        const SizedBox(height: 24),
        _buildSubAccountsSection(),
        const SizedBox(height: 28),
        _sectionLabel('ACCOUNT'),
        const SizedBox(height: 12),
        _menuGrid([
          _MenuEntry(
            Icons.dashboard_outlined,
            'Overview',
            () => _goToSection(ProfileSection.overview),
          ),
          _MenuEntry(
            Icons.receipt_long_outlined,
            'Orders',
            () => _goToSection(ProfileSection.orders),
          ),
          _MenuEntry(
            Icons.favorite_border,
            'Wishlist',
            () => context.push('/wishlist'),
          ),
          _MenuEntry(
            Icons.local_offer_outlined,
            'Coupons',
            () => _goToSection(ProfileSection.coupons),
          ),
          _MenuEntry(
            Icons.credit_card,
            'Saved Cards',
            () => _goToSection(ProfileSection.savedCards),
          ),
          _MenuEntry(
            Icons.location_on_outlined,
            'Addresses',
            () => _goToSection(ProfileSection.savedAddress),
          ),
          _MenuEntry(
            Icons.notifications_none,
            'Notifications',
            () => _goToSection(ProfileSection.notificationSettings),
          ),
          _MenuEntry(
            Icons.help_outline,
            'Help Center',
            () => _goToSection(ProfileSection.helpCenter),
          ),
        ]),
        const SizedBox(height: 28),
 
        // FAQs / About Us / Terms — individual cards, one below another,
        // instead of a shared list or a grid tile.
        _sectionLabel('MORE'),
        const SizedBox(height: 12),
        _infoCard(
          Icons.quiz_outlined,
          'FAQs',
          () => _goToSection(ProfileSection.faqs),
        ),
        const SizedBox(height: 10),
        _infoCard(
          Icons.info_outline,
          'About Us',
          () => _goToSection(ProfileSection.aboutUs),
        ),
        const SizedBox(height: 10),
        _infoCard(
          Icons.description_outlined,
          'Terms, License & Policies',
          () => _goToSection(ProfileSection.termsPolicies),
        ),
        const SizedBox(height: 28),
 
        // Minimal, understated logout — text + icon rather than a big
        // block button, sitting quietly at the bottom.
        Center(
          child: TextButton.icon(
            onPressed: _isLoading ? null : _confirmLogout,
            style: TextButton.styleFrom(foregroundColor: _Palette.danger),
            icon: const Icon(Icons.logout, size: 17),
            label: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildAppVersion(),
      ],
    );
  }
 
  // ---------------------------------------------------------------------
  // SHARED PIECES
  // ---------------------------------------------------------------------
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _Palette.muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
 
  /// One standalone card per row — used for FAQs / About Us / Terms so
  /// each sits as its own distinct block instead of being grouped.
  Widget _infoCard(IconData icon, String title, VoidCallback onTap) {
    return Material(
      color: _Palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _Palette.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _Palette.canvas,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: _Palette.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _Palette.ink,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 13,
                color: _Palette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  /// Grid of square-ish tiles (icon on top, label below) for the account
  /// shortcuts — kept for quick-access items only.
  Widget _menuGrid(List<_MenuEntry> entries) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Material(
          color: _Palette.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: entry.onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _Palette.line),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: _Palette.canvas,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(entry.icon, size: 18, color: _Palette.ink),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _Palette.ink,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
 
  Widget _buildAppVersion() {
    return Center(
      child: Text(
        'App Version $kAppVersion',
        style: const TextStyle(fontSize: 12, color: _Palette.muted),
      ),
    );
  }
}
 
class _MenuEntry {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuEntry(this.icon, this.label, this.onTap);
}