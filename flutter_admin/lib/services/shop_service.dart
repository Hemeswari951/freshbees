import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class ShopService {
  // ─────────────────────────────────────────────────────────────────────────
  // GET ALL SHOPS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllShops() async {
    final res = await ApiService.get('/shops');

    return List<Map<String, dynamic>>.from(
      res['data'],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // GET SINGLE SHOP
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getShopDetail(
    int shopId,
  ) async {
    final res = await ApiService.get(
      '/shops/$shopId',
    );

    return Map<String, dynamic>.from(
      res['data'],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE SHOP STATUS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> updateShopStatus(
    int shopId,
    String status, {
    String? reason,
  }) async {
    await ApiService.patch(
      '/shops/$shopId/status',
      {
        'status': status,
        'reason': reason,
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // CREATE SHOP
  // ─────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createShop({
    // ── Step 1 — Basic ─────────────────────────────────────────────────────

    required String shopName,
    required String description,
    required List<int> categoryIds,
    required String address,
    required String city,
    required String state,
    required String pincode,

    // Location
    String? locationUrl,
    double? latitude,
    double? longitude,

    // Images
    XFile? logoFile,
    XFile? bannerFile,

    // ── Step 2 — Owner ─────────────────────────────────────────────────────

    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,

    // ── Step 3 — Bank ──────────────────────────────────────────────────────

    required String accountNumber,
    required String bankName,
    required String ifscCode,
    String? gstNumber,

    // ── Step 4 — Settings ──────────────────────────────────────────────────

    required String commissionRate,
    required bool activateImmediately,
    required bool sendWelcomeEmail,
    required bool allowProductUploads,
    required bool enablePayoutRequests,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/shops',
    );

    final token = ApiService.getToken();

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    // ── Authorization ──────────────────────────────────────────────────────

    request.headers['Authorization'] =
        'Bearer $token';

    // ── Step 1 — Basic ─────────────────────────────────────────────────────

    request.fields['shopName'] = shopName;
    request.fields['description'] = description;
    request.fields['categoryIds'] =
        jsonEncode(categoryIds);
    request.fields['address'] = address;
    request.fields['city'] = city;
    request.fields['state'] = state;
    request.fields['pincode'] = pincode;

    // ── Location ────────────────────────────────────────────────────────────

    request.fields['locationUrl'] =
        locationUrl ?? '';

    request.fields['latitude'] =
        latitude?.toString() ?? '';

    request.fields['longitude'] =
        longitude?.toString() ?? '';

    // ── Step 2 — Owner ─────────────────────────────────────────────────────

    request.fields['ownerName'] = ownerName;
    request.fields['ownerEmail'] = ownerEmail;
    request.fields['ownerPhone'] = ownerPhone;

    // ── Step 3 — Bank ──────────────────────────────────────────────────────

    request.fields['accountNumber'] =
        accountNumber;

    request.fields['bankName'] = bankName;

    request.fields['ifscCode'] = ifscCode;

    request.fields['gstNumber'] =
        gstNumber ?? '';

    // ── Step 4 — Settings ──────────────────────────────────────────────────

    request.fields['commissionRate'] =
        commissionRate;

    request.fields['activateImmediately'] =
        activateImmediately.toString();

    request.fields['sendWelcomeEmail'] =
        sendWelcomeEmail.toString();

    request.fields['allowProductUploads'] =
        allowProductUploads.toString();

    request.fields['enablePayoutRequests'] =
        enablePayoutRequests.toString();

    // ───────────────────────────────────────────────────────────────────────
    // LOGO
    // ───────────────────────────────────────────────────────────────────────

    if (logoFile != null) {
      final bytes = await logoFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'logo',
          bytes,
          filename: logoFile.name,
          contentType: MediaType(
            'image',
            _ext(logoFile.name),
          ),
        ),
      );
    }

    // ───────────────────────────────────────────────────────────────────────
    // BANNER
    // ───────────────────────────────────────────────────────────────────────

    if (bannerFile != null) {
      final bytes =
          await bannerFile.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'banner',
          bytes,
          filename: bannerFile.name,
          contentType: MediaType(
            'image',
            _ext(bannerFile.name),
          ),
        ),
      );
    }

    // ───────────────────────────────────────────────────────────────────────
    // SEND REQUEST
    // ───────────────────────────────────────────────────────────────────────

    final streamed = await request.send();

    final response =
        await http.Response.fromStream(
      streamed,
    );

    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body)
          as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Invalid response from server',
      );
    }

    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(
        body['data'],
      );
    }

    throw Exception(
      body['message'] ??
          'Failed to create shop',
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FILE EXTENSION
  // ─────────────────────────────────────────────────────────────────────────

  static String _ext(String path) {
    final ext = path
        .split('.')
        .last
        .toLowerCase();

    if (ext == 'jpg') {
      return 'jpeg';
    }

    if (ext == 'jpeg') {
      return 'jpeg';
    }

    if (ext == 'png') {
      return 'png';
    }

    if (ext == 'webp') {
      return 'webp';
    }

    return ext;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE BASIC INFO
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> updateBasicInfo(
    int shopId,
    Map<String, dynamic> body,
  ) async {
    await ApiService.patch(
      '/shops/$shopId/basic',
      body,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE OWNER INFO
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> updateOwnerInfo(
    int shopId,
    Map<String, dynamic> body,
  ) async {
    await ApiService.patch(
      '/shops/$shopId/owner',
      body,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE BANK INFO
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> updateBankInfo(
    int shopId,
    Map<String, dynamic> body,
  ) async {
    await ApiService.patch(
      '/shops/$shopId/bank',
      body,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UPDATE SETTINGS
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> updateSettings(
    int shopId,
    Map<String, dynamic> body,
  ) async {
    await ApiService.patch(
      '/shops/$shopId/settings',
      body,
    );
  }
}