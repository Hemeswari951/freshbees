class ProductDetailsModel {
  final int id;
  final String productName;
  final String description;
  final String? subCategory;
  final String? fabric;
  final String? pattern;
  final String? fitType;
  final String? sleeveType;
  final String? neckType;
  final String? occasion;
  final String? washCare;
  final String? countryOfOrigin;
  final double price;
  final double? mrp;
  final int discountPercent;
  final String? thumbnail;
  final int shopId;
  final String shopName;
  final int categoryId;
  final String categoryName;
  final String? brandName;
  final int totalStock;
  final String stockStatus;
  final List<ProductColorModel> colors;
  final List<ProductAttributeModel> attributes;
  final List<ProductTagModel> tags;
  final List<ProductReviewModel> reviews;
  
  ProductDetailsModel({
    required this.id,
    required this.productName,
    required this.description,
    required this.subCategory,
    required this.fabric,
    required this.pattern,
    required this.fitType,
    required this.sleeveType,
    required this.neckType,
    required this.occasion,
    required this.washCare,
    required this.countryOfOrigin,
    required this.price,
    this.mrp,
    required this.discountPercent,
    this.thumbnail,
    required this.shopId,
    required this.shopName,
    required this.categoryId,
    required this.categoryName,
    this.brandName,
    required this.totalStock,
    required this.stockStatus,
    required this.colors,
    required this.attributes,
    required this.tags,
    required this.reviews,
    
  });

  factory ProductDetailsModel.fromJson(Map<String, dynamic> json) {
    return ProductDetailsModel(
      id: json["id"],
      productName: json["productName"],
      description: json["description"] ?? "",
      subCategory: json["subCategory"],

      fabric: json["fabric"],
      pattern: json["pattern"],
      fitType: json["fitType"],
      sleeveType: json["sleeveType"],
      neckType: json["neckType"],
      occasion: json["occasion"],
      washCare: json["washCare"],
      countryOfOrigin: json["countryOfOrigin"],
      price: (json["price"] as num).toDouble(),
      mrp: json["mrp"] == null ? null : (json["mrp"] as num).toDouble(),
      discountPercent: json["discountPercent"] ?? 0,
      thumbnail: json["thumbnail"] == null
          ? null
          : "http://localhost:3000${json["thumbnail"]}",
      shopId: json["shopId"],
      shopName: json["shopName"],
      categoryId: json["categoryId"],
      categoryName: json["categoryName"],
      brandName: json["brandName"],
      totalStock: json["totalStock"] ?? 0,
      stockStatus: json["stockStatus"] ?? "",
      colors: (json["colors"] as List)
    .map((e) => ProductColorModel.fromJson(e))
    .toList(),

    attributes: (json["attributes"] as List? ?? [])
    .map((e) => ProductAttributeModel.fromJson(e))
    .toList(),

tags: (json["tags"] as List? ?? [])
    .map((e) => ProductTagModel.fromJson(e))
    .toList(),

reviews: (json["reviews"] as List? ?? [])
    .map((e) => ProductReviewModel.fromJson(e))
    .toList(),

     
    );
  }
}

class ProductImageModel {
  final int imageId;
  final String imageUrl;
  final String imageType;

  ProductImageModel({
    required this.imageId,
    required this.imageUrl,
    required this.imageType,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      imageId: json["imageId"],
      imageUrl: "http://localhost:3000${json["imageUrl"]}",
      imageType: json["imageType"],
    );
  }
}

class ProductColorModel {
  final int productColorId;
  final String colorName;
  final String? colorHex;
  final List<ProductImageModel> images;
  final List<ProductVariantModel> variants;

  ProductColorModel({
    required this.productColorId,
    required this.colorName,
    this.colorHex,
    required this.images,
    required this.variants,
  });

  factory ProductColorModel.fromJson(Map<String, dynamic> json) {
    return ProductColorModel(
      productColorId: json["productColorId"],
      colorName: json["colorName"],
      colorHex: json["colorHex"],
      images: (json["images"] as List)
          .map((e) => ProductImageModel.fromJson(e))
          .toList(),
      variants: (json["variants"] as List? ?? [])
    .map((e) => ProductVariantModel.fromJson(e))
    .toList(),
    );
  }
}

class ProductVariantModel {
  final int variantId;
  final int? productColorId;
  final double? price;
  final double? mrp;
  final String size;
  final int stockQuantity;

  ProductVariantModel({
    required this.variantId,
    this.productColorId,
    required this.price,
    required this.mrp,
    required this.size,
    required this.stockQuantity,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      variantId: json["variantId"],
      productColorId: json["productColorId"] as int?,
      price: json["price"] == null
    ? null
    : (json["price"] as num).toDouble(),

mrp: json["mrp"] == null
    ? null
    : (json["mrp"] as num).toDouble(),
      size: json["size"],
      stockQuantity: json["stockQuantity"],
    );
  }
}

class ProductAttributeModel {
  final int attributeId;
  final String label;
  final String value;
  final int displayOrder;

  ProductAttributeModel({
    required this.attributeId,
    required this.label,
    required this.value,
    required this.displayOrder,
  });

  factory ProductAttributeModel.fromJson(Map<String, dynamic> json) {
    return ProductAttributeModel(
      attributeId: json["attributeId"] ?? 0,
      label: json["label"] ?? "",
      value: json["value"] ?? "",
      displayOrder: json["displayOrder"] ?? 0,
    );
  }
}

class ProductTagModel {
  final int tagId;
  final String tagName;

  ProductTagModel({
    required this.tagId,
    required this.tagName,
  });

  factory ProductTagModel.fromJson(Map<String, dynamic> json) {
    return ProductTagModel(
      tagId: json["tagId"] ?? 0,
      tagName: json["tagName"] ?? "",
    );
  }
}

class ProductReviewModel {
  final int reviewId;
  final int customerId;
  final int rating;
  final String reviewText;
  final DateTime createdAt;

  ProductReviewModel({
    required this.reviewId,
    required this.customerId,
    required this.rating,
    required this.reviewText,
    required this.createdAt,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      reviewId: json["reviewId"] ?? 0,
      customerId: json["customerId"] ?? 0,
      rating: json["rating"] ?? 0,
      reviewText: json["reviewText"] ?? "",
      createdAt: DateTime.parse(json["createdAt"]),
    );
  }
}