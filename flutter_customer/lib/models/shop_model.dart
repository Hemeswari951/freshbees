 
import '../services/api_service.dart';
 
/// Represents a shop as shown to the customer (nearby shops, shop list,
/// shop detail). Built to be tolerant of both camelCase and snake_case
/// keys, since different backend endpoints may serialize fields
/// differently (this mirrors how the admin app reads shop data).
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
  final double rating;
  final String status; // Active / Blocked / Pending
 
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
    this.rating = 0.0,
    this.status = 'Active',
  });
 
  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] ?? json['shop_id'] ?? 0,
      shopName: (json['shopName'] ?? json['shop_name'] ?? '').toString(),
      description: json['description']?.toString(),
      shopLogo: (json['shopLogo'] ?? json['shop_logo'])?.toString(),
      shopBanner: (json['shopBanner'] ?? json['shop_banner'])?.toString(),
      categories: json['categories'] is List
          ? (json['categories'] as List).map((e) => e.toString()).toList()
          : <String>[],
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      address: json['address']?.toString(),
      rating: json['rating'] is num
          ? (json['rating'] as num).toDouble()
          : double.tryParse(json['rating']?.toString() ?? '') ?? 0.0,
      status: (json['status'] ?? 'Active').toString(),
    );
  }
 
  /// "Boutique, Men" style subtitle used under the shop name on cards.
  String get categoryLabel =>
      categories.isNotEmpty ? categories.join(', ') : 'Shop';
 
  /// "Hariprasad · Kurnool" style location line.
  String get locationLabel {
    if (city != null && city!.isNotEmpty) {
      return state != null && state!.isNotEmpty ? '$city, $state' : city!;
    }
    return address ?? '';
  }
 
  /// Full URL for the shop logo, ready to hand to Image.network.
  String? get logoUrl =>
      (shopLogo != null && shopLogo!.isNotEmpty)
          ? '${ApiService.serverUrl}$shopLogo'
          : null;
 
  bool get isActive => status.toLowerCase() == 'active';
}