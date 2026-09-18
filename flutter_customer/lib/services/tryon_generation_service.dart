import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'api_service.dart';

class TryOnGenerationService {
  static Future<String> generateTryOn({
  int? profileId,
  XFile? customerPhoto,
  required int productId,
  required String productImageUrl,
}) async {
    final url =
        '${ApiService.serverUrl}/api/customer/virtual-tryon/generate';

    debugPrint('TRY-ON REQUEST URL: $url');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(url),
    );

    // --------------------------------------------------
    // Authorization
    // --------------------------------------------------

    final token = ApiService.getToken();

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // --------------------------------------------------
    // Profile ID
    // --------------------------------------------------

    if (profileId != null) {
      request.fields['profileId'] = profileId.toString();

      debugPrint(
        'TRY-ON PROFILE ID: $profileId',
      );
    }

    // --------------------------------------------------
    // Product ID
    // --------------------------------------------------

    request.fields['productId'] = productId.toString();

    // --------------------------------------------------
// Product Image URL
// --------------------------------------------------

request.fields['productImageUrl'] = productImageUrl;

debugPrint(
  'TRY-ON PRODUCT IMAGE URL: $productImageUrl',
);

    debugPrint(
      'TRY-ON PRODUCT ID: $productId',
    );

    

    // --------------------------------------------------
    // Main user's temporary photo
    // --------------------------------------------------

    if (customerPhoto != null) {
      final bytes = await customerPhoto.readAsBytes();

      request.files.add(
        http.MultipartFile.fromBytes(
          'customerPhoto',
          bytes,
          filename: customerPhoto.name,
        ),
      );

      debugPrint(
        'TRY-ON TEMP PHOTO: ${customerPhoto.name}',
      );
    }

    // --------------------------------------------------
    // Send request
    // --------------------------------------------------

    final streamedResponse = await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    debugPrint(
      'TRY-ON RESPONSE STATUS: ${response.statusCode}',
    );

    debugPrint(
      'TRY-ON RESPONSE BODY: ${response.body}',
    );

    final body = response.body.trim();

    if (body.startsWith('<!DOCTYPE') ||
        body.startsWith('<html')) {
      throw Exception(
        'Server returned an invalid response. Please try again.',
      );
    }

    Map<String, dynamic> data;

    try {
      data = jsonDecode(body)
          as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
        'Invalid server response',
      );
    }

    if (response.statusCode != 200) {
      throw Exception(
        data['message'] ??
            'Failed to generate try-on',
      );
    }

    if (data['success'] != true) {
      throw Exception(
        data['message'] ??
            'Failed to generate try-on',
      );
    }

    final generatedImageUrl =
        data['data']?['generatedImageUrl']
            ?.toString();

    if (generatedImageUrl == null ||
        generatedImageUrl.isEmpty) {
      throw Exception(
        'Generated try-on image is missing',
      );
    }

    return ApiService.imageUrl(
      generatedImageUrl,
    );
  }
}