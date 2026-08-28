class OrderItemModel {
  final int orderItemId;
  final int? shopId;
  final int? productId;
  final int? variantId;
  final int quantity;
  final double price;
  final String itemStatus;

  final String? productName;
  final String? productImage;
  final String? shopName;

  final String? size;
  final String? colorName;
  final String? colorHex;

  OrderItemModel({
    required this.orderItemId,
    this.shopId,
    this.productId,
    this.variantId,
    required this.quantity,
    required this.price,
    required this.itemStatus,
    this.productName,
    this.productImage,
    this.shopName,
    this.size,
    this.colorName,
    this.colorHex,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      orderItemId: json['order_item_id'],
      shopId: json['shop_id'],
      productId: json['product_id'],
      variantId: json['variant_id'],
      quantity: json['quantity'] ?? 0,
      price: double.tryParse(
            json['item_price']?.toString() ?? '0',
          ) ??
          0,
      itemStatus: json['item_status'] ?? 'Processing',

      productName: json['product_name'],
      productImage: json['product_image'],
      shopName: json['shop_name'],

      size: json['variant_size'],
      colorName: json['color_name'],
      colorHex: json['color_hex'],
    );
  }
}


class OrderModel {
  final int orderId;
  final double totalAmount;

  final String? paymentMethod;
  final String? paymentStatus;
  final String? orderStatus;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? deliveryName;
  final String? deliveryPhone;
  final String? addressLine1;
  final String? addressLine2;
  final String? deliveryCity;
  final String? deliveryState;
  final String? deliveryCountry;
  final String? deliveryPincode;

  final List<OrderItemModel> items;

  OrderModel({
    required this.orderId,
    required this.totalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.orderStatus,
    this.createdAt,
    this.updatedAt,
    this.deliveryName,
    this.deliveryPhone,
    this.addressLine1,
    this.addressLine2,
    this.deliveryCity,
    this.deliveryState,
    this.deliveryCountry,
    this.deliveryPincode,
    required this.items,
  });

  factory OrderModel.fromRows(List<Map<String, dynamic>> rows) {
    final first = rows.first;

    return OrderModel(
      orderId: first['order_id'],
      totalAmount: double.tryParse(
            first['total_amount']?.toString() ?? '0',
          ) ??
          0,

      paymentMethod: first['payment_method'],
      paymentStatus: first['payment_status'],
      orderStatus: first['order_status'],

      createdAt: first['created_at'] != null
          ? DateTime.tryParse(first['created_at'].toString())
          : null,

      updatedAt: first['updated_at'] != null
          ? DateTime.tryParse(first['updated_at'].toString())
          : null,

      deliveryName: first['delivery_name'],
      deliveryPhone: first['delivery_phone'],
      addressLine1: first['address_line1'],
      addressLine2: first['address_line2'],
      deliveryCity: first['delivery_city'],
      deliveryState: first['delivery_state'],
      deliveryCountry: first['delivery_country'],
      deliveryPincode: first['delivery_pincode'],

      items: rows
          .where((row) => row['order_item_id'] != null)
          .map(OrderItemModel.fromJson)
          .toList(),
    );
  }
}