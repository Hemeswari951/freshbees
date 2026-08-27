import 'dart:convert';
import 'package:http/http.dart' as http;

import 'api_service.dart';
import '../models/order_model.dart';

class OrderService {
  static Future<List<OrderModel>> getMyOrders() async {
    final token = ApiService.getAccessToken();

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