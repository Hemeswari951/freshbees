import '../models/order_item_detail_model.dart';
import 'api_service.dart';

class OrderItemDetailService {
  OrderItemDetailService._();

  static Future<OrderItemDetailModel> getOrderItemDetail(int orderItemId) async {
    final response = await ApiService.get('/orders/items/$orderItemId');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return OrderItemDetailModel.fromJson(response['data']);
    }
    throw Exception('Failed to load order details');
  }
}