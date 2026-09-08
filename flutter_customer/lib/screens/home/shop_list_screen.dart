import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/shop_model.dart';
import '../../services/home_service.dart';
import '../../services/location_manager.dart';
import 'widgets/shop_card.dart';

class ShopListScreen extends StatefulWidget {
  final String categoryTitle;

  const ShopListScreen({super.key, required this.categoryTitle});

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

  Future<void> _loadAllShops() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      await _locationManager.ensureLoaded();

      if (!mounted) return;

      final catParam = widget.categoryTitle.toLowerCase() == 'all'
          ? null
          : widget.categoryTitle;

      final shops = await HomeService.getShops(
        category: catParam,
        latitude: _locationManager.latitude,
        longitude: _locationManager.longitude,
      );

      if (!mounted) return;

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

  void _openShop(ShopModel shop) {
    final uri = Uri(
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
  // DYNAMIC BREADCRUMB
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
          onTap: () => context.go('/home'),
          child: Text('Home', style: crumbStyle()),
        ),

        Text('  /  ', style: crumbStyle()),

        // Current page
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

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 768;

    final crossAxisCount = isDesktop ? 4 : 2;

    return Scaffold(
      backgroundColor: _bg,

      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: _ink,
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
              title: Text(
                '${widget.categoryTitle} Stores',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              centerTitle: false,
            ),

      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadAllShops,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : _shops.isEmpty
            ? const Center(
                child: Text(
                  'No shops available in this category.',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 40.0 : 16.0,
                      vertical: 20.0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (isDesktop) ...[
                          _buildBreadcrumb(),
                          const SizedBox(height: 20),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nearby ${widget.categoryTitle} Outlets',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
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

                        const SizedBox(height: 16),
                      ]),
                    ),
                  ),

                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 40.0 : 16.0,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.82,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final shop = _shops[index];

                        final categoryLabel = shop.categories.isNotEmpty
                            ? shop.categories.first
                            : widget.categoryTitle;

                        return ShopCard(
                          shop: shop,
                          width: double.infinity,
                          category: categoryLabel,
                          onTap: () => _openShop(shop),
                        );
                      }, childCount: _shops.length),
                    ),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 40.0)),
                ],
              ),
      ),
    );
  }
}
