import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/shop_model.dart';
import '../../../services/home_service.dart';
import '../../../services/location_manager.dart';
import '../widgets/shop_grid.dart';
import '../widgets/product_grid.dart';

class AllTab extends StatefulWidget {
  /// Active text search (from the search bar, voice search, or a tapped
  /// suggestion) — when set, the Products section below shows
  /// relevance-ranked matches instead of the plain "all products" list.
  final String? searchQuery;

  /// Active image search (camera icon) — when set, the Products section
  /// shows only the single closest-matching product. Mutually exclusive
  /// with [searchQuery].
  final XFile? searchImage;

  /// Called when the person taps "Clear search" — null when no search is
  /// currently active (so the button simply isn't shown).
  final VoidCallback? onClearSearch;

  const AllTab({
    super.key,
    this.searchQuery,
    this.searchImage,
    this.onClearSearch,
  });

  @override
  State<AllTab> createState() => _AllTabState();
}

class _AllTabState extends State<AllTab> {
  List<ShopModel> _shops = [];

  bool _isLoading = true;

  String? _error;

  final LocationManager _locationManager = LocationManager();

  int _lastLocationVersion = 0;

  @override
  void initState() {
    super.initState();

    // Listen for location changes.
    _locationManager.addListener(_onLocationChanged);

    _lastLocationVersion = _locationManager.locationVersion;

    _loadShops();
  }

  // ===========================================================================
  // LOCATION CHANGED
  // ===========================================================================

  void _onLocationChanged() {
    if (!mounted) return;

    final currentVersion = _locationManager.locationVersion;

    if (currentVersion == _lastLocationVersion) {
      return;
    }

    _lastLocationVersion = currentVersion;

    debugPrint('AllTab: Location changed. Reloading shops...');

    _loadShops();
  }

  // ===========================================================================
  // LOAD SHOPS
  // ===========================================================================

  Future<void> _loadShops() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Make sure latest location/login state is available.
      await _locationManager.ensureLoaded();

      if (!mounted) return;

      final latitude = _locationManager.latitude;
      final longitude = _locationManager.longitude;

      debugPrint('AllTab: User latitude = $latitude');

      debugPrint('AllTab: User longitude = $longitude');

      final shops = await HomeService.getShops(
        category: null,
        latitude: latitude,
        longitude: longitude,
      );

      if (!mounted) return;

      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AllTab._loadShops error: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Could not load shops. Please try again.';
      });
    }
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================
  @override
  void dispose() {
    _locationManager.removeListener(_onLocationChanged);

    super.dispose();
  }

  // ===========================================================================
  // OPEN SHOP
  // ===========================================================================

  void _openShop(ShopModel shop) {
    final uri = Uri(
      path: '/products',
      queryParameters: {
        'shopId': shop.id.toString(),
        'shopName': shop.shopName,
      },
    );

    context.push(uri.toString());
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShopsSection(),

        const SizedBox(height: 28),

        _buildProductsSection(),
      ],
    );
  }

  // ===========================================================================
  // SHOPS SECTION
  // ===========================================================================

  Widget _buildShopsSection() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 12),
              TextButton(onPressed: _loadShops, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_shops.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayedShops = _shops.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Near By Shops',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),

            if (_shops.length > 5)
              TextButton(
                onPressed: () {
                  context.push('/shops?category=All');
                },
                child: const Text('See All'),
              ),
          ],
        ),

        const SizedBox(height: 12),

        ShopGrid(shops: displayedShops, onShopTap: _openShop, category: 'All'),
      ],
    );
  }

  // ===========================================================================
  // PRODUCTS SECTION
  // ===========================================================================

  Widget _buildProductsSection() {
    final bool isSearching =
        widget.searchQuery != null || widget.searchImage != null;

    final String heading = widget.searchImage != null
        ? 'Image Search Result'
        : (widget.searchQuery != null
            ? 'Results for "${widget.searchQuery}"'
            : 'All Products');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  heading,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSearching && widget.onClearSearch != null)
                TextButton.icon(
                  onPressed: widget.onClearSearch,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('Clear search'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
        ),
        ProductGrid(
          category: 'all',
          searchQuery: widget.searchQuery,
          searchImage: widget.searchImage,
        ),
      ],
    );
  }
}
