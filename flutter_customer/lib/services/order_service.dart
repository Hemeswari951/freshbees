
import 'api_service.dart';

class OrderService {
  OrderService._();

  /// Places an order for [productId] (optionally a specific [variantId]
  /// for the selected size/color) and [quantity]. Throws an Exception
  /// with a user-facing message on failure (handled by ApiService._handle).
  static Future<Map<String, dynamic>> placeOrder({
    required int productId,
    int? variantId,
    required int quantity,
  }) async {
    final body = {
      'product_id': productId,
      if (variantId != null) 'variant_id': variantId,
      'quantity': quantity,
    };

    return ApiService.post('/orders', body);
  }
}
