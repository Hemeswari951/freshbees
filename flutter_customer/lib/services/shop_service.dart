import '../models/shop_model.dart';
import '../models/product_model.dart';
import 'api_service.dart';

class ShopService {
  ShopService._();

  /// Get all active shops for the "Nearby Shops" / shop listing sections.
  static Future<List<ShopModel>> getNearbyShops() async {
    final response = await ApiService.get('/shops');

    if (response is Map<String, dynamic>) {
      final List data = response['data'] ?? [];
      return data
          .map((json) => ShopModel.fromJson(json as Map<String, dynamic>))
          .where((shop) => shop.isActive)
          .toList();
    }

    return [];
  }

  /// Get a single shop's details by id (for a future shop-detail screen).
  static Future<ShopModel?> getShopById(int shopId) async {
    final response = await ApiService.get('/shops/$shopId');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return ShopModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    return null;
  }

  /// Get every ACTIVE product added by this shop's owner — the same
  /// products already visible under the shop in the Admin Portal.
  /// Powers the Shop Detail screen opened by tapping a shop on Home.
  static Future<List<ProductModel>> getShopProducts(int shopId) async {
    final response = await ApiService.get('/shops/$shopId/products');

    if (response is Map<String, dynamic>) {
      final List data = response['data'] ?? [];
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}