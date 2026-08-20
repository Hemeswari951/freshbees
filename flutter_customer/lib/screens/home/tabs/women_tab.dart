import 'package:flutter/material.dart';

import '../../../models/shop_model.dart';
import '../../../services/home_service.dart';
import '../../product/product_list_screen.dart';

/// Content shown when the "Women" toggle is selected on Home.
class WomenTab extends StatefulWidget {
  const WomenTab({super.key});

  @override
  State<WomenTab> createState() => _WomenTabState();
}

class _WomenTabState extends State<WomenTab> {
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
      final shops = await HomeService.getShops(category: 'Women');
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          args: ProductListArgs.shop(shopId: shop.id, shopName: shop.shopName),
        ),
      ),
    );
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
          child: Text('No Women shops found.', style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _shops.length,
      itemBuilder: (context, index) {
        final shop = _shops[index];
        return _ShopCard(shop: shop, onTap: () => _openShop(shop));
      },
    );
  }
}

class _ShopCard extends StatelessWidget {
  final ShopModel shop;
  final VoidCallback onTap;

  const _ShopCard({required this.shop, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2ECE4),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.4,
              child: Container(
                color: const Color(0xFFE8DFD1),
                child: (shop.logoUrl != null && shop.logoUrl!.isNotEmpty)
                    ? Image.network(
                        shop.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(
                          Icons.storefront_outlined,
                          size: 36,
                          color: Colors.black38,
                        ),
                      )
                    : const Icon(
                        Icons.storefront_outlined,
                        size: 36,
                        color: Colors.black38,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.shopName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    shop.categoryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}