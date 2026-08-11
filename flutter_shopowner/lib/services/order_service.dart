import '../models/order_model.dart';
import 'api_service.dart';

class OrderService {
  OrderService._();

  static Future<List<OrderModel>> getOrders() async {
    final response = await ApiService.get('/orders');

    if (response is Map<String, dynamic>) {
      final List data = response['data'] ?? [];
      return data.map((json) => OrderModel.fromJson(json)).toList();
    }

    return [];
  }
}
