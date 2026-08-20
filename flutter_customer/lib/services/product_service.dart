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
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
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
}