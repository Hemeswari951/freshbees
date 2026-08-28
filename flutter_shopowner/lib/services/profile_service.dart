import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class BankDetails {
  final String? accountNumber;
  final String? accountHolderName;
  final String? bankName;
  final String? ifscCode;
  final String? gstNumber;

  BankDetails({
    this.accountNumber,
    this.accountHolderName,
    this.bankName,
    this.ifscCode,
    this.gstNumber,
  });

  factory BankDetails.fromJson(Map<String, dynamic> j) => BankDetails(
    accountNumber: j['accountNumber'] as String?,
    accountHolderName: j['accountHolderName'] as String?,
    bankName: j['bankName'] as String?,
    ifscCode: j['ifscCode'] as String?,
    gstNumber: j['gstNumber'] as String?,
  );
}

class ShopProfile {
  final int id;
  final String shopName;
  final String ownerName;
  final String? logoUrl;
  final String? bannerUrl;
  final String? description;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? email;
  final String? phoneNumber;
  final DateTime? ownerLastLogin;
  final DateTime? createdAt;
  final List<String> categories;
  final BankDetails? bankDetails;
  final int productsCount;
  final int ordersCount;
  final double avgRating;
  final int reviewCount;

  ShopProfile({
    required this.id,
    required this.shopName,
    required this.ownerName,
    this.logoUrl,
    this.bannerUrl,
    this.description,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.email,
    this.phoneNumber,
    this.ownerLastLogin,
    this.createdAt,
    this.categories = const [],
    this.bankDetails,
    required this.productsCount,
    required this.ordersCount,
    required this.avgRating,
    required this.reviewCount,
  });

  factory ShopProfile.fromJson(Map<String, dynamic> j) => ShopProfile(
    id: j['id'] as int,
    shopName: (j['shopName'] ?? '') as String,
    ownerName: (j['ownerName'] ?? '') as String,
    logoUrl: j['logoUrl'] as String?,
    bannerUrl: j['bannerUrl'] as String?,
    description: j['description'] as String?,
    address: j['address'] as String?,
    city: j['city'] as String?,
    state: j['state'] as String?,
    pincode: j['pincode'] as String?,
    email: j['email'] as String?,
    phoneNumber: j['phoneNumber'] as String?,
    ownerLastLogin: j['ownerLastLogin'] != null
        ? DateTime.tryParse(j['ownerLastLogin'].toString())
        : null,
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'].toString())
        : null,
    categories: j['categories'] != null
        ? List<String>.from(j['categories'] as List)
        : const [],
    bankDetails: j['bankDetails'] != null
        ? BankDetails.fromJson(
            Map<String, dynamic>.from(j['bankDetails'] as Map),
          )
        : null,
    productsCount: (j['productsCount'] as num?)?.toInt() ?? 0,
    ordersCount: (j['ordersCount'] as num?)?.toInt() ?? 0,
    avgRating: (j['avgRating'] as num?)?.toDouble() ?? 0.0,
    reviewCount: (j['reviewCount'] as num?)?.toInt() ?? 0,
  );

  String get initial =>
      shopName.trim().isNotEmpty ? shopName.trim()[0].toUpperCase() : '?';

  String get location {
    final parts = [city, state].where((s) => s != null && s.isNotEmpty);
    return parts.isEmpty ? '-' : parts.join(', ');
  }
}

class ShopReview {
  final int id;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;
  final String customerName;
  final int productId;
  final String productName;

  ShopReview({
    required this.id,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.customerName,
    required this.productId,
    required this.productName,
  });

  factory ShopReview.fromJson(Map<String, dynamic> j) => ShopReview(
    id: j['id'] as int,
    rating: (j['rating'] as num).toInt(),
    reviewText: j['reviewText'] as String?,
    createdAt: DateTime.parse(j['createdAt'] as String),
    customerName: (j['customerName'] ?? 'Customer') as String,
    productId: j['productId'] as int,
    productName: (j['productName'] ?? '') as String,
  );
}

class ProfileService {
  ProfileService._();

  static String fullImageUrl(String relativePath) {
    if (relativePath.startsWith('http://') ||
        relativePath.startsWith('https://')) {
      return relativePath;
    }
    return '${ApiService.serverUrl}$relativePath';
  }

  static Future<ShopProfile> getProfile() async {
    final response = await ApiService.get('/profile');
    return ShopProfile.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  static Future<ShopProfile> updateProfile({
    String? shopName,
    String? ownerName,
    String? description,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? email,
    String? phoneNumber,
    XFile? logo,
    XFile? banner,
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiService.baseUrl}/profile'),
    );

    final token = ApiService.getToken();
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (shopName != null) request.fields['shopName'] = shopName;
    if (ownerName != null) request.fields['ownerName'] = ownerName;
    if (description != null) request.fields['description'] = description;
    if (address != null) request.fields['address'] = address;
    if (city != null) request.fields['city'] = city;
    if (state != null) request.fields['state'] = state;
    if (pincode != null) request.fields['pincode'] = pincode;
    if (email != null) request.fields['email'] = email;
    if (phoneNumber != null) request.fields['phoneNumber'] = phoneNumber;

    if (logo != null) {
      final bytes = await logo.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('logo', bytes, filename: logo.name),
      );
    }
    if (banner != null) {
      final bytes = await banner.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('banner', bytes, filename: banner.name),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200) {
      return ShopProfile.fromJson(
        Map<String, dynamic>.from(body['data'] as Map),
      );
    }

    throw Exception(
      body['message'] ?? 'Failed to update profile (${response.statusCode})',
    );
  }

  static Future<List<ShopReview>> getReviews({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.get('/reviews?page=$page&limit=$limit');
    final List list = response['data'] as List;
    return list
        .map((e) => ShopReview.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
