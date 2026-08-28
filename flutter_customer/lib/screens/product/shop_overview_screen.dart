import 'package:flutter/material.dart';

import '../../models/shop_model.dart';
// Expected signature: static Future<ShopModel> getShopById(int shopId)
import '../../services/shop_overview_service.dart';

/// Shows a shop's profile — banner, logo, name, categories, rating,
/// location, description, and the shop owner's details.
///
/// Responsive:
/// - Width >= [_desktopBreakpoint] → NO app-bar header. Instead a thin
///   breadcrumb route bar ("← Shops / ShopName") sits fixed at the top,
///   and the page below is a wide two-column layout (content + a
///   pinned info/owner sidebar).
/// - Below that → normal mobile pattern: a pinned SliverAppBar with a
///   back button + shop name that reveals as the banner collapses,
///   single stacked column underneath.
class ShopOverviewScreen extends StatefulWidget {
  final int shopId;

  const ShopOverviewScreen({super.key, required this.shopId});

  @override
  State<ShopOverviewScreen> createState() => _ShopOverviewScreenState();
}

class _ShopOverviewScreenState extends State<ShopOverviewScreen> {
  static const double _desktopBreakpoint = 900;
  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _ink = Color(0xFF1F1B16);

  ShopModel? _shop;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final shop = await ShopOverviewService.getShopById(widget.shopId);
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load shop details. Please try again.';
      });
    }
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Scaffold(
      backgroundColor: _bg,
      // Mobile gets its back button from the SliverAppBar itself, so no
      // SafeArea top-padding fight there. Desktop's breadcrumb bar needs
      // its own top inset since there's no AppBar providing it.
      body: SafeArea(
        top: isDesktop,
        bottom: false,
        child: _buildBody(context, isDesktop),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDesktop) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadShop, child: const Text('Retry')),
          ],
        ),
      );
    }

    final shop = _shop;
    if (shop == null) {
      return const Center(child: Text('Shop not found.'));
    }

    return isDesktop ? _buildDesktopScaffold(shop) : _buildMobileScaffold(shop);
  }

  // =============================================================
  // DESKTOP — breadcrumb route bar + wide two-column layout
  // =============================================================

  Widget _buildDesktopScaffold(ShopModel shop) {
    return Column(
      children: [
        _buildBreadcrumbBar(shop),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDesktopBanner(shop),
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: _buildDesktopMainColumn(shop)),
                          const SizedBox(width: 28),
                          SizedBox(width: 320, child: _buildDesktopSidebar(shop)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Fixed "route" strip replacing the AppBar on desktop — click "Shops"
  /// or the arrow to go back, current shop name shown as the active crumb.
  Widget _buildBreadcrumbBar(ShopModel shop) {
    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: _ink),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => Navigator.maybePop(context),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'Shops',
                style: TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.chevron_right_rounded, size: 16, color: Colors.black38),
          ),
          Flexible(
            child: Text(
              shop.shopName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBanner(ShopModel shop) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 300,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBannerImage(shop),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 32,
              right: 32,
              bottom: 28,
              child: _buildLogoAndTitleRow(shop, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopMainColumn(ShopModel shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusChip(shop),
        const SizedBox(height: 18),
        _buildSectionTitle('About this shop'),
        const SizedBox(height: 8),
        _buildDescription(shop),
        const SizedBox(height: 26),
        _buildSectionTitle('Categories'),
        const SizedBox(height: 10),
        _buildCategoryChips(shop),
        const SizedBox(height: 26),
        _buildSectionTitle('Shop owner'),
        const SizedBox(height: 10),
        _buildOwnerCard(shop),
      ],
    );
  }

  Widget _buildDesktopSidebar(ShopModel shop) {
    return _buildStatsCard(shop);
  }

  // =============================================================
  // MOBILE — pinned SliverAppBar (back button + shop name) + stack
  // =============================================================

  Widget _buildMobileScaffold(ShopModel shop) {
    return CustomScrollView(
      slivers: [
        _buildMobileAppBar(shop),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusChip(shop),
                const SizedBox(height: 16),
                _buildStatsCard(shop),
                const SizedBox(height: 20),
                _buildSectionTitle('Shop owner'),
                const SizedBox(height: 10),
                _buildOwnerCard(shop),
                const SizedBox(height: 24),
                _buildSectionTitle('About this shop'),
                const SizedBox(height: 8),
                _buildDescription(shop),
                const SizedBox(height: 24),
                _buildSectionTitle('Categories'),
                const SizedBox(height: 10),
                _buildCategoryChips(shop),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileAppBar(ShopModel shop) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: Colors.white,
      foregroundColor: _ink,
      elevation: 0,
      // Default back button (auto-shown since this screen was pushed).
      title: Text(
        shop.shopName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildBannerImage(shop),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.30),
                    Colors.black.withOpacity(0.05),
                    Colors.black.withOpacity(0.50),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16, // stays inside the banner — nothing pokes into the content below
              child: _buildLogoAndTitleRow(shop, false),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SHARED — banner image, logo/title row
  // =============================================================

  Widget _buildBannerImage(ShopModel shop) {
    final bannerUrl = shop.bannerUrl;
    if (bannerUrl == null) {
      return Container(color: const Color(0xFFE8DFD3));
    }
    return Image.network(
      bannerUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE8DFD3)),
    );
  }

  Widget _buildLogoAndTitleRow(ShopModel shop, bool isDesktop) {
    final logoSize = isDesktop ? 96.0 : 72.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildLogo(shop.logoUrl, logoSize, fallbackIcon: Icons.storefront),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isDesktop ? 8 : 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isDesktop ? 26 : 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: const [Shadow(blurRadius: 6, color: Colors.black45)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shop.categoryLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(String? url, double size, {required IconData fallbackIcon}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: ClipOval(
        child: url == null
            ? Icon(fallbackIcon, size: size * 0.5, color: Colors.black26)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, size: size * 0.5, color: Colors.black26),
              ),
      ),
    );
  }

  // =============================================================
  // SHARED PIECES
  // =============================================================

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _ink),
    );
  }

  Widget _buildDescription(ShopModel shop) {
    final description = shop.description;
    if (description == null || description.isEmpty) {
      return const Text(
        'No description added yet.',
        style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
      );
    }
    return Text(
      description,
      style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
    );
  }

  Widget _buildCategoryChips(ShopModel shop) {
    if (shop.categories.isEmpty) {
      return const Text(
        'No categories added yet.',
        style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: shop.categories
          .map(
            (c) => Chip(
              label: Text(c, style: const TextStyle(fontSize: 12)),
              backgroundColor: const Color(0xFFF0E6D8),
              side: BorderSide.none,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatusChip(ShopModel shop) {
    final active = shop.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle : Icons.remove_circle,
            size: 14,
            color: active ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 6),
          Text(
            shop.status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  /// Rating + location + address — sidebar card on desktop, sits inline
  /// on mobile, right below the status chip.
  Widget _buildStatsCard(ShopModel shop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 6),
              Text(
                shop.rating.toStringAsFixed(1),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 4),
              Text(
                '(${shop.ratingCount} ratings)',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          if (shop.locationLabel.isNotEmpty) ...[
            const Divider(height: 28),
            _iconTextRow(Icons.location_on_outlined, shop.locationLabel),
          ],
          if (shop.address != null && shop.address!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _iconTextRow(Icons.map_outlined, shop.address!, dim: true),
          ],
        ],
      ),
    );
  }

  /// Shop owner's name, avatar, and contact details.
  /// NOTE: assumes ShopModel exposes ownerName / ownerEmail / ownerPhone /
  /// ownerProfileImage — add those fields if they aren't there yet.
  Widget _buildOwnerCard(ShopModel shop) {
    final hasOwnerInfo = shop.ownerName != null && shop.ownerName!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: !hasOwnerInfo
          ? const Text(
              'Owner details not available.',
              style: TextStyle(color: Colors.black45, fontStyle: FontStyle.italic),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildLogo(shop.ownerProfileImage, 52, fallbackIcon: Icons.person),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.ownerName!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Shop owner',
                            style: TextStyle(fontSize: 12, color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (shop.ownerPhone != null && shop.ownerPhone!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _iconTextRow(Icons.phone_outlined, shop.ownerPhone!),
                ],
                if (shop.ownerEmail != null && shop.ownerEmail!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _iconTextRow(Icons.mail_outline, shop.ownerEmail!),
                ],
              ],
            ),
    );
  }

  Widget _iconTextRow(IconData icon, String text, {bool dim = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: dim ? Colors.black54 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// USAGE
/// ---------------------------------------------------------------------
///
/// Navigator.push(context, MaterialPageRoute(
///   builder: (_) => ShopOverviewScreen(shopId: shopId),
/// ));