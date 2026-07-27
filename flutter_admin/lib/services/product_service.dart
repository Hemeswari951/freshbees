import 'api_service.dart';

/// Admin-side product access — only what the admin app needs right now:
/// list every product (across all shops) and view one product's full
/// detail. There is no updateProductStatus/activate-deactivate call here
/// because the admin backend doesn't expose that endpoint yet — if
/// ProductViewScreen's active/inactive toggle is used on the admin side,
/// it will throw until that endpoint + this method are added.
class ProductService {
  // GET /api/admin/products
  // filters are all optional and only narrow the admin's view — never
  // an authorization check, admin can already see every shop's products.
  static Future<List<Map<String, dynamic>>> getAllProducts({
    int? shopId,
    int? categoryId,
    bool? isActive,
    String? search,
  }) async {
    final params = <String, String>{};
    if (shopId != null) params['shopId'] = '$shopId';
    if (categoryId != null) params['categoryId'] = '$categoryId';
    if (isActive != null) params['isActive'] = '$isActive';
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    final query = params.isEmpty
        ? ''
        : '?${params.entries.map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}').join('&')}';

    final res = await ApiService.get('/products$query');
    return List<Map<String, dynamic>>.from(res['products'] as List? ?? []);
  }

  // GET /api/admin/products/:productId
  // Used by ProductViewScreen. Throws (via ApiService._handle) if the
  // product doesn't exist — the screen's existing try/catch in _load()
  // already surfaces that as an error state with a Retry button.
  static Future<Map<String, dynamic>> getProductDetail(int productId) async {
    final res = await ApiService.get('/products/$productId');
    return Map<String, dynamic>.from(res['product'] as Map);
  }

  static Future<void> updateProductStatus(int productId, bool isActive) async {
    await ApiService.patch('/products/$productId/status', {
      'isActive': isActive,
    });
  }

  // Backend stores image paths relative to the server (e.g.
  // "/uploads/products/xyz.jpg"). This turns that into the absolute URL
  // Image.network needs. Already-absolute URLs pass through unchanged.
  static String fullImageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${ApiService.serverUrl}$path';
  }
}
