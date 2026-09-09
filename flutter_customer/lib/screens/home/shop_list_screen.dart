import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/shop_model.dart';
import '../../services/api_service.dart';
import '../../services/home_service.dart';
import '../../services/location_manager.dart';
import '../../widgets/product_mobile_header.dart';
import 'widgets/shop_card.dart';

class ShopListScreen extends StatefulWidget {
  final String categoryTitle;
  final String? searchQuery;

  const ShopListScreen({
    super.key,
    required this.categoryTitle,
    this.searchQuery,
  });

  @override
  State<ShopListScreen> createState() => _ShopListScreenState();
}

class _ShopListScreenState extends State<ShopListScreen> {
  List<ShopModel> _shops = [];

  bool _isLoading = true;
  String? _error;

  final LocationManager _locationManager = LocationManager();

  static const Color _bg = Color(0xFFFAF7F2);
  static const Color _ink = Color(0xFF1F1B16);

  @override
  void initState() {
    super.initState();
    _loadAllShops();
  }

  // ============================================================
  // LOAD SHOPS
  // ============================================================

  Future<void> _loadAllShops() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // ----------------------------------------------------------
      // Load current location
      // ----------------------------------------------------------

      await _locationManager.ensureLoaded();

      if (!mounted) return;

      // ----------------------------------------------------------
      // Category
      //
      // "All" -> null
      // Other category -> category name
      // ----------------------------------------------------------

      final String? categoryParam =
          widget.categoryTitle.trim().toLowerCase() == 'all'
          ? null
          : widget.categoryTitle.trim();

      // ----------------------------------------------------------
      // Get shops from API
      // ----------------------------------------------------------

      List<ShopModel> shops = await HomeService.getShops(
        category: categoryParam,
        latitude: _locationManager.latitude,
        longitude: _locationManager.longitude,
      );

      // ----------------------------------------------------------
      // SEARCH FILTER
      //
      // Search query irundha mattum filter pannum.
      //
      // Example:
      // searchQuery = "fresh"
      //
      // Fresh Mart
      // Fresh Basket
      // Fresh Corner
      //
      // mattum show aagum.
      //
      // searchQuery null / empty -> ALL shops
      // ----------------------------------------------------------

      final String query = widget.searchQuery?.trim().toLowerCase() ?? '';

      if (query.isNotEmpty) {
        shops = shops.where((shop) {
          final String shopName = shop.shopName.toLowerCase();

          return shopName.contains(query);
        }).toList();
      }

      if (!mounted) return;

      // ----------------------------------------------------------
      // Update UI
      // ----------------------------------------------------------

      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('ShopListScreen._loadAllShops error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Could not load shops. Please try again.';
      });
    }
  }

  // ============================================================
  // OPEN SHOP
  // ============================================================

  void _openShop(ShopModel shop) {
    final Uri uri = Uri(
      path: '/products',
      queryParameters: {
        'shopId': shop.id.toString(),
        'shopName': shop.shopName,
        'category': widget.categoryTitle,
      },
    );

    context.push(uri.toString());
  }

  // ============================================================
  // BACK / PROTECTED NAV
  // ============================================================

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _goToProtected(String route) {
    final token = ApiService.getToken();

    final isLoggedIn = token != null && token.isNotEmpty;

    if (isLoggedIn) {
      context.push(route);
    } else {
      context.push(
        Uri(path: '/login', queryParameters: {'redirect': route}).toString(),
      );
    }
  }

  // ============================================================
  // BREADCRUMB
  // ============================================================

  Widget _buildBreadcrumb() {
    TextStyle crumbStyle({bool active = false}) {
      return TextStyle(
        fontSize: 15,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? _ink : _ink.withOpacity(0.5),
      );
    }

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            context.go('/home');
          },
          child: Text('Home', style: crumbStyle()),
        ),

        Text('  /  ', style: crumbStyle()),

        Expanded(
          child: Text(
            '${widget.categoryTitle} Stores',
            style: crumbStyle(active: true),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PAGE TITLE
  // ============================================================

  String get _pageTitle {
    final query = widget.searchQuery?.trim() ?? '';

    if (query.isNotEmpty) {
      return 'Results for "$query"';
    }

    return '${widget.categoryTitle} Stores';
  }

  // ============================================================
  // OUTLET TITLE
  // ============================================================

  String get _outletTitle {
    final query = widget.searchQuery?.trim() ?? '';

    if (query.isNotEmpty) {
      return 'Shops matching "$query"';
    }

    return 'Nearby ${widget.categoryTitle} Outlets';
  }

  // ============================================================
  // HEADER (page-content header — title + result count, NOT the
  // top navigation bar)
  // ============================================================

  Widget _buildHeader({required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isDesktop) ...[_buildBreadcrumb(), const SizedBox(height: 20)],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _outletTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 12),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8DFD1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_shops.length} Found',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),

        // Show search information when search is active
        if (widget.searchQuery != null &&
            widget.searchQuery!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),

          Text(
            'Showing shops based on your search',
            style: TextStyle(fontSize: 12, color: _ink.withOpacity(0.55)),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final query = widget.searchQuery?.trim() ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              query.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.storefront_outlined,
              size: 52,
              color: Colors.black26,
            ),

            const SizedBox(height: 16),

            Text(
              query.isNotEmpty ? 'No shops found' : 'No shops available',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              query.isNotEmpty
                  ? 'No shops match "$query".'
                  : 'No shops available in this category.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _loadAllShops,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Colors.black38,
            ),

            const SizedBox(height: 12),

            Text(
              _error ?? 'Something went wrong.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _loadAllShops,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SHOP GRID
  // ============================================================

  Widget _buildShopGrid({required bool isDesktop}) {
    final int crossAxisCount = isDesktop ? 4 : 2;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 40.0 : 16.0),

      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,

          crossAxisSpacing: 16,

          mainAxisSpacing: 16,

          childAspectRatio: 0.82,
        ),

        delegate: SliverChildBuilderDelegate((context, index) {
          final ShopModel shop = _shops[index];

          final String categoryLabel = shop.categories.isNotEmpty
              ? shop.categories.first
              : widget.categoryTitle;

          return ShopCard(
            shop: shop,
            width: double.infinity,
            category: categoryLabel,
            onTap: () {
              _openShop(shop);
            },
          );
        }, childCount: _shops.length),
      ),
    );
  }

  // ============================================================
  // CONTENT (loading / error / empty / grid) — shared by both
  // mobile and desktop layouts.
  // ============================================================

  Widget _buildContent({required bool isDesktop}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_shops.isEmpty) {
      return _buildEmptyState();
    }

    return CustomScrollView(
      slivers: [
        // ------------------------------------------------
        // HEADER
        // ------------------------------------------------

        SliverPadding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 40.0 : 16.0,
            vertical: 20.0,
          ),

          sliver: SliverToBoxAdapter(child: _buildHeader(isDesktop: isDesktop)),
        ),

        // ------------------------------------------------
        // SHOP GRID
        // ------------------------------------------------
        _buildShopGrid(isDesktop: isDesktop),

        // ------------------------------------------------
        // BOTTOM SPACE
        // ------------------------------------------------
        const SliverPadding(padding: EdgeInsets.only(bottom: 40.0)),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: _bg,

      // --------------------------------------------------------
      // BODY
      //
      // Mobile: the old plain AppBar (back arrow + title only)
      // is replaced with the shared ProductMobileHeader — same
      // back / search / cart header used on the product list and
      // product view screens. Desktop is untouched (breadcrumb
      // still lives inside _buildHeader as before, no top bar).
      // --------------------------------------------------------
      body: SafeArea(
        child: isDesktop
            ? _buildContent(isDesktop: true)
            : Column(
                children: [
                  ProductMobileHeader(
                    title: _pageTitle,
                    onBack: _goBack,
                    onCart: () => _goToProtected('/cart'),
                  ),

                  Expanded(child: _buildContent(isDesktop: false)),
                ],
              ),
      ),
    );
  }
}
