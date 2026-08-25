import '../models/product_model.dart';
import '../models/product_details_model.dart';
import 'api_service.dart';

// ---------------------------------------------------------------------
// Filter options — distinct sizes/colors actually present in the DB
// right now. Backend-driven so the filter panel's Size/Color lists
// never go stale when a shop owner adds a new color/size.
// ---------------------------------------------------------------------
class FilterOptionsResult {
  final List<String> colors;
  final List<String> sizes;

  const FilterOptionsResult({required this.colors, required this.sizes});

  factory FilterOptionsResult.fromJson(Map<String, dynamic> json) {
    return FilterOptionsResult(
      colors: (json['colors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      sizes: (json['sizes'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  static const empty = FilterOptionsResult(colors: [], sizes: []);
}

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
  //
  // NOTE: `filters` param is kept here for backward compatibility (e.g.
  // if you later want to push price range to the backend for large
  // catalogs), but ProductListScreen no longer passes anything in it —
  // size/color/discount/rating are all filtered client-side against
  // the full fetched list via ProductFilters.matches().
  // ---------------------------------------------------------------------

  static Future<List<ProductModel>> getProducts({
    Map<String, String>? filters,
  }) async {
    final query = _buildQuery(filters ?? {});
    final response = await ApiService.get('/products$query');
    return _parseProducts(response);
  }

  static Future<List<ProductModel>> getProductsByShop(
    int shopId, {
    Map<String, String>? filters,
  }) async {
    final params = {'shopId': shopId.toString(), ...?filters};
    final query = _buildQuery(params);
    final response = await ApiService.get('/products$query');
    return _parseProducts(response);
  }

  static Future<List<ProductModel>> searchProducts(
    String searchQuery, {
    Map<String, String>? filters,
  }) async {
    final params = {'search': searchQuery, ...?filters};
    final query = _buildQuery(params);
    final response = await ApiService.get('/products$query');
    return _parseProducts(response);
  }

  /// Distinct sizes/colors currently present across visible products —
  /// used to populate the filter panel's Size/Color lists dynamically.
  /// Fails soft (returns empty) so a broken/unreachable endpoint just
  /// hides those two filter groups instead of crashing the screen.
  static Future<FilterOptionsResult> getFilterOptions() async {
    try {
      final response = await ApiService.get('/products/meta/filter-options');
      if (response is Map<String, dynamic> && response['data'] != null) {
        return FilterOptionsResult.fromJson(response['data']);
      }
      return FilterOptionsResult.empty;
    } catch (_) {
      return FilterOptionsResult.empty;
    }
  }

  
  static Future<ProductDetailsModel> getProductDetails(int productId) async {
    final response = await ApiService.get('/products/$productId');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return ProductDetailsModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw Exception('Failed to load product details');
  }
}