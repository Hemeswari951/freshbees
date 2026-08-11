
import '../models/shop_model.dart';
import 'api_service.dart';

/// Customer-facing shop service.
///
/// Calls the same backend the admin panel writes to, so any shop the
/// admin creates (and activates) automatically shows up here — no more
/// hardcoded shop cards.
///
/// NOTE: This expects a backend route:
///   GET /api/customer/shops
/// returning: { "success": true, "data": [ { ...shop fields... }, ... ] }
/// only including shops with status == "Active".
///
/// If your backend doesn't have this route yet, add it alongside your
/// existing /api/customer/products route (see product_service.dart for
/// the same pattern) — it should just query the shops table/collection
/// filtered by status = 'Active' (and optionally by proximity/city for
/// "nearby" shops).
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
}
