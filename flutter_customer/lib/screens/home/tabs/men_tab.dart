import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/shop_model.dart';
import '../../../services/home_service.dart';
import '../widgets/shop_grid.dart';

/// Content shown when the "Men" toggle is selected on Home.
class MenTab extends StatefulWidget {
  const MenTab({super.key});

  @override
  State<MenTab> createState() => _MenTabState();
}

class _MenTabState extends State<MenTab> {
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
      final shops = await HomeService.getShops(category: 'Men');

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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
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
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text(
            'No Men shops found.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }
    return ShopGrid(shops: _shops, onShopTap: _openShop, category: 'All');
  }
}
