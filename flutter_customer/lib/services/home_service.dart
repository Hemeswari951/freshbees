import '../models/shop_model.dart';
import 'api_service.dart';

class HomeService {
  HomeService._();

  static List<ShopModel> _parseShops(dynamic response) {
    if (response is Map<String, dynamic>) {
      final List data = response['data'] ?? [];

      return data
          .map(
            (json) => ShopModel.fromJson(json),
          )
          .toList();
    }

    return [];
  }

  static String _buildQuery(
    Map<String, String> params,
  ) {
    if (params.isEmpty) return '';

    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    return '?$query';
  }

  /// Get shops based on category and user location.
  ///
  /// latitude / longitude are sent to backend.
  /// Backend is responsible for calculating distance
  /// and returning shops in nearest -> farthest order.
  static Future<List<ShopModel>> getShops({
    String? category,
    double? latitude,
    double? longitude,
  }) async {
    final params = <String, String>{};

    // -------------------------------------------------------------------------
    // CATEGORY
    // -------------------------------------------------------------------------

    if (category != null &&
        category.trim().isNotEmpty &&
        category.toLowerCase() != 'all') {
      params['category'] = category.toLowerCase();
    }

    // -------------------------------------------------------------------------
    // USER LOCATION
    // -------------------------------------------------------------------------

    if (latitude != null && longitude != null) {
      params['latitude'] = latitude.toString();
      params['longitude'] = longitude.toString();
    }

    final query = _buildQuery(params);

    final response =
        await ApiService.get(
      '/home/get-shops$query',
    );

    return _parseShops(response);
  }
}