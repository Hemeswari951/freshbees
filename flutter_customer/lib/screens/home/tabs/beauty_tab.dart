import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/shop_model.dart';
import '../widgets/product_grid.dart';
import '../../../services/home_service.dart';
import '../widgets/shop_grid.dart';

/// Content shown when the "Beauty" toggle is selected on Home.
class BeautyTab extends StatefulWidget {
  const BeautyTab({super.key});

  @override
  State<BeautyTab> createState() => _BeautyTabState();
}

class _BeautyTabState extends State<BeautyTab> {
  List<ShopModel> _shops = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShops();
  }

  Future<void> _loadShops() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final shops = await HomeService.getShops(category: 'Beauty');

      if (!mounted) return;

      setState(() {
        _shops = shops;
        _isLoading = false;
      });
    } catch (e) {
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
      },
    );

    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SHOPS SECTION (top) ──────────────────────────────────
        _buildShopsSection(),

        const SizedBox(height: 28),

        _buildProductsSection(),
      ],
    );
  }

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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'No shops found.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return ShopGrid(shops: _shops, onShopTap: _openShop, category: 'All');
  }

  Widget _buildProductsSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'All Products',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        ProductGrid(category: 'beauty'),
      ],
    );
  }
}
