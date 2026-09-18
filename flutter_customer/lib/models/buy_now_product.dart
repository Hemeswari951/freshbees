class BuyNowProduct {
  final int productId;
  final int? variantId;
  int quantity;
  final String productName;
  final String? thumbnail;
  final double price;
  final double? mrp;
  final String? size;
  final int? stockQuantity;
  final double? rating;       // NEW
  final int? reviewCount;     // NEW

  BuyNowProduct({
    required this.productId,
    this.variantId,
    this.quantity = 1,
    required this.productName,
    this.thumbnail,
    required this.price,
    this.mrp,
    this.size,
    this.stockQuantity,
    this.rating,
    this.reviewCount,
  });

  double get lineTotal => price * quantity;
  double get mrpLineTotal => (mrp ?? price) * quantity;
}