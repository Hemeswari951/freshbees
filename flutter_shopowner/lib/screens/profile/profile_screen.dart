import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/app_colors.dart';
import '../../services/profile_service.dart';
import '../../utils/shop_colors.dart';
import 'shop_details_screen.dart';
import 'reviews_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ShopProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await ProfileService.getProfile();
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openEditSheet() async {
    if (_profile == null) return;
    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditShopSheet(profile: _profile!),
    );
    if (updated == true) _load();
  }

  // ── UI-only for now. Real token-clear / navigation logic will be
  // wired in later once the auth flow is finalized. ──
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // TODO: add real logout logic later (clear token / prefs +
    // navigate to login screen).
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged out')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _errorState()
              : _content(),
        ),
      ),
    );
  }

  Widget _errorState() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 100),
        const Icon(Icons.error_outline, size: 34, color: AppColors.inkSoft),
        const SizedBox(height: 10),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5),
        ),
        const SizedBox(height: 14),
        Center(
          child: TextButton(onPressed: _load, child: const Text('Try again')),
        ),
      ],
    );
  }

  Widget _content() {
    final p = _profile!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _headerCard(p),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeading('MY SHOP'),
              _menuCard([
                _MenuRowData(
                  icon: Icons.storefront_rounded,
                  iconBg: const Color(0xFFD9F0E6),
                  iconColor: const Color(0xFF1E8A5F),
                  label: 'Shop info',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ShopDetailsScreen(profile: p),
                    ),
                  ),
                ),
                _MenuRowData(
                  icon: Icons.category_rounded,
                  iconBg: const Color(0xFFE3D9F5),
                  iconColor: const Color(0xFF7A4FD1),
                  label: 'Inventory',
                  // TODO: replace with real navigation once we confirm
                  // where products_screen.dart lives in your project.
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inventory screen coming soon')),
                    );
                  },
                ),
                _MenuRowData(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: const Color(0xFFFBE7CF),
                  iconColor: const Color(0xFFB9791F),
                  label: 'Earnings',
                  onTap: () {
                    // TODO: navigate to Earnings screen
                  },
                ),
              ]),
              const SizedBox(height: 20),

              _sectionHeading('ANALYTICS'),
              _menuCard([
                _MenuRowData(
                  icon: Icons.bar_chart_rounded,
                  iconBg: const Color(0xFFE3E1FB),
                  iconColor: const Color(0xFF5B54D6),
                  label: 'Reports',
                  onTap: () {
                    // TODO: navigate to Reports screen
                  },
                ),
                _MenuRowData(
                  icon: Icons.download_rounded,
                  iconBg: const Color(0xFFE3E1FB),
                  iconColor: const Color(0xFF5B54D6),
                  label: 'Download reports',
                  onTap: () {
                    // TODO: trigger report download
                  },
                ),
              ]),
              const SizedBox(height: 20),

              _sectionHeading('CUSTOMERS'),
              _menuCard([
                _MenuRowData(
                  icon: Icons.star_rounded,
                  iconBg: const Color(0xFFE7F3D6),
                  iconColor: const Color(0xFF6E9A2E),
                  label: 'Reviews and ratings',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReviewsScreen()),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              _sectionHeading('APP'),
              _menuCard([
                _MenuRowData(
                  icon: Icons.settings_rounded,
                  iconBg: const Color(0xFFF1EAD9),
                  iconColor: const Color(0xFF8A7B4E),
                  label: 'Settings',
                  onTap: () {
                    // TODO: navigate to Settings screen
                  },
                ),
                _MenuRowData(
                  icon: Icons.help_outline_rounded,
                  iconBg: const Color(0xFFDCEBFA),
                  iconColor: const Color(0xFF2E7FC1),
                  label: 'Help centre',
                  onTap: () {
                    // TODO: navigate to Help centre screen
                  },
                ),
              ]),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmLogout,
                  icon: const Icon(
                    Icons.logout_rounded,
                    size: 17,
                    color: AppColors.red,
                  ),
                  label: const Text(
                    'Log out',
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.redSoft,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCard(ShopProfile p) {
    // Same seed used here and in ShopDetailsScreen so a given shop always
    // shows the same accent color in both places.
    final shopColor = ShopColors.forSeed(p.shopName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(color: shopColor),
          child: p.bannerUrl != null
              ? Image.network(
                  ProfileService.fullImageUrl(p.bannerUrl!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              : null,
        ),
        Transform.translate(
          offset: const Offset(0, -40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _avatar(p, shopColor),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.shopName,
                            style: const TextStyle(
                              fontFamily: 'Fraunces',
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Owned by ${p.ownerName}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _editButton(),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        icon: Icons.inventory_2_outlined,
                        iconColor: const Color(0xFF6E56D9),
                        value: p.productsCount.toString(),
                        label: 'Products',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        icon: Icons.shopping_bag_outlined,
                        iconColor: const Color(0xFF1E8A5F),
                        value: p.ordersCount.toString(),
                        label: 'Orders',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _statCard(
                        icon: Icons.star_outline_rounded,
                        iconColor: const Color(0xFF2E9E6B),
                        value: p.reviewCount > 0
                            ? p.avgRating.toStringAsFixed(1)
                            : 'New',
                        label: 'Rating',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatar(ShopProfile p, Color shopColor) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: shopColor,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cream, width: 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: p.logoUrl != null
          ? Image.network(
              ProfileService.fullImageUrl(p.logoUrl!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarInitial(p),
            )
          : _avatarInitial(p),
    );
  }

  Widget _avatarInitial(ShopProfile p) {
    return Center(
      child: Text(
        p.initial,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _editButton() {
    return GestureDetector(
      onTap: _openEditSheet,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line),
        ),
        child: const Icon(
          Icons.edit_outlined,
          size: 16,
          color: AppColors.terracotta,
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.inkSoft,
      ),
    ),
  );

  Widget _menuCard(List<_MenuRowData> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            _menuRow(rows[i]),
            if (i != rows.length - 1)
              const Divider(height: 1, color: AppColors.line),
          ],
        ],
      ),
    );
  }

  Widget _menuRow(_MenuRowData data) {
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: data.iconBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(data.icon, size: 17, color: data.iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                data.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.inkSoft,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRowData {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  _MenuRowData({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });
}

class _EditShopSheet extends StatefulWidget {
  final ShopProfile profile;
  const _EditShopSheet({required this.profile});

  @override
  State<_EditShopSheet> createState() => _EditShopSheetState();
}

class _EditShopSheetState extends State<_EditShopSheet> {
  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  XFile? _newLogo;
  XFile? _newBanner;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController(text: widget.profile.shopName);
    _ownerNameCtrl = TextEditingController(text: widget.profile.ownerName);
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _newLogo = picked);
  }

  Future<void> _pickBanner() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _newBanner = picked);
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ProfileService.updateProfile(
        shopName: _shopNameCtrl.text.trim().isNotEmpty
            ? _shopNameCtrl.text.trim()
            : null,
        ownerName: _ownerNameCtrl.text.trim().isNotEmpty
            ? _ownerNameCtrl.text.trim()
            : null,
        logo: _newLogo,
        banner: _newBanner,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Edit shop info',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 18),

            _imagePickerRow(
              label: 'Banner image',
              existingUrl: widget.profile.bannerUrl,
              newFile: _newBanner,
              onTap: _pickBanner,
              height: 90,
            ),
            const SizedBox(height: 14),
            _imagePickerRow(
              label: 'Logo',
              existingUrl: widget.profile.logoUrl,
              newFile: _newLogo,
              onTap: _pickLogo,
              height: 70,
              circular: true,
            ),
            const SizedBox(height: 16),

            _field(_shopNameCtrl, 'Shop name'),
            const SizedBox(height: 12),
            _field(_ownerNameCtrl, 'Owner name'),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.red, fontSize: 12.5),
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_saving ? 'Saving...' : 'Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.blush,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.terracotta),
        ),
      ),
    );
  }

  // Image picker preview with a small floating edit badge in the
  // bottom-right corner, so it's visually obvious the image is tappable
  // — instead of relying on the whole box just silently being a button.
  Widget _imagePickerRow({
    required String label,
    required String? existingUrl,
    required XFile? newFile,
    required VoidCallback onTap,
    required double height,
    bool circular = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: SizedBox(
            height: height,
            width: circular ? height : double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(circular ? height : 12),
                  child: Container(
                    height: height,
                    width: circular ? height : double.infinity,
                    color: AppColors.blush,
                    child: newFile != null
                        ? FutureBuilder<Uint8List>(
                            future: newFile.readAsBytes(),
                            builder: (context, snap) {
                              if (!snap.hasData) return const SizedBox.shrink();
                              return Image.memory(snap.data!, fit: BoxFit.cover);
                            },
                          )
                        : existingUrl != null
                        ? Image.network(
                            ProfileService.fullImageUrl(existingUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.inkSoft,
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.add_a_photo_outlined,
                              color: AppColors.inkSoft,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: circular ? 0 : 8,
                  bottom: circular ? 0 : 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 13,
                      color: AppColors.terracotta,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}