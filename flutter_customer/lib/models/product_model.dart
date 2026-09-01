class ProductModel {
  final int id;
  final String productName;
  final String description;

  final double price;
  final double? mrp;
  final int discountPercent;

  final String thumbnail;

  final int shopId;
  final String shopName;

  final int categoryId;
  final String categoryName;
  final String subCategory;

  final String brandName;

  final int totalStock;
  final String stockStatus;

  // NEW — needed for filtering
  final List<String> sizes;
  final List<String> colors;
  final double rating;

  // NEW — how many customers have rated this product. Backend derives
  // this from the `reviews` table (there is no stored count column on
  // `products`), so it's always 0 until at least one review exists.
  final int reviewCount;

  ProductModel({
    required this.id,
    required this.productName,
    required this.description,
    required this.price,
    this.mrp,
    required this.discountPercent,
    required this.thumbnail,
    required this.shopId,
    required this.shopName,
    required this.categoryId,
    required this.categoryName,
    required this.subCategory,
    required this.brandName,
    required this.totalStock,
    required this.stockStatus,
    this.sizes = const [],
    this.colors = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] ?? 0,
      productName: json['productName'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      mrp: json['mrp'] != null ? (json['mrp'] as num).toDouble() : null,
      discountPercent: json['discountPercent'] ?? 0,
      thumbnail: json['thumbnail'] ?? '',
      shopId: json['shopId'] ?? 0,
      shopName: json['shopName'] ?? '',
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      subCategory: json['subCategory'] ?? '',
      brandName: json['brandName'] ?? '',
      totalStock: json['totalStock'] ?? 0,
      stockStatus: json['stockStatus'] ?? '',
      sizes: (json['sizes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      colors: (json['colors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productName': productName,
      'description': description,
      'price': price,
      'mrp': mrp,
      'discountPercent': discountPercent,
      'thumbnail': thumbnail,
      'shopId': shopId,
      'shopName': shopName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'subCategory': subCategory,
      'brandName': brandName,
      'totalStock': totalStock,
      'stockStatus': stockStatus,
      'sizes': sizes,
      'colors': colors,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }
}