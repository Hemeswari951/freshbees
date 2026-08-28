import 'package:flutter/material.dart';
import '../../widgets/app_colors.dart';
import '../../services/profile_service.dart';
import '../../utils/shop_colors.dart';

// Shop / owner info edits are saved through ProfileService.updateProfile(...)
// (see services/profile_service.dart). Bank details, email and phone are
// intentionally not editable here — see _blockBankEdit() / _blockContactEdit().

class ShopDetailsScreen extends StatefulWidget {
  final ShopProfile profile;
  const ShopDetailsScreen({super.key, required this.profile});

  @override
  State<ShopDetailsScreen> createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Local editable copy so the UI updates instantly after a save,
  // without waiting for the parent screen to refetch the profile.
  late ShopProfile _profile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Edit: Shop Information ────────────────────────────────────────
  Future<void> _editShopInfo() async {
    final shopNameCtrl = TextEditingController(text: _profile.shopName);
    final descCtrl = TextEditingController(text: _profile.description ?? '');
    final addressCtrl = TextEditingController(text: _profile.address ?? '');
    final cityCtrl = TextEditingController(text: _profile.city ?? '');
    final stateCtrl = TextEditingController(text: _profile.state ?? '');
    final pincodeCtrl = TextEditingController(text: _profile.pincode ?? '');

    final saved = await _showEditSheet(
      title: 'Edit shop information',
      fields: [
        _EditField('Shop name', shopNameCtrl),
        _EditField('Description', descCtrl, maxLines: 3),
        _EditField('Address', addressCtrl, maxLines: 2),
        _EditField('City', cityCtrl),
        _EditField('State', stateCtrl),
        _EditField('Pincode', pincodeCtrl, keyboardType: TextInputType.number),
      ],
    );
    if (saved != true) return;

    setState(() => _saving = true);
    try {
      final updated = await ProfileService.updateProfile(
        shopName: shopNameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        city: cityCtrl.text.trim(),
        state: stateCtrl.text.trim(),
        pincode: pincodeCtrl.text.trim(),
      );
      setState(() => _profile = updated);
      if (mounted) _showSnack('Shop information updated');
    } catch (e) {
      if (mounted) _showSnack('Could not save changes. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Edit: Owner Information ───────────────────────────────────────
  // Only the owner name is editable here now. Email and phone are
  // admin-managed — see _blockContactEdit().
  Future<void> _editOwnerInfo() async {
    final ownerNameCtrl = TextEditingController(text: _profile.ownerName);

    final saved = await _showEditSheet(
      title: 'Edit owner name',
      fields: [_EditField('Owner name', ownerNameCtrl)],
    );
    if (saved != true) return;

    setState(() => _saving = true);
    try {
      final updated = await ProfileService.updateProfile(
        ownerName: ownerNameCtrl.text.trim(),
      );
      setState(() => _profile = updated);
      if (mounted) _showSnack('Owner name updated');
    } catch (e) {
      if (mounted) _showSnack('Could not save changes. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Email & phone are admin-managed — editing is blocked, and tapping
  // these rows just points the shop owner to support instead.
  void _blockContactEdit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact Admin'),
        content: const Text(
          'Email and phone number are managed by the admin team. '
          'Please contact support if you need to update them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Bank details are admin-managed — editing is blocked, and tapping
  // the edit icon here just points the shop owner to support instead.
  void _blockBankEdit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Contact Admin'),
        content: const Text(
          'Bank and account details are managed by the admin team. '
          'Please contact support if you need to update them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // Generic bottom sheet used by both edit flows above.
  Future<bool?> _showEditSheet({
    required String title,
    required List<_EditField> fields,
  }) {
    final formKey = GlobalKey<FormState>();
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 14),
                for (final f in fields) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: f.controller,
                      maxLines: f.maxLines,
                      keyboardType: f.keyboardType,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? '${f.label} is required'
                          : null,
                      decoration: InputDecoration(
                        labelText: f.label,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0E5B45),
                        ),
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            Navigator.of(ctx).pop(true);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Staggered fade + slide-up for each section, index-based delay
  Widget _animated(int index, Widget child) {
    final start = (index * 0.08).clamp(0.0, 0.6);
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        start,
        (start + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          _buildBody(p),
          if (_saving)
            Container(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF0E5B45)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(ShopProfile p) {
    // Same seed as ProfileScreen, so a given shop always shows the same
    // accent color in both places when there's no banner/logo uploaded.
    final shopColor = ShopColors.forSeed(p.shopName);

    return CustomScrollView(
      slivers: [
        // ── Banner header ──────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: shopColor,
          elevation: 0,
          leading: Padding(
            padding: const EdgeInsets.all(10),
            child: _roundIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                p.bannerUrl != null
                    ? Image.network(
                        ProfileService.fullImageUrl(p.bannerUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: shopColor),
                      )
                    : Container(color: shopColor),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 16,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: shopColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: p.logoUrl != null
                            ? Image.network(
                                ProfileService.fullImageUrl(p.logoUrl!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _initial(p),
                              )
                            : _initial(p),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.shopName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              'Owned by ${p.ownerName}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Body ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _animated(
                  0,
                  Row(
                    children: [
                      Expanded(
                        child: _statChip(
                          icon: Icons.inventory_2_outlined,
                          value: p.productsCount.toString(),
                          label: 'Products',
                          color: const Color(0xFF6E56D9),
                          bg: const Color(0xFFE3E1FB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statChip(
                          icon: Icons.shopping_bag_outlined,
                          value: p.ordersCount.toString(),
                          label: 'Orders',
                          color: const Color(0xFF1E8A5F),
                          bg: const Color(0xFFD9F0E6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statChip(
                          icon: Icons.star_outline_rounded,
                          value: p.reviewCount > 0
                              ? p.avgRating.toStringAsFixed(1)
                              : 'New',
                          label: 'Rating',
                          color: const Color(0xFF2E9E6B),
                          bg: const Color(0xFFE7F3D6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                _animated(
                  1,
                  _sectionHeading('SHOP INFORMATION', onEdit: _editShopInfo),
                ),
                const SizedBox(height: 8),
                _animated(
                  1,
                  _infoList(
                    [
                      _InfoItem(
                        Icons.storefront_rounded,
                        'Shop name',
                        p.shopName,
                      ),
                      _InfoItem(
                        Icons.description_outlined,
                        'Description',
                        p.description?.isNotEmpty == true
                            ? p.description!
                            : '-',
                      ),
                      if ((p.address ?? '').isNotEmpty)
                        _InfoItem(Icons.home_outlined, 'Address', p.address!),
                      _InfoItem(Icons.place_outlined, 'Location', p.location),
                      _InfoItem(
                        Icons.pin_drop_outlined,
                        'Pincode',
                        p.pincode ?? '-',
                      ),
                      _InfoItem(
                        Icons.category_outlined,
                        'Categories',
                        p.categories.isNotEmpty ? p.categories.join(', ') : '-',
                      ),
                      if (p.createdAt != null)
                        _InfoItem(
                          Icons.calendar_today_outlined,
                          'Member since',
                          _formatDate(p.createdAt!),
                        ),
                    ],
                    accent: const Color(0xFF6E56D9),
                    accentBg: const Color(0xFFE3E1FB),
                  ),
                ),
                const SizedBox(height: 18),

                _animated(
                  2,
                  _sectionHeading('OWNER INFORMATION', onEdit: _editOwnerInfo),
                ),
                const SizedBox(height: 8),
                // Built as individual rows (not _infoList) so email and
                // phone can be marked locked / non-editable, unlike
                // owner name which stays freely editable via the sheet.
                _animated(
                  2,
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          _InfoItem(
                            Icons.person_outline_rounded,
                            'Owner name',
                            p.ownerName,
                          ),
                          accent: const Color(0xFF1E8A5F),
                          accentBg: const Color(0xFFD9F0E6),
                        ),
                        Divider(
                          height: 1,
                          color: AppColors.line.withValues(alpha: 0.6),
                        ),
                        _infoRow(
                          _InfoItem(
                            Icons.mail_outline_rounded,
                            'Email',
                            p.email ?? '-',
                          ),
                          accent: const Color(0xFF1E8A5F),
                          accentBg: const Color(0xFFD9F0E6),
                          locked: true,
                          onTap: _blockContactEdit,
                        ),
                        Divider(
                          height: 1,
                          color: AppColors.line.withValues(alpha: 0.6),
                        ),
                        _infoRow(
                          _InfoItem(
                            Icons.call_outlined,
                            'Phone',
                            p.phoneNumber ?? '-',
                          ),
                          accent: const Color(0xFF1E8A5F),
                          accentBg: const Color(0xFFD9F0E6),
                          locked: true,
                          onTap: _blockContactEdit,
                        ),
                        if (p.ownerLastLogin != null) ...[
                          Divider(
                            height: 1,
                            color: AppColors.line.withValues(alpha: 0.6),
                          ),
                          _infoRow(
                            _InfoItem(
                              Icons.login_rounded,
                              'Last login',
                              _formatDate(p.ownerLastLogin!),
                            ),
                            accent: const Color(0xFF1E8A5F),
                            accentBg: const Color(0xFFD9F0E6),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                _animated(
                  3,
                  _sectionHeading(
                    'BANK / ACCOUNT DETAILS',
                    onEdit: _blockBankEdit,
                    locked: true,
                  ),
                ),
                const SizedBox(height: 8),
                _animated(3, _bankCard(p.bankDetails)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bankCard(BankDetails? bank) {
    if (bank == null) {
      return _card(
        child: const Text(
          'No bank details found',
          style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
        ),
      );
    }

    return Column(
      children: [
        _infoList(
          [
            _InfoItem(
              Icons.credit_card_outlined,
              'Account number',
              _maskAccount(bank.accountNumber),
            ),
            _InfoItem(
              Icons.badge_outlined,
              'Account holder',
              bank.accountHolderName ?? '-',
            ),
            _InfoItem(
              Icons.account_balance_outlined,
              'Bank name',
              bank.bankName ?? '-',
            ),
            _InfoItem(Icons.tag_outlined, 'IFSC code', bank.ifscCode ?? '-'),
          ],
          accent: const Color(0xFFB9791F),
          accentBg: const Color(0xFFFBE7CF),
        ),
        const SizedBox(height: 8),

        if ((bank.gstNumber ?? '').isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFBE7CF),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFB9791F).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 15,
                    color: Color(0xFFB9791F),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GST NUMBER',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFF8A6520),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        bank.gstNumber!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Color(0xFF5C4415),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.blush,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.inkSoft,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Bank details are set by admin. Contact support to update.',
                  style: TextStyle(fontSize: 10.5, color: AppColors.inkSoft),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _initial(ShopProfile p) => Center(
    child: Text(
      p.initial,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }

  Widget _sectionHeading(
    String text, {
    VoidCallback? onEdit,
    bool locked = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, right: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          if (onEdit != null)
            GestureDetector(
              onTap: onEdit,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      locked ? Icons.lock_outline_rounded : Icons.edit_outlined,
                      size: 13.5,
                      color: locked
                          ? AppColors.inkSoft
                          : const Color(0xFF0E5B45),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      locked ? 'Locked' : 'Edit',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: locked
                            ? AppColors.inkSoft
                            : const Color(0xFF0E5B45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Shared compact card wrapper — subtle shadow, tighter radius
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoList(List<_InfoItem> items, {Color? accent, Color? accentBg}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _infoRow(
              items[i],
              accent: accent ?? const Color(0xFF1E8A5F),
              accentBg: accentBg ?? const Color(0xFFD9F0E6),
            ),
            if (i != items.length - 1)
              Divider(height: 1, color: AppColors.line.withValues(alpha: 0.6)),
          ],
        ],
      ),
    );
  }

  // Same layout for every single field, no exceptions: icon + label on
  // top, value left-aligned underneath. Short values, long addresses,
  // emails, comma-lists — all wrap and align exactly the same way, so
  // nothing looks "off" depending on how long the text happens to be.
  //
  // If `locked` is true, a small lock icon shows next to the label and
  // tapping the row (via `onTap`) can surface a "contact admin" message
  // instead of allowing an edit — used for email/phone/bank fields.
  Widget _infoRow(
    _InfoItem item, {
    required Color accent,
    required Color accentBg,
    bool locked = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 13.5, color: accent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
                if (locked)
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: AppColors.inkSoft,
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                item.value,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }

  String _maskAccount(String? account) {
    if (account == null || account.isEmpty) return '-';
    if (account.length <= 4) return account;
    return '•••• •••• ${account.substring(account.length - 4)}';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}

class _EditField {
  final String label;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  const _EditField(
    this.label,
    this.controller, {
    this.maxLines = 1,
    this.keyboardType,
  });
}
