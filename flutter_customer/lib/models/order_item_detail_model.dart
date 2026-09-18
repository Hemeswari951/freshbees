class OrderAddressModel {
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String country;

  OrderAddressModel({
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.country,
  });

  factory OrderAddressModel.fromJson(Map<String, dynamic> json) {
    return OrderAddressModel(
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      country: json['country'] ?? '',
    );
  }

  String get oneLine {
    final parts = [addressLine1, addressLine2, city, state, pincode, country]
        .where((p) => p != null && p.trim().isNotEmpty)
        .join(', ');
    return parts;
  }
}

class OrderItemDetailModel {
  final int orderId;
  final int orderItemId;
  final int productId;
  final String productName;
  final String? variantSize;
  final int quantity;
  final double price;
  final String thumbnail;
  final String itemStatus;
  final DateTime itemCreatedAt;
  final DateTime itemUpdatedAt;

  final int shopId;
  final String shopName;

  final double totalAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? orderStatus;
  final DateTime orderCreatedAt;

  final OrderAddressModel? address;

  OrderItemDetailModel({
    required this.orderId,
    required this.orderItemId,
    required this.productId,
    required this.productName,
    this.variantSize,
    required this.quantity,
    required this.price,
    required this.thumbnail,
    required this.itemStatus,
    required this.itemCreatedAt,
    required this.itemUpdatedAt,
    required this.shopId,
    required this.shopName,
    required this.totalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.orderStatus,
    required this.orderCreatedAt,
    this.address,
  });

  factory OrderItemDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderItemDetailModel(
      orderId: json['orderId'],
      orderItemId: json['orderItemId'],
      productId: json['productId'],
      productName: json['productName'] ?? '',
      variantSize: json['variantSize'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      thumbnail: json['thumbnail'] ?? '',
      itemStatus: json['itemStatus'] ?? 'Processing',
      itemCreatedAt: DateTime.parse(json['itemCreatedAt']),
      itemUpdatedAt: DateTime.parse(json['itemUpdatedAt']),
      shopId: json['shopId'],
      shopName: json['shopName'] ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      orderStatus: json['orderStatus'],
      orderCreatedAt: DateTime.parse(json['orderCreatedAt']),
      address: json['address'] != null ? OrderAddressModel.fromJson(json['address']) : null,
    );
  }
}