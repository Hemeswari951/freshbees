import 'api_service.dart';
import 'cart_count.dart';

/// One row in the customer's bag
/// One row in the customer's bag
class CartItemModel {
  final int cartItemId;
  final int productId;
  final int? variantId;
  final String productName;
  final String? shopName;
  final String thumbnail;
  final double price;
  final double? mrp;
  final int quantity;
  final String? size;
  final String? color;
  final int? stockQuantity;
  final double lineTotal;
  final double? rating;       // NEW — avg rating from reviews table, null if no reviews
  final int? reviewCount;     // NEW — total review count

  CartItemModel({
    required this.cartItemId,
    required this.productId,
    this.variantId,
    required this.productName,
    this.shopName,
    required this.thumbnail,
    required this.price,
    this.mrp,
    required this.quantity,
    this.size,
    this.color,
    this.stockQuantity,
    required this.lineTotal,
    this.rating,
    this.reviewCount,
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

      shopName: json['shopName']?.toString(),

      thumbnail: json['thumbnail']?.toString() ?? '',

      mrp: json['mrp'] == null
          ? null
          : (json['mrp'] is num
              ? (json['mrp'] as num).toDouble()
              : double.tryParse(json['mrp'].toString())),

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
      color: json['color']?.toString(),

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

      // NEW — backend sends `rating: null` when no reviews, so no fallback needed
      rating: json['rating'] == null
          ? null
          : (json['rating'] is num
              ? (json['rating'] as num).toDouble()
              : double.tryParse(json['rating'].toString())),

      reviewCount: json['reviewCount'] != null
          ? int.tryParse(json['reviewCount'].toString())
          : null,
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

  final items = rows
      .map(
        (r) => CartItemModel.fromJson(
          Map<String, dynamic>.from(r),
        ),
      )
      .toList();

  cartItemCount.value = items.length;   // ← ADD THIS — keeps badge in sync

  return CartResult(
    items: items,
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

 // ============================================================
// ADD TO CART
// ============================================================

/// Returns the cartItemId of the row that was created/updated, if the
/// backend sends it back. Callers that don't need it (e.g. the plain
/// "Add to Cart" button) can just ignore the return value.
static Future<int?> addToCart({
  required int productId,
  int? variantId,
  int quantity = 1,
  String? size,
  String? color,
}) async {
  final response = await ApiService.post(
    '/cart',
    {
      'product_id': productId,
      'variant_id': variantId,
      'quantity': quantity,
      if (size != null) 'size': size,
      if (color != null) 'color': color,
    },
  );

  if (response['success'] != true) {
    throw Exception(
      response['message'] ?? 'Failed to add to bag',
    );
  }

  cartItemCount.value = cartItemCount.value + 1;   // ← ADD THIS LINE

  final data = response['data'];
  final rawId = data is Map
      ? (data['cartItemId'] ?? data['cart_item_id'] ?? data['id'])
      : (response['cartItemId'] ?? response['cart_item_id']);

  if (rawId != null) {
    return int.tryParse(rawId.toString());
  }
  return null;
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

  if (cartItemCount.value > 0) {
    cartItemCount.value = cartItemCount.value - 1;   // ← ADD THIS
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