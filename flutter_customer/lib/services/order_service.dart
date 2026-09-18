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

  /// GET /api/customer/orders/:orderId
  /// Single order with all its items — used by the Order Details screen.
  static Future<OrderModel> getOrderById(int orderId) async {
    final token = ApiService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login to view your orders');
    }

    final response = await http.get(
      Uri.parse('${ApiService.serverUrl}/api/customer/orders/$orderId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to load order');
    }

    final List<dynamic> data = decoded['data'] ?? [];

    final rows = data.map((row) => Map<String, dynamic>.from(row)).toList();

    return OrderModel.fromRows(rows);
  }

  /// GET /api/customer/orders/items/cancel-reasons
  /// The preset reasons shown in the cancel sheet (last one is always
  /// "Other", which opens a free-text field instead of being sent as-is).
  static Future<List<String>> getCancelReasons() async {
    final token = ApiService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue');
    }

    final response = await http.get(
      Uri.parse('${ApiService.serverUrl}/api/customer/orders/items/cancel-reasons'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to load cancellation reasons');
    }

    return (decoded['data'] as List).map((e) => e.toString()).toList();
  }

  /// PUT /api/customer/orders/items/:itemId/cancel   body: { reason, customReason? }
  /// Only succeeds while the item is still 'Pending'.
  ///
  /// [reason] must be one of the strings returned by [getCancelReasons].
  /// When it's 'Other', pass the customer's own text in [customReason] —
  /// that's what actually gets stored against the item.
  static Future<void> cancelOrderItem(
    int orderItemId, {
    required String reason,
    String? customReason,
  }) async {
    final token = ApiService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login to continue');
    }

    final response = await http.put(
      Uri.parse(
        '${ApiService.serverUrl}/api/customer/orders/items/$orderItemId/cancel',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'reason': reason,
        if (customReason != null) 'customReason': customReason,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200 || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Failed to cancel item');
    }
  }
}