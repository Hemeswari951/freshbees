
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// One row in the customer's bag — mirrors the JSON shape returned by
/// GET /api/customer/cart (see cart.controller.js → mapCartItem).
class CartItemModel {
  final int cartItemId;
  final int productId;
  final int? variantId;
  final String productName;
  final String thumbnail;
  final double price;
  final int quantity;
  final String? size;
  final int? stockQuantity;
  final double lineTotal;

  CartItemModel({
    required this.cartItemId,
    required this.productId,
    this.variantId,
    required this.productName,
    required this.thumbnail,
    required this.price,
    required this.quantity,
    this.size,
    this.stockQuantity,
    required this.lineTotal,
  });

 // Inside the file containing CartItemModel

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      cartItemId: int.tryParse(json['cartItemId'].toString()) ?? 0,
      productId: int.tryParse(json['productId'].toString()) ?? 0,
      variantId: json['variantId'] != null ? int.tryParse(json['variantId'].toString()) : null,
      productName: json['productName'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: int.tryParse(json['quantity'].toString()) ?? 1,
      size: json['size'] as String?,
      stockQuantity: json['stockQuantity'] != null ? int.tryParse(json['stockQuantity'].toString()) : null,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Bag contents + subtotal, as returned by GET /api/customer/cart.
class CartResult {
  final List<CartItemModel> items;
  final double subtotal;

  CartResult({required this.items, required this.subtotal});
}

/// Result of a successful checkout — enough to show the Order Success screen.
class CheckoutResult {
  final int orderId;
  final String paymentMethod;

  CheckoutResult({required this.orderId, required this.paymentMethod});
}

class CartService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiService.getAccessToken()}',
      };

  /// GET /api/customer/cart
  static Future<CartResult> getCart() async {
    final response = await http.get(
      Uri.parse('${ApiService.serverUrl}/api/customer/cart'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load bag');
    }

    final List rows = data['data']['items'] ?? [];
    return CartResult(
      items: rows.map((r) => CartItemModel.fromJson(r)).toList(),
      subtotal: (data['data']['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// POST /api/customer/cart  { product_id, variant_id?, quantity? }
  /// Used by the "ADD TO BAG" button on the product details screen.
  static Future<void> addToCart({
    required int productId,
    int? variantId,
    int quantity = 1,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.serverUrl}/api/customer/cart'),
      headers: _headers,
      body: jsonEncode({
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to add to bag');
    }
  }

  /// PUT /api/customer/cart/:id  { quantity }
  static Future<void> updateQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiService.serverUrl}/api/customer/cart/$cartItemId'),
      headers: _headers,
      body: jsonEncode({'quantity': quantity}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update quantity');
    }
  }

  /// DELETE /api/customer/cart/:id
  static Future<void> removeItem(int cartItemId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.serverUrl}/api/customer/cart/$cartItemId'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to remove item');
    }
  }

  /// POST /api/customer/orders/checkout  { cart_item_ids?, address_id, payment_method }
  /// "Buy Now" from the Payment screen (end of Cart → Address → Payment
  /// flow). Pass specific [cartItemIds] to check out only some of the bag,
  /// or leave null to check out everything.
  ///
  /// UPDATED: now requires [addressId] and [paymentMethod] (previously this
  /// silently checked out with no address and hardcoded "COD" server-side),
  /// and returns the created order id so the Order Success screen can show it.
  static Future<CheckoutResult> checkout({
    required int addressId,
    required String paymentMethod,
    List<int>? cartItemIds,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.serverUrl}/api/customer/orders/checkout'),
      headers: _headers,
      body: jsonEncode({
        if (cartItemIds != null) 'cart_item_ids': cartItemIds,
        'address_id': addressId,
        'payment_method': paymentMethod,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to place order');
    }

    return CheckoutResult(
      orderId: int.tryParse(data['order_id'].toString()) ?? 0,
      paymentMethod: data['payment_method']?.toString() ?? paymentMethod,
    );
  }
}

