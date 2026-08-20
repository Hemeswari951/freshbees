import '../models/shop_model.dart';
import 'api_service.dart';

class HomeService {
  HomeService._();

  static List<ShopModel> _parseShops(dynamic response) {
    if (response is Map<String, dynamic>) {
      final List data = response['data'] ?? [];
      return data.map((json) => ShopModel.fromJson(json)).toList();
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

  /// Single route for every tab. Pass `category: null` (or 'All') for
  /// every shop; pass 'Men' / 'Women' / 'Kids' / 'Beauty' to filter.
  /// Adding a new category later needs zero changes here — just pass
  /// a different string in from the tab.
  ///
  /// TODO: adjust the path ('/shops') and param name ('category') if
  /// your backend uses different ones.
  static Future<List<ShopModel>> getShops({String? category}) async {
    final params = <String, String>{};
    if (category != null && category.toLowerCase() != 'all') {
      params['category'] = category.toLowerCase();
    }
    final query = _buildQuery(params);
    final response = await ApiService.get('/home/get-shops$query');
    return _parseShops(response);
  }
}