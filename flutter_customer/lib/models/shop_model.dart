import '../services/api_service.dart';

class ShopModel {
  final int id;
  final String shopName;

  final String? description;

  final String? shopLogo;
  final String? shopBanner;

  final List<String> categories;

  final String? city;
  final String? state;
  final String? address;

  final String? phone; // ADDED PHONE PROPERTY

  final double rating;
  final int ratingCount;

  final String status;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final String? ownerProfileImage;

  ShopModel({
    required this.id,
    required this.shopName,
    this.description,
    this.shopLogo,
    this.shopBanner,
    this.categories = const [],
    this.city,
    this.state,
    this.address,
    this.phone, // ADDED TO CONSTRUCTOR
    this.rating = 0.0,
    this.ratingCount = 0,
    this.status = 'Active',
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    this.ownerProfileImage,
  });

  // ==============================================================
  // FROM JSON
  // ==============================================================

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    // --------------------------------------------------------------
    // Categories
    // --------------------------------------------------------------

    List<String> parsedCategories = [];

    if (json['categories'] is List) {
      parsedCategories = (json['categories'] as List)
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      final String? category = json['category']?.toString();
      final String? categoryLabel = json['categoryLabel']?.toString();

      if (category != null && category.isNotEmpty) {
        parsedCategories = [category];
      } else if (categoryLabel != null && categoryLabel.isNotEmpty) {
        parsedCategories = [categoryLabel];
      }
    }

    // --------------------------------------------------------------
    // Rating
    // --------------------------------------------------------------

    double parsedRating = 0.0;

    if (json['rating'] is num) {
      parsedRating = (json['rating'] as num).toDouble();
    } else {
      parsedRating = double.tryParse(json['rating']?.toString() ?? '') ?? 0.0;
    }

    // --------------------------------------------------------------
    // Rating Count
    // --------------------------------------------------------------

    int parsedRatingCount = 0;

    if (json['ratingCount'] is num) {
      parsedRatingCount = (json['ratingCount'] as num).toInt();
    } else if (json['rating_count'] is num) {
      parsedRatingCount = (json['rating_count'] as num).toInt();
    } else {
      parsedRatingCount =
          int.tryParse(
            (json['ratingCount'] ?? json['rating_count'] ?? '0').toString(),
          ) ??
          0;
    }

    return ShopModel(
      id: json['id'] ?? json['shop_id'] ?? 0,
      shopName: (json['shopName'] ?? json['shop_name'] ?? '').toString(),
      description: json['description']?.toString(),
      shopLogo: (json['logoUrl'] ?? json['shopLogo'] ?? json['shop_logo'])
          ?.toString(),
      shopBanner:
          (json['shopBanner'] ?? json['bannerUrl'] ?? json['shop_banner'])
              ?.toString(),
      categories: parsedCategories,
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      address: json['address']?.toString(),

      // PARSE PHONE NUMBER FROM MULTIPLE POSSIBLE KEYS
      phone: (json['phone'] ?? json['shop_phone'] ?? json['contact'])
          ?.toString(),

      rating: parsedRating,
      ratingCount: parsedRatingCount,
      status: (json['status'] ?? 'Active').toString(),
      ownerName: json['ownerName']?.toString(),
      ownerEmail: json['ownerEmail']?.toString(),
      ownerPhone: json['ownerPhone']?.toString(),
      ownerProfileImage: json['ownerProfileImage']?.toString(),
    );
  }

  // ==============================================================
  // CATEGORY LABEL
  // ==============================================================

  String get categoryLabel {
    if (categories.isNotEmpty) {
      return categories.join(', ');
    }
    return 'Shop';
  }

  // ==============================================================
  // LOCATION LABEL
  // ==============================================================

  String get locationLabel {
    if (city != null && city!.isNotEmpty) {
      if (state != null && state!.isNotEmpty) {
        return '$city, $state';
      }
      return city!;
    }
    return address ?? '';
  }

  // ==============================================================
  // LOGO URL
  // ==============================================================

  String? get logoUrl {
    if (shopLogo == null || shopLogo!.isEmpty) {
      return null;
    }
    if (shopLogo!.startsWith('http://') || shopLogo!.startsWith('https://')) {
      return shopLogo;
    }
    return '${ApiService.serverUrl}$shopLogo';
  }

  // ==============================================================
  // BANNER URL
  // ==============================================================

  String? get bannerUrl {
    if (shopBanner == null || shopBanner!.isEmpty) {
      return null;
    }
    if (shopBanner!.startsWith('http://') ||
        shopBanner!.startsWith('https://')) {
      return shopBanner;
    }
    return '${ApiService.serverUrl}$shopBanner';
  }

  // ==============================================================
  // ACTIVE STATUS
  // ==============================================================

  bool get isActive {
    return status.toLowerCase() == 'active';
  }
}
