import 'package:flutter/material.dart';
import '../../widgets/t_colors.dart';
import '../../services/shop_service.dart';
import '../../services/api_service.dart';
import 'add_shop_screen.dart';
import 'shop_detail_screen.dart';
import '../../core/responsive.dart';

class ShopsScreen extends StatelessWidget {
  const ShopsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ShopsBody();
}

class _ShopsBody extends StatefulWidget {
  const _ShopsBody();

  @override
  State<_ShopsBody> createState() => _ShopsBodyState();
}

class _ShopsBodyState extends State<_ShopsBody> {
  String selectedFilter = 'All';
  String searchQuery = '';
  int? hoveredCard;

  // ── Real data ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> allShops = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final shops = await ShopService.getAllShops();
      setState(() {
        allShops = shops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ── Filters ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get filteredShops {
    return allShops.where((s) {
      final matchFilter =
          selectedFilter == 'All' || s['status'] == selectedFilter;
      final matchSearch =
          searchQuery.isEmpty ||
          (s['shopName'] as String).toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          (s['ownerName'] as String).toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
      return matchFilter && matchSearch;
    }).toList();
  }

  int get totalShops => allShops.length;
  int get activeShops => allShops.where((s) => s['status'] == 'Active').length;
  int get blockedShops =>
      allShops.where((s) => s['status'] == 'Blocked').length;

  // ── Revenue formatter  ₹82000 → ₹82k  ───────────────────────────────────
  String _formatRevenue(dynamic raw) {
    final num value = (raw is num) ? raw : num.tryParse(raw.toString()) ?? 0;
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(1)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(0)}k';
    return '₹${value.toStringAsFixed(0)}';
  }

  // ── Initials from shop name  "Ravi's Fashion" → "RF" ─────────────────────
  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ── Deterministic avatar color from shopId ────────────────────────────────
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

  Color _avatarColor(int shopId) =>
      _avatarColors[shopId % _avatarColors.length];
  Color _bannerColor(int shopId) =>
      _bannerColors[shopId % _bannerColors.length];

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    
    // Loading state
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: TColors.black),
      );
    }

    // Error state
    if (_error != null) {
      return Center(
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
              'Failed to load shops',
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
              onTap: _loadShops,
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
      );
    }

    final shops = filteredShops;
    final isMobile = Responsive.isMobile(context);
    return Container(
      color: TColors.cream,
      child: RefreshIndicator(
        color: TColors.black,
        onRefresh: _loadShops,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
  isMobile ? 12 : 24,
),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatCards(),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildFilterRow(),
              const SizedBox(height: 16),
              shops.isEmpty ? _buildEmptyState() : _buildGrid(shops),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stat cards ────────────────────────────────────────────────────────────
  Widget _buildStatCards() {
  final isMobile = Responsive.isMobile(context);

  if (isMobile) {
    return Column(
      children: [
        _statCard(
          'Total Shops',
          totalShops.toString(),
          Icons.store_outlined,
          const Color(0xFFE6F1FB),
          const Color(0xFF185FA5),
        ),

        const SizedBox(height: 12),

        _statCard(
          'Active Shops',
          activeShops.toString(),
          Icons.check_circle_outline,
          const Color(0xFFE1F5EE),
          const Color(0xFF085041),
        ),

        const SizedBox(height: 12),

        _statCard(
          'Blocked Shops',
          blockedShops.toString(),
          Icons.block_outlined,
          const Color(0xFFFCEBEB),
          const Color(0xFF791F1F),
        ),
      ],
    );
  }

  return Row(
    children: [
      _statCard(
        'Total Shops',
        totalShops.toString(),
        Icons.store_outlined,
        const Color(0xFFE6F1FB),
        const Color(0xFF185FA5),
      ),

      const SizedBox(width: 12),

      _statCard(
        'Active Shops',
        activeShops.toString(),
        Icons.check_circle_outline,
        const Color(0xFFE1F5EE),
        const Color(0xFF085041),
      ),

      const SizedBox(width: 12),

      _statCard(
        'Blocked Shops',
        blockedShops.toString(),
        Icons.block_outlined,
        const Color(0xFFFCEBEB),
        const Color(0xFF791F1F),
      ),
    ],
  );
}

  Widget _statCard(
  String label,
  String value,
  IconData icon,
  Color bg,
  Color color,
) {
  final isMobile = Responsive.isMobile(context);

  Widget card = Container(
    width: isMobile ? double.infinity : null,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: TColors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: TColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: TColors.black,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: TColors.brownLight,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  if (isMobile) {
    return card;
  }

  return Expanded(child: card);
}
  // ── Search bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return SizedBox(
      height: 40,
      child: TextField(
        onChanged: (val) => setState(() => searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search shops by name or owner...',
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
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
            borderSide: const BorderSide(color: TColors.black, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Filter chips + Add shop ───────────────────────────────────────────────
 Widget _buildFilterRow() {
  final isMobile = Responsive.isMobile(context);

  // Add Shop Button
  Widget addShopButton = MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AddShopScreen(),
          ),
        );

        // Refresh list after returning
        _loadShops();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: TColors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 15,
              color: TColors.white,
            ),
            SizedBox(width: 5),
            Text(
              "Add Shop",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: TColors.white,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // Mobile Layout
  if (isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chip('All', totalShops),
            _chip('Active', activeShops),
            _chip('Blocked', blockedShops),
          ],
        ),

        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: addShopButton,
        ),
      ],
    );
  }

  // Desktop / Tablet Layout
  return Row(
    children: [
      _chip('All', totalShops),

      const SizedBox(width: 8),

      _chip('Active', activeShops),

      const SizedBox(width: 8),

      _chip('Blocked', blockedShops),

      const Spacer(),

      addShopButton,
    ],
  );
}

  Widget _chip(String label, int count) {
    final active = selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => selectedFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? TColors.black : TColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? TColors.black : TColors.border),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active ? TColors.white : TColors.brown,
          ),
        ),
      ),
    );
  }

  // ── Grid ──────────────────────────────────────────────────────────────────
  Widget _buildGrid(List<Map<String, dynamic>> shops) {
  final crossAxisCount = Responsive.isDesktop(context)
      ? 3
      : Responsive.isTablet(context)
          ? 2
          : 1;

  final childAspectRatio = Responsive.isMobile(context)
      ? 1.35
      : 1.55;

  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    ),
    itemCount: shops.length,
    itemBuilder: (_, i) => _buildCard(shops[i], i),
  );
}
  // ── Shop card ─────────────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> shop, int index) {
    final hovered = hoveredCard == index;
    final isBlocked = shop['status'] == 'Blocked';
    final int shopId = shop['shopId'] as int;
    final avatarColor = _avatarColor(shopId);
    final bannerColor = _bannerColor(shopId);
    final initials = _initials(shop['shopName'] as String);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hoveredCard = index),
      onExit: (_) => setState(() => hoveredCard = null),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ShopDetailScreen(shopId: shopId)),
          );
          // Refresh in case block status changed inside detail screen
          _loadShops();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: TColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovered ? TColors.black : TColors.border,
              width: hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: hovered ? 0.07 : 0.03),
                blurRadius: hovered ? 14 : 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Banner ───────────────────────────────────────────────
              Stack(
                children: [
                  // Banner background or image
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: isBlocked
                          ? bannerColor.withValues(alpha: 0.6)
                          : bannerColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      image: shop['shopBanner'] != null
                          ? DecorationImage(
                              image: NetworkImage(
                                '${ApiService.serverUrl}${shop['shopBanner']}',
                              ),
                              fit: BoxFit.cover,
                              opacity: isBlocked ? 0.5 : 1.0,
                            )
                          : null,
                    ),
                  ),

                  // Rating — top right
                  Positioned(
                    top: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TColors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Color(0xFFBA7517),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            (shop['avgRating'] as num).toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: TColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Blocked badge — top left
                  if (isBlocked)
                    Positioned(
                      top: 8,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCEBEB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF09595)),
                        ),
                        child: const Text(
                          'Blocked',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF791F1F),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ── Body ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo + shop name row
                    Row(
                      children: [
                        // Logo: real image or initials fallback
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: avatarColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: TColors.white,
                              width: 1.5,
                            ),
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
                                    initials,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: TColors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        // Name + owner
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop['shopName'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: TColors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${shop['ownerName']} · ${shop['location']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: TColors.brownLight,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Category
                    Row(
                      children: [
                        const Icon(
                          Icons.sell_outlined,
                          size: 10,
                          color: TColors.brownLight,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                             (shop['categories'] as List).join(", "),
                            style: const TextStyle(
                              fontSize: 12,
                              color: TColors.brownLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Mini stats row
                    Row(
                      children: [
                        _miniStat(
                          Icons.inventory_2_outlined,
                          shop['totalProducts'].toString(),
                          'Products',
                        ),
                        const SizedBox(width: 6),
                        _miniStat(
                          Icons.receipt_long_outlined,
                          shop['totalOrders'].toString(),
                          'Orders',
                        ),
                        const SizedBox(width: 6),
                        _miniStat(
                          Icons.currency_rupee,
                          _formatRevenue(shop['totalRevenue']),
                          'Revenue',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: TColors.cream,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Icon(icon, size: 12, color: TColors.brownLight),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: TColors.black,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: TColors.brownLight),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return SizedBox(
      height: 340,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: TColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.store_outlined,
                size: 30,
                color: TColors.brownLight,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'No shops found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: TColors.black,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Try a different filter or add a new shop',
              style: TextStyle(fontSize: 12, color: TColors.brownLight),
            ),
            const SizedBox(height: 18),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddShopScreen()),
                  );
                  _loadShops();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: TColors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 15, color: TColors.white),
                      SizedBox(width: 6),
                      Text(
                        'Add shop',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: TColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
