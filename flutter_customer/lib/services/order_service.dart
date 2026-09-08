import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import '../models/order_model.dart';

/// Result of a successful "Buy Now" order (POST /orders/buy-now).
class BuyNowResult {
  final int orderId;
  final String paymentMethod;

  BuyNowResult({required this.orderId, required this.paymentMethod});
}

class OrderService {
  /// POST /api/customer/orders/buy-now
  /// Places a single-item order directly (Address -> Order Summary ->
  /// Payment), completely bypassing the cart — nothing is added to or
  /// removed from cart_items.
  static Future<BuyNowResult> buyNow({
    required int productId,
    int? variantId,
    required int quantity,
    required int addressId,
    required String paymentMethod,
  }) async {
    final token = ApiService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue');
    }

    final response = await http.post(
      Uri.parse('${ApiService.serverUrl}/api/customer/orders/buy-now'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'product_id': productId,
        if (variantId != null) 'variant_id': variantId,
        'quantity': quantity,
        'address_id': addressId,
        'payment_method': paymentMethod,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 201 || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to place order');
    }

    return BuyNowResult(
      orderId: int.tryParse(decoded['order_id']?.toString() ?? '') ?? 0,
      paymentMethod: decoded['payment_method']?.toString() ?? paymentMethod,
    );
  }

  static Future<List<OrderModel>> getMyOrders() async {
    final token = ApiService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login to view your orders');
    }

    final response = await http.get(
      Uri.parse('${ApiService.serverUrl}/api/customer/orders'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('GET ORDERS STATUS: ${response.statusCode}');
    print('GET ORDERS BODY: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to load orders');
    }

    final decoded = jsonDecode(response.body);

    if (decoded['success'] != true) {
      throw Exception(
        decoded['message'] ?? 'Failed to load orders',
      );
    }

    final List<dynamic> data = decoded['data'] ?? [];

    final Map<int, List<Map<String, dynamic>>> grouped = {};

    for (final row in data) {
      final map = Map<String, dynamic>.from(row);

      final orderId = map['order_id'];

      if (orderId == null) continue;

      grouped.putIfAbsent(orderId, () => []);
      grouped[orderId]!.add(map);
    }

    return grouped.values
        .map((rows) => OrderModel.fromRows(rows))
        .toList();
  }
}