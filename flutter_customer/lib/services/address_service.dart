
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

/// One saved delivery address — mirrors GET /api/customer/addresses
/// (see address.controller.js → mapAddress).
class AddressModel {
  final int addressId;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String country;
  final String pincode;
  final String addressType;
  final bool isDefault;

  AddressModel({
    required this.addressId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    required this.addressType,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      addressId: int.tryParse(json['addressId'].toString()) ?? 0,
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      addressLine1: json['addressLine1'] ?? '',
      addressLine2: json['addressLine2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? 'India',
      pincode: json['pincode'] ?? '',
      addressType: json['addressType'] ?? 'Home',
      isDefault: json['isDefault'] == true,
    );
  }

  /// "123 Main St, Near Park, Bengaluru, Karnataka - 560001"
  String get oneLine {
    final parts = [addressLine1, addressLine2, city, state]
        .where((p) => p.trim().isNotEmpty)
        .join(', ');
    return pincode.isNotEmpty ? '$parts - $pincode' : parts;
  }
}

class AddressService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${ApiService.getToken()}',
      };

  /// GET /api/customer/addresses
  static Future<List<AddressModel>> getAddresses() async {
    final response = await http.get(
      Uri.parse('${ApiService.serverUrl}/api/customer/addresses'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to load addresses');
    }

    final List rows = data['data'] ?? [];
    return rows.map((r) => AddressModel.fromJson(r)).toList();
  }

  /// POST /api/customer/addresses
  static Future<int> addAddress({
    required String fullName,
    required String phone,
    required String addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String country = 'India',
    required String pincode,
    String addressType = 'Home',
    bool isDefault = false,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.serverUrl}/api/customer/addresses'),
      headers: _headers,
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'country': country,
        'pincode': pincode,
        'address_type': addressType,
        'is_default': isDefault,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 201 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to add address');
    }
    return int.tryParse(data['address_id'].toString()) ?? 0;
  }

  /// PUT /api/customer/addresses/:id/default
  static Future<void> setDefault(int addressId) async {
    final response = await http.put(
      Uri.parse('${ApiService.serverUrl}/api/customer/addresses/$addressId/default'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to update default address');
    }
  }

  /// DELETE /api/customer/addresses/:id
  static Future<void> deleteAddress(int addressId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.serverUrl}/api/customer/addresses/$addressId'),
      headers: _headers,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to remove address');
    }
  }
}
