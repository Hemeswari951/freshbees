import '../models/shop_model.dart';
import 'api_service.dart';

class ShopOverviewService {
  ShopOverviewService._();

  /// TODO: path already matches the backend route above
  /// (/home/shop-detail/:id) — change if you mount it elsewhere.
  static Future<ShopModel> getShopById(int shopId) async {
  final response = await ApiService.get('/shops/$shopId');

  if (response['data'] != null) {
    return ShopModel.fromJson(
      response['data'] as Map<String, dynamic>,
    );
  }

  throw Exception('Shop not found');
}
}