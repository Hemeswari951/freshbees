import 'package:flutter/material.dart';
import '../../widgets/t_colors.dart';
import '../../services/api_service.dart';
import '../../services/shop_service.dart';
import '../products/product_view_screen.dart';

import '../../screens/shops/dialogs/edit_shop_info_dialog.dart';
import '../../screens/shops/dialogs/edit_owner_dialog.dart';
import '../../screens/shops/dialogs/edit_bank_dialog.dart';
import '../../screens/shops/dialogs/edit_settings_dialog.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry — accepts shopId instead of a map
// ─────────────────────────────────────────────────────────────────────────────
class ShopDetailScreen extends StatelessWidget {
  final int shopId;
  const ShopDetailScreen({super.key, required this.shopId});

  @override
  Widget build(BuildContext context) => _ShopDetailBody(shopId: shopId);
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────
class _ShopDetailBody extends StatefulWidget {
  final int shopId;
  const _ShopDetailBody({required this.shopId});

  @override
  State<_ShopDetailBody> createState() => _ShopDetailBodyState();
}

class _ShopDetailBodyState extends State<_ShopDetailBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── API state ──────────────────────────────────────────────────────────────
  Map<String, dynamic>? _shop;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _payouts = [];

  bool _isLoading = true;
  String? _error;
  bool _isBlocking = false; // loading state for block/unblock button

  // ── Products tab local state ───────────────────────────────────────────────
  String _productSearch = '';
  String _genderFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadShop();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Load shop (single call — products/orders/payouts come bundled in) ───────
  Future<void> _loadShop() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final shop = await ShopService.getShopDetail(widget.shopId);

      setState(() {
        _shop = shop;
        _products = List<Map<String, dynamic>>.from(shop['products'] ?? []);
        _orders = List<Map<String, dynamic>>.from(shop['orders'] ?? []);
        _payouts = List<Map<String, dynamic>>.from(shop['payouts'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Block / Unblock ────────────────────────────────────────────────────────
  void _showBlockDialog() {
    final isBlocked = (_shop!['isBlocked'] as bool?) ?? false;
    final action = isBlocked ? 'Unblock' : 'Block';
    final desc = isBlocked
        ? 'This will make the shop visible to customers again.'
        : 'This will hide the shop from customers and disable new orders.';

    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? errorText; // lives across rebuilds of this dialog

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: TColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                '$action shop?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: TColors.black,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TColors.brownLight,
                    ),
                  ),
                  if (!isBlocked) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      onChanged: (_) {
                        if (errorText != null) {
                          setDialogState(() => errorText = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Reason for blocking...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        errorText: errorText,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: TColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: TColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: TColors.black,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: TColors.brownLight),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final reason = reasonController.text.trim();

                    // Reason mandatory only when blocking
                    if (!isBlocked && reason.isEmpty) {
                      setDialogState(() {
                        errorText = 'Please enter a reason';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext);
                    await _toggleBlock(reason: isBlocked ? null : reason);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: isBlocked
                          ? const Color(0xFF1D9E75)
                          : const Color(0xFFA32D2D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: TColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleBlock({String? reason}) async {
    final isBlocked = (_shop!['isBlocked'] as bool?) ?? false;
    setState(() => _isBlocking = true);
    try {
      await ShopService.updateShopStatus(
        widget.shopId,
        !isBlocked ? 'blocked' : 'active',
        reason: reason,
      );
      await _loadShop(); // refresh to get updated status
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: const Color(0xFFA32D2D),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBlocking = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Root build
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Loading
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: TColors.cream,
        body: Center(child: CircularProgressIndicator(color: TColors.black)),
      );
    }

    // Error
    if (_error != null) {
      return Scaffold(
        backgroundColor: TColors.cream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_outlined,
                size: 40,
                color: TColors.brownLight,
              ),
              const SizedBox(height: 12),
              const Text(
                'Failed to load shop',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TColors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(fontSize: 11, color: TColors.brownLight),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _loadShop,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: TColors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: TColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final shop = _shop!;
    final isBlocked = (shop['isBlocked'] as bool?) ?? false;
    final shopId = (shop['shopId'] as num?)?.toInt() ?? widget.shopId;
    final bannerColor = _bannerColor(shopId);
    final avatarColor = _avatarColor(shopId);
    final categories = (shop['categories'] as List?) ?? [];
    final shopName = (shop['shopName'] as String?) ?? 'Unnamed shop';

    return Scaffold(
      backgroundColor: TColors.cream,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          // ── Banner ───────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            collapsedHeight: 56,
            pinned: true,
            backgroundColor: bannerColor,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: shop['shopBanner'] != null
                  ? Image.network(
                      '${ApiService.serverUrl}${shop['shopBanner']}',
                      fit: BoxFit.cover,
                      color: isBlocked
                          ? Colors.white.withValues(alpha: 0.5)
                          : null,
                      colorBlendMode: isBlocked ? BlendMode.lighten : null,
                    )
                  : Container(
                      color: isBlocked
                          ? bannerColor.withValues(alpha: 0.55)
                          : bannerColor,
                    ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(10),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: TColors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TColors.border),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 18,
                    color: TColors.black,
                  ),
                ),
              ),
            ),
          ),

          // ── Shop identity row ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: TColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: TColors.border, width: 2),
                      image: shop['shopLogo'] != null
                          ? DecorationImage(
                              image: NetworkImage(
                                '${ApiService.serverUrl}${shop['shopLogo']}',
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: shop['shopLogo'] == null
                        ? Center(
                            child: Text(
                              _initials(shopName),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: TColors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),

                  // Name + meta
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: TColors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _statusBadge(isBlocked),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${shop['ownerName'] ?? '-'} · ${shop['location'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: TColors.brownLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.sell_outlined,
                              size: 10,
                              color: TColors.brownLight,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              categories.join(", "),
                              style: const TextStyle(
                                fontSize: 11,
                                color: TColors.brownLight,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.star_rounded,
                              size: 11,
                              color: Color(0xFFBA7517),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              ((shop['avgRating'] as num?) ?? 0)
                                  .toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: TColors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      _isBlocking
                          ? Container(
                              width: 90,
                              height: 36,
                              alignment: Alignment.center,
                              child: const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: TColors.black,
                                ),
                              ),
                            )
                          : _actionBtn(
                              icon: isBlocked
                                  ? Icons.check_circle_outline
                                  : Icons.block_outlined,
                              label: isBlocked ? 'Unblock' : 'Block',
                              bg: isBlocked
                                  ? const Color(0xFFE1F5EE)
                                  : const Color(0xFFFCEBEB),
                              fg: isBlocked
                                  ? const Color(0xFF085041)
                                  : const Color(0xFF791F1F),
                              borderColor: isBlocked
                                  ? const Color(0xFF7DD4B0)
                                  : const Color(0xFFF09595),
                              onTap: _showBlockDialog,
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Stat cards ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: TColors.cream,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _statCard(
                    'Products',
                    (shop['totalProducts'] ?? 0).toString(),
                    Icons.inventory_2_outlined,
                    const Color(0xFFE6F1FB),
                    const Color(0xFF185FA5),
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    'Orders',
                    (shop['totalOrders'] ?? 0).toString(),
                    Icons.receipt_long_outlined,
                    const Color(0xFFE1F5EE),
                    const Color(0xFF085041),
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    'Revenue',
                    _formatRevenue(shop['totalRevenue']),
                    Icons.currency_rupee,
                    const Color(0xFFF5E4C0),
                    const Color(0xFFBA7517),
                  ),
                  const SizedBox(width: 10),
                  _statCard(
                    'Rating',
                    ((shop['avgRating'] as num?) ?? 0).toStringAsFixed(1),
                    Icons.star_outline_rounded,
                    const Color(0xFFF5D8E8),
                    const Color(0xFF993556),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab bar ───────────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: TColors.black,
                unselectedLabelColor: TColors.brownLight,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 13),
                indicatorColor: TColors.black,
                indicatorWeight: 2,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Products'),
                  Tab(text: 'Orders'),
                  Tab(text: 'Payouts'),
                ],
              ),
            ),
          ),
        ],

        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildProductsTab(),
            _buildOrdersTab(),
            _buildPayoutsTab(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 1 — Overview
  // Left  → Shop information
  // Right → Owner information + Bank / account details
  // Below → Settings (full width)
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildOverviewTab() {
    final shop = _shop!;
    final bank = shop['bankDetails'] as Map<String, dynamic>?;
    final settings = shop['settings'] as Map<String, dynamic>?;
    final isBlocked = (shop['isBlocked'] as bool?) ?? false;
    final categories = (shop['categories'] as List?) ?? [];
    final state = (shop['state'] as String?) ?? '';

    final shopCard = _sectionCard(
      title: 'Shop information',
      icon: Icons.storefront_outlined,
      onEdit: () async {
        final updated = await showDialog<bool>(
          context: context,
          builder: (_) =>
              EditShopInfoDialog(shopId: widget.shopId, shop: _shop!),
        );

        if (updated == true) {
          await _loadShop();
        }
      },
      children: [
        _infoRow('Shop name', (shop['shopName'] as String?) ?? '-'),
        _infoRow('Description', (shop['description'] as String?) ?? '-'),
        _infoRow('Location', (shop['location'] as String?) ?? '-'),
        if (state.isNotEmpty) _infoRow('State', state),
        _infoRow('Pincode', (shop['pincode'] as String?) ?? '-'),
        _infoRow('Categories', categories.join(", ")),
        _infoRow('Status', isBlocked ? 'Blocked' : 'Active'),
        _infoRow(
          'Rating',
          '${((shop['avgRating'] as num?) ?? 0).toStringAsFixed(1)} / 5.0',
        ),
        if (shop['createdAt'] != null)
          _infoRow('Member since', _formatDate(shop['createdAt'].toString())),
      ],
    );

    final ownerCard = _sectionCard(
      title: 'Owner information',
      icon: Icons.person_outline,
      onEdit: () async {
        final updated = await showDialog<bool>(
          context: context,
          builder: (_) => EditOwnerDialog(shopId: widget.shopId, shop: _shop!),
        );

        if (updated == true) {
          await _loadShop();
        }
      },
      children: [
        _infoRow('Owner name', (shop['ownerName'] as String?) ?? '-'),
        _infoRow('Email', (shop['ownerEmail'] as String?) ?? '-'),
        _infoRow('Phone', (shop['ownerPhone'] as String?) ?? '-'),
        if (shop['ownerLastLogin'] != null)
          _infoRow(
            'Last login',
            _formatDate(shop['ownerLastLogin'].toString()),
          ),
      ],
    );

    final bankCard = _sectionCard(
      title: 'Account / bank details',
      icon: Icons.account_balance_outlined,
      onEdit: () async {
        final updated = await showDialog<bool>(
          context: context,

          builder: (_) => EditBankDialog(shopId: widget.shopId, shop: _shop!),
        );

        if (updated == true) {
          await _loadShop();
        }
      },
      children: bank != null
          ? [
              _infoRow(
                'Account number',
                _maskAccount((bank['accountNumber'] as String?) ?? ''),
              ),
              _infoRow('Bank name', (bank['bankName'] as String?) ?? '-'),
              _infoRow('IFSC code', (bank['ifscCode'] as String?) ?? '-'),
              if ((bank['gstNumber'] as String? ?? '').isNotEmpty)
                _infoRow('GST number', bank['gstNumber'] as String),
            ]
          : [
              const Text(
                'No bank details found',
                style: TextStyle(fontSize: 12, color: TColors.brownLight),
              ),
            ],
    );

    final settingsCard = _sectionCard(
      title: 'Settings',
      icon: Icons.settings_outlined,
      onEdit: () async {
        final updated = await showDialog<bool>(
          context: context,

          builder: (_) =>
              EditSettingsDialog(shopId: widget.shopId, shop: _shop!),
        );

        if (updated == true) {
          await _loadShop();
        }
      },
      children: settings != null
          ? [
              _infoRow(
                'Commission rate',
                '${settings['commissionRate'] ?? 0}%',
              ),
              _settingToggleRow(
                'Activate shop',
                (settings['activateImmediately'] as bool?) ?? false,
              ),
              _settingToggleRow(
                'Allow product uploads',
                (settings['allowProductUploads'] as bool?) ?? false,
              ),
              _settingToggleRow(
                'Enable payout requests',
                (settings['enablePayoutRequests'] as bool?) ?? false,
              ),
            ]
          : [
              const Text(
                'No settings found',
                style: TextStyle(fontSize: 12, color: TColors.brownLight),
              ),
            ],
    );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 560;

            if (isNarrow) {
              return Column(
                children: [
                  shopCard,
                  const SizedBox(height: 12),
                  ownerCard,
                  const SizedBox(height: 12),
                  bankCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: shopCard),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [ownerCard, const SizedBox(height: 12), bankCard],
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 12),
        settingsCard,
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 2 — Products  (real data)
  // ─────────────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((p) {
      final matchGender =
          _genderFilter == 'All' || p['category'] == _genderFilter;
      final matchSearch =
          _productSearch.isEmpty ||
          (p['productName'] as String? ?? '').toLowerCase().contains(
            _productSearch.toLowerCase(),
          );
      return matchGender && matchSearch;
    }).toList();
  }

  Widget _buildProductsTab() {
    if (_products.isEmpty) {
      return _emptyState(
        icon: Icons.inventory_2_outlined,
        title: 'No products added',
        subtitle: 'Products added by this shop will appear here',
      );
    }

    final products = _filteredProducts;
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: SizedBox(
            height: 40,
            child: TextField(
              onChanged: (val) => setState(() => _productSearch = val),
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                prefixIcon: Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: TColors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: TColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: TColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: TColors.black,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Row(
            children: [
              Text(
                '${products.length} products',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: TColors.black,
                ),
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                children: [
                  'All',
                  'Men',
                  'Women',
                  'Kids',
                  'Beauty',
                ].map(_genderChip).toList(),
              ),
            ],
          ),
        ),

        // Grid
        Expanded(
          child: products.isEmpty
              ? const Center(
                  child: Text(
                    'No products found',
                    style: TextStyle(fontSize: 13, color: TColors.brownLight),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _productCard(products[i]),
                ),
        ),
      ],
    );
  }

  Widget _genderChip(String label) {
    final active = _genderFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _genderFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? TColors.black : TColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? TColors.black : TColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? TColors.white : TColors.brown,
          ),
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> p) {
    final int stock = (p['stock'] as num?)?.toInt() ?? 0;
    final bool outOfStock = stock == 0;
    final bool lowStock = stock > 0 && stock <= 5;
    final double rating = (p['avgRating'] as num?)?.toDouble() ?? 4.3;
    final String reviews = p['reviews']?.toString() ?? '11.6k';
    final double price = (p['price'] as num?)?.toDouble() ?? 0;
    final double mrp = (p['mrp'] as num?)?.toDouble() ?? 0;
    final int discount = mrp > price
        ? (((mrp - price) / mrp) * 100).round()
        : 0;
    final String? imagePath = p['image'] as String?;
    final String imageUrl = imagePath != null
        ? '${ApiService.serverUrl}$imagePath'
        : '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductViewScreen(productId: p['productId']),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: TColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: outOfStock ? const Color(0xFFE05656) : TColors.border,
            width: outOfStock ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base image
                  Container(
                    color: TColors.cream,
                    alignment: Alignment.center,
                    child: imagePath != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.checkroom_outlined,
                              size: 40,
                              color: TColors.brownLight,
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : const Icon(
                            Icons.checkroom_outlined,
                            size: 40,
                            color: TColors.brownLight,
                          ),
                  ),

                  // Rating + reviews pill
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.star, size: 11, color: Colors.teal),
                          const SizedBox(width: 4),
                          Container(
                            width: 1,
                            height: 10,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            reviews,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Low stock tag
                  if (lowStock)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE05656),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Only $stock left',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: TColors.white,
                          ),
                        ),
                      ),
                    ),

                  // Out of stock overlay
                  if (outOfStock)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        color: const Color(0xFFE05656),
                        child: const Text(
                          'OUT OF STOCK',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: TColors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Text details
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    p['productName'] as String? ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TColors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p['subCategory'] as String? ?? 'Uncategorized',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: TColors.brownLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 5,
                    children: [
                      Text(
                        'Rs. ${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: TColors.black,
                        ),
                      ),
                      if (discount > 0) ...[
                        Text(
                          'Rs. ${mrp.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          '($discount% OFF)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color.fromARGB(255, 46, 114, 52),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 3 — Orders  (real data)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return _emptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders made',
        subtitle: 'Orders placed for this shop will show up here',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '${_orders.length} orders',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: TColors.black,
          ),
        ),
        const SizedBox(height: 12),
        ..._orders.map(_orderCard),
      ],
    );
  }

  Widget _orderCard(Map<String, dynamic> o) {
    final status = o['itemStatus'] as String? ?? 'Processing';
    Color statusBg;
    Color statusFg;
    switch (status) {
      case 'Delivered':
        statusBg = const Color(0xFFE1F5EE);
        statusFg = const Color(0xFF085041);
        break;
      case 'Shipped':
        statusBg = const Color(0xFFE6F1FB);
        statusFg = const Color(0xFF185FA5);
        break;
      case 'Processing':
        statusBg = const Color(0xFFF5E4C0);
        statusFg = const Color(0xFFBA7517);
        break;
      case 'Cancelled':
        statusBg = const Color(0xFFFCEBEB);
        statusFg = const Color(0xFF791F1F);
        break;
      default:
        statusBg = TColors.cream;
        statusFg = TColors.brownLight;
    }

    final qty = (o['quantity'] as num?)?.toInt() ?? 1;
    final price = (o['price'] as num?)?.toDouble() ?? 0;
    final amount = price * qty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '#ORD-${o['orderId']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: TColors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  o['productName'] as String? ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: TColors.brownLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${o['customerName'] ?? ''}  ·  ${_formatDate(o['createdAt']?.toString() ?? '')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TColors.brownLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: TColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB 4 — Payouts  (real data)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPayoutsTab() {
    if (_payouts.isEmpty) {
      return _emptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No payouts yet',
        subtitle: 'Payouts released to this shop will appear here',
      );
    }

    final totalPaid = _payouts
        .where((p) => p['status'] == 'Completed')
        .fold<double>(
          0,
          (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0),
        );
    final pending = _payouts
        .where((p) => p['status'] == 'Pending')
        .fold<double>(
          0,
          (sum, p) => sum + ((p['amount'] as num?)?.toDouble() ?? 0),
        );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            _payoutSummaryCard(
              'Total paid out',
              '₹${totalPaid.toStringAsFixed(0)}',
              const Color(0xFFE1F5EE),
              const Color(0xFF085041),
            ),
            const SizedBox(width: 10),
            _payoutSummaryCard(
              'Pending',
              '₹${pending.toStringAsFixed(0)}',
              const Color(0xFFF5E4C0),
              const Color(0xFFBA7517),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Payout history',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: TColors.black,
          ),
        ),
        const SizedBox(height: 10),
        ..._payouts.map(_payoutCard),
      ],
    );
  }

  Widget _payoutSummaryCard(String label, String value, Color bg, Color fg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: fg.withValues(alpha: 0.8)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payoutCard(Map<String, dynamic> p) {
    final isPending = p['status'] == 'Pending';
    final amount = (p['amount'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPending
                  ? const Color(0xFFF5E4C0)
                  : const Color(0xFFE1F5EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPending ? Icons.schedule_outlined : Icons.check_circle_outline,
              size: 18,
              color: isPending
                  ? const Color(0xFFBA7517)
                  : const Color(0xFF085041),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#PAY-${p['payoutId']}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: TColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${p['method'] ?? ''}  ·  ${p['orderCount'] ?? 0} orders  ·  ${_formatDate(p['requestedAt']?.toString() ?? '')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TColors.brownLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TColors.black,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isPending
                      ? const Color(0xFFF5E4C0)
                      : const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  p['status'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPending
                        ? const Color(0xFFBA7517)
                        : const Color(0xFF085041),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  // Empty state used by Products / Orders / Payouts tabs when there's no data
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: TColors.cream,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: TColors.brownLight),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: TColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: TColors.brownLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: TColors.brownLight),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: TColors.cream,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TColors.border),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 16),

                        SizedBox(width: 5),

                        Text(
                          "Edit",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: TColors.border, height: 1),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: TColors.brownLight),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: TColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingToggleRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: TColors.brownLight),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: value ? const Color(0xFFE1F5EE) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value ? 'Enabled' : 'Disabled',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: value ? const Color(0xFF085041) : TColors.brownLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color bg,
    required Color fg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Improved stat card — icon in a soft circular badge + value/label,
  // with a subtle shadow so it lifts off the cream background.
  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color bg,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: TColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: TColors.black,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: TColors.brownLight,
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

  Widget _statusBadge(bool isBlocked) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isBlocked ? const Color(0xFFFCEBEB) : const Color(0xFFE1F5EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBlocked ? const Color(0xFFF09595) : const Color(0xFF7DD4B0),
        ),
      ),
      child: Text(
        isBlocked ? 'Blocked' : 'Active',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isBlocked ? const Color(0xFF791F1F) : const Color(0xFF085041),
        ),
      ),
    );
  }

  // ─── Utils ────────────────────────────────────────────────────────────────
  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String _formatRevenue(dynamic raw) {
    final num value = (raw is num)
        ? raw
        : num.tryParse(raw?.toString() ?? '') ?? 0;
    if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(1)}L';
    }
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(0)}k';
    return '₹${value.toStringAsFixed(0)}';
  }

  String _maskAccount(String account) {
    if (account.length <= 4) return account;
    return '•••• •••• ${account.substring(account.length - 4)}';
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
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
    } catch (_) {
      return raw;
    }
  }

  static const List<Color> _avatarColors = [
    Color(0xFF1D9E75),
    Color(0xFFBA7517),
    Color(0xFF3B6D11),
    Color(0xFFA32D2D),
    Color(0xFF534AB7),
    Color(0xFF993556),
    Color(0xFF185FA5),
    Color(0xFF7A3B1E),
  ];
  static const List<Color> _bannerColors = [
    Color(0xFFD4EDE3),
    Color(0xFFF5E4C0),
    Color(0xFFD8EDCA),
    Color(0xFFF5D0D0),
    Color(0xFFE0DEFA),
    Color(0xFFF5D8E8),
    Color(0xFFE6F1FB),
    Color(0xFFFDE8D8),
  ];

  Color _avatarColor(int id) => _avatarColors[id % _avatarColors.length];
  Color _bannerColor(int id) => _bannerColors[id % _bannerColors.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// Pinned tab bar delegate
// ─────────────────────────────────────────────────────────────────────────────
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height + 1;
  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: TColors.white,
      child: Column(
        children: [
          tabBar,
          Container(height: 1, color: TColors.border),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
