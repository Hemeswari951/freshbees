import 'api_service.dart';

/// One row in the customer's bag
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

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      cartItemId: int.tryParse(
            json['cartItemId']?.toString() ?? '',
          ) ??
          0,

      productId: int.tryParse(
            json['productId']?.toString() ?? '',
          ) ??
          0,

      variantId: json['variantId'] != null
          ? int.tryParse(json['variantId'].toString())
          : null,

      productName: json['productName']?.toString() ?? '',

      thumbnail: json['thumbnail']?.toString() ?? '',

      price: json['price'] is num
          ? (json['price'] as num).toDouble()
          : double.tryParse(
                json['price']?.toString() ?? '',
              ) ??
              0.0,

      quantity: int.tryParse(
            json['quantity']?.toString() ?? '',
          ) ??
          1,

      size: json['size']?.toString(),

      stockQuantity: json['stockQuantity'] != null
          ? int.tryParse(
              json['stockQuantity'].toString(),
            )
          : null,

      lineTotal: json['lineTotal'] is num
          ? (json['lineTotal'] as num).toDouble()
          : double.tryParse(
                json['lineTotal']?.toString() ?? '',
              ) ??
              0.0,
    );
  }
}

/// Bag contents + subtotal
class CartResult {
  final List<CartItemModel> items;
  final double subtotal;

  CartResult({
    required this.items,
    required this.subtotal,
  });
}

/// Result of successful checkout
class CheckoutResult {
  final int orderId;
  final String paymentMethod;

  CheckoutResult({
    required this.orderId,
    required this.paymentMethod,
  });
}

class CartService {
  // ============================================================
  // GET CART
  // ============================================================

  static Future<CartResult> getCart() async {
    final response = await ApiService.get('/cart');

    final List rows = response['data']?['items'] ?? [];

    return CartResult(
      items: rows
          .map(
            (r) => CartItemModel.fromJson(
              Map<String, dynamic>.from(r),
            ),
          )
          .toList(),

      subtotal: response['data']?['subtotal'] is num
          ? (response['data']['subtotal'] as num).toDouble()
          : double.tryParse(
                response['data']?['subtotal']?.toString() ?? '',
              ) ??
              0.0,
    );
  }

  // ============================================================
  // ADD TO CART
  // ============================================================

  static Future<void> addToCart({
    required int productId,
    int? variantId,
    int quantity = 1,
  }) async {
    final response = await ApiService.post(
      '/cart',
      {
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
      },
    );

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to add to bag',
      );
    }
  }

  // ============================================================
  // UPDATE QUANTITY
  // ============================================================

  static Future<void> updateQuantity({
    required int cartItemId,
    required int quantity,
  }) async {
    final response = await ApiService.put(
      '/cart/$cartItemId',
      {
        'quantity': quantity,
      },
    );

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to update quantity',
      );
    }
  }

  // ============================================================
  // REMOVE ITEM
  // ============================================================

  static Future<void> removeItem(
    int cartItemId,
  ) async {
    final response = await ApiService.delete(
      '/cart/$cartItemId',
    );

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to remove item',
      );
    }
  }

  // ============================================================
  // CHECKOUT
  // ============================================================

  static Future<CheckoutResult> checkout({
    required int addressId,
    required String paymentMethod,
    List<int>? cartItemIds,
  }) async {
    final response = await ApiService.post(
      '/orders/checkout',
      {
        if (cartItemIds != null)
          'cart_item_ids': cartItemIds,

        'address_id': addressId,

        'payment_method': paymentMethod,
      },
    );

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to place order',
      );
    }

    return CheckoutResult(
      orderId: int.tryParse(
            response['order_id']?.toString() ?? '',
          ) ??
          0,

      paymentMethod:
          response['payment_method']?.toString() ??
              paymentMethod,
    );
  }
}