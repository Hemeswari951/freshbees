
class OrderModel {
  final int orderItemId;
  final int orderId;
  final int productId;
  final String productName;
  final int? variantId;
  final int quantity;
  final double price;
  final String itemStatus;
  final DateTime createdAt;
  final String customerName;
  final String? customerEmail;

  OrderModel({
    required this.orderItemId,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.variantId,
    required this.quantity,
    required this.price,
    required this.itemStatus,
    required this.createdAt,
    required this.customerName,
    this.customerEmail,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] ?? '';
    final lastName = json['last_name'] ?? '';

    return OrderModel(
      orderItemId: json['order_item_id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      productName: json['product_name'] ?? '',
      variantId: json['variant_id'],
      quantity: json['quantity'] is int
          ? json['quantity']
          : int.tryParse(json['quantity'].toString()) ?? 0,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      itemStatus: json['item_status'] ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now(),
      customerName: '$firstName $lastName'.trim(),
      customerEmail: json['email'],
    );
  }
}
