
import '../models/product_model.dart';
import 'api_service.dart';

class WishlistService {
  WishlistService._();

  /// Every product the logged-in customer has wishlisted.
  static Future<List<ProductModel>> getWishlist() async {
    final response = await ApiService.get('/wishlist');

    if (response is Map<String, dynamic>) {
      final List data = response['data'] ?? [];
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  /// Add a product to the wishlist (heart tap on a product card).
  static Future<bool> addToWishlist(int productId) async {
    final response = await ApiService.post('/wishlist/$productId', {});
    return response['success'] == true;
  }

  /// Remove a product from the wishlist (heart tap again).
  static Future<bool> removeFromWishlist(int productId) async {
    final response = await ApiService.delete('/wishlist/$productId');
    return response['success'] == true;
  }
}