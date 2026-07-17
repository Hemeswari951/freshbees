import 'dart:convert';
// import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'api_service.dart';

class ShopService {
  // ── Get all shops (ShopsScreen) ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllShops() async {
    final res = await ApiService.get('/shops');
    return List<Map<String, dynamic>>.from(res['data']);
  }

  // ── Get single shop detail (ShopDetailScreen) ────────────────────────────
  static Future<Map<String, dynamic>> getShopDetail(int shopId) async {
    final res = await ApiService.get('/shops/$shopId');
    return Map<String, dynamic>.from(res['data']);
  }

  // ── Update Shop Status ─────────────────────────────────────────────────────
  static Future<void> updateShopStatus(
    int shopId,
    String status, {
    String? reason,
  }) async {
    await ApiService.patch('/shops/$shopId/status', {
      'status': status,
      'reason': reason,
    });
  }

  // ── Create shop (multipart — has image files) ─────────────────────────────
  static Future<Map<String, dynamic>> createShop({
    // Step 1 — Basic
    required String shopName,
    required String description,
    required List<int> categoryIds,
    required String address,
    required String city,
    required String state,
    required String pincode,
    XFile? logoFile,
    XFile? bannerFile,
    // Step 2 — Owner
    required String ownerName,
    required String ownerEmail,
    required String ownerPhone,
    // Step 3 — Bank
    required String accountNumber,
    required String bankName,
    required String ifscCode,
    String? gstNumber,
    // Step 4 — Settings
    required String commissionRate,
    required bool activateImmediately,
    required bool sendWelcomeEmail,
    required bool allowProductUploads,
    required bool enablePayoutRequests,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/shops');

    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer ${ApiService.getToken()}'
      // Step 1
      ..fields['shopName'] = shopName
      ..fields['description'] = description
      ..fields['categoryIds'] = jsonEncode(categoryIds)
      ..fields['address'] = address
      ..fields['city'] = city
      ..fields['state'] = state
      ..fields['pincode'] = pincode
      // Step 2
      ..fields['ownerName'] = ownerName
      ..fields['ownerEmail'] = ownerEmail
      ..fields['ownerPhone'] = ownerPhone
      // Step 3
      ..fields['accountNumber'] = accountNumber
      ..fields['bankName'] = bankName
      ..fields['ifscCode'] = ifscCode
      ..fields['gstNumber'] = gstNumber ?? ''
      // Step 4
      ..fields['commissionRate'] = commissionRate
      ..fields['activateImmediately'] = activateImmediately.toString()
      ..fields['sendWelcomeEmail'] = sendWelcomeEmail.toString()
      ..fields['allowProductUploads'] = allowProductUploads.toString()
      ..fields['enablePayoutRequests'] = enablePayoutRequests.toString();

    // Attach logo if selected
    if (logoFile != null) {
      final bytes = await logoFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'logo',
          bytes,
          filename: logoFile.name,
          contentType: MediaType('image', _ext(logoFile.name)),
        ),
      );
    }

    // Attach banner if selected
    if (bannerFile != null) {
      final bytes = await bannerFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'banner',
          bytes,
          filename: bannerFile.name,
          contentType: MediaType('image', _ext(bannerFile.name)),
        ),
      );
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);

    if (res.statusCode == 201) {
      return Map<String, dynamic>.from(body['data']);
    }

    throw Exception(body['message'] ?? 'Failed to create shop');
  }

  // Helper — get file extension for content type
  static String _ext(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'jpg') return 'jpeg';
    return ext; // png, jpeg, webp
  }

  static Future<void> updateBasicInfo(
    int shopId,

    Map<String, dynamic> body,
  ) async {
    await ApiService.patch("/shops/$shopId/basic", body);
  }

  static Future<void> updateOwnerInfo(
    int shopId,
    Map<String, dynamic> body,
  ) async {
    await ApiService.patch("/shops/$shopId/owner", body);
  }

  static Future<void> updateBankInfo(
    int shopId,
    Map<String, dynamic> body,
  ) async {
    await ApiService.patch("/shops/$shopId/bank", body);
  }

  static Future<void> updateSettings(
    int shopId,
    Map<String, dynamic> body,
  ) async {
    await ApiService.patch("/shops/$shopId/settings", body);
  }
}
