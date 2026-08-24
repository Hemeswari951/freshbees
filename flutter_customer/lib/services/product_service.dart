import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  ProductService._();

  // ---------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------

  static List<ProductModel> _parseProducts(dynamic response) {
    if (response is Map<String, dynamic>) {
      final List data = response['data'] ?? [];
      return data.map((json) => ProductModel.fromJson(json)).toList();
    }
    return [];
  }

  static String _buildQuery(Map<String, String> params) {
    if (params.isEmpty) return '';
    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return '?$query';
  }

  // ---------------------------------------------------------------------
  // endpoints
  // ---------------------------------------------------------------------

  /// Get all products, with optional filters (price range, colors,
  /// categories, discount, rating — see ProductFilters.toQueryParams()
  /// in product_filters.dart).
  static Future<List<ProductModel>> getProducts({
    Map<String, String>? filters,
  }) async {
    final query = _buildQuery(filters ?? {});
    final response = await ApiService.get('/products$query');
    return _parseProducts(response);
  }

  /// Get products belonging to a specific shop, with optional filters
  /// layered on top.
  ///
  /// TODO: if your backend uses a dedicated route instead of a query
  /// param (e.g. '/shops/$shopId/products'), swap the endpoint below —
  /// everything else stays the same.
  static Future<List<ProductModel>> getProductsByShop(
    int shopId, {
    Map<String, String>? filters,
  }) async {
    final params = {'shopId': shopId.toString(), ...?filters};
    final query = _buildQuery(params);
    final response = await ApiService.get('/products$query');
    return _parseProducts(response);
  }

  /// Search products by keyword, with optional filters layered on top.
  static Future<List<ProductModel>> searchProducts(
    String searchQuery, {
    Map<String, String>? filters,
  }) async {
    final params = {'search': searchQuery, ...?filters};
    final query = _buildQuery(params);
    final response = await ApiService.get('/products$query');
    return _parseProducts(response);
  }

  // ---------------------------------------------------------------------
  // wishlist
  // ---------------------------------------------------------------------
  // Goes through ApiService like every other call above, so it
  // automatically gets the '/api/customer' prefix, the auth header
  // (from ApiService.headers / the stored customer_token), and the same
  // JSON-parsing + error-throwing behaviour as get/post/delete.
  //
  // Full URLs hit: {serverUrl}/api/customer/wishlist
  //                {serverUrl}/api/customer/wishlist/:productId
  //
  // See the backend files (wishlistController.js / wishlistRoutes.js)
  // for the matching Express side — getWishlist there returns the same
  // `{ data: [...] }` envelope your product endpoints use, so
  // _parseProducts can be reused as-is.

  /// Fetches the logged-in customer's wishlist as full ProductModel
  /// objects. Throws (via ApiService's error handling) if the request
  /// fails — callers should catch and treat that as "couldn't load,
  /// hearts default to unfilled" rather than a hard error.
  static Future<List<ProductModel>> getWishlist() async {
    final response = await ApiService.get('/wishlist');
    return _parseProducts(response);
  }

  /// Adds [productId] to the logged-in customer's wishlist.
  /// Returns true on success, false on any failure (ApiService throws
  /// on non-2xx, or a network error) so the caller can roll back its
  /// optimistic UI update.
  static Future<bool> addToWishlist(int productId) async {
    try {
      await ApiService.post('/wishlist', {'productId': productId});
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Removes [productId] from the logged-in customer's wishlist.
  static Future<bool> removeFromWishlist(int productId) async {
    try {
      await ApiService.delete('/wishlist/$productId');
      return true;
    } catch (_) {
      return false;
    }
  }
}