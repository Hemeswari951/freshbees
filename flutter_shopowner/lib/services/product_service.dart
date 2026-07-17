import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

/// One size/stock row within a color.
class SizeStockInput {
  final String size;
  final int stock;

  SizeStockInput({required this.size, required this.stock});
}

/// One color block from the Add Product screen.
class ProductColorInput {
  final String colorName;
  final String? colorHex;

  /// Keys:
  /// front
  /// back
  /// side
  /// zoom
  final Map<String, XFile?> images;

  /// Ordered 360° images
  final List<XFile> spin360Images;

  final List<SizeStockInput> sizes;

  ProductColorInput({
    required this.colorName,
    this.colorHex,
    required this.images,
    this.spin360Images = const [],
    required this.sizes,
  });
}

class ProductService {
  ProductService._();

  static String get mediaBaseUrl => ApiService.serverUrl;

  static String fullImageUrl(String relativePath) {
    return '$mediaBaseUrl$relativePath';
  }

  static MediaType _mediaTypeFor(String filename) {
    final ext = filename.toLowerCase().split('.').last;

    switch (ext) {
      case 'png':
        return MediaType('image', 'png');

      case 'webp':
        return MediaType('image', 'webp');

      case 'gif':
        return MediaType('image', 'gif');

      case 'heic':
        return MediaType('image', 'heic');

      case 'jpg':
      case 'jpeg':
      default:
        return MediaType('image', 'jpeg');
    }
  }

  /// GET /products
  static Future<List<Map<String, dynamic>>> getProducts() async {
    final response = await ApiService.get('/products');

    final List list = response['data'] as List;

    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// GET /products/:id
  static Future<Map<String, dynamic>> getProductDetail(int id) async {
    final response = await ApiService.get('/products/$id');

    return Map<String, dynamic>.from(response['data'] as Map);
  }

  /// GET /products/meta/lookup
  static Future<Map<String, List<Map<String, dynamic>>>>
  getProductMeta() async {
    final response = await ApiService.get('/products/meta/lookup');

    final data = response['data'] as Map<String, dynamic>;

    return {
      'categories': (data['categories'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      'brands': (data['brands'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    };
  }

  /// POST /products
  static Future<Map<String, dynamic>> addProduct({
    required String productName,
    required String description,
    int? categoryId,
    int? brandId,
    double? mrp,
    required double price,
    int discountPercent = 0,
    required List<ProductColorInput> colors,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiService.baseUrl}/products'),
    );

    final token = ApiService.getToken();

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['productName'] = productName;
    request.fields['description'] = description;

    if (categoryId != null) {
      request.fields['categoryId'] = categoryId.toString();
    }

    if (brandId != null) {
      request.fields['brandId'] = brandId.toString();
    }

    if (mrp != null) {
      request.fields['mrp'] = mrp.toString();
    }

    request.fields['price'] = price.toString();
    request.fields['discountPercent'] = discountPercent.toString();

    request.fields['colors'] = jsonEncode(
      colors
          .map(
            (c) => {
              'colorName': c.colorName,
              'colorHex': c.colorHex,
              'sizes': c.sizes
                  .map((s) => {'size': s.size, 'stockQuantity': s.stock})
                  .toList(),
            },
          )
          .toList(),
    );

    for (int i = 0; i < colors.length; i++) {
      final color = colors[i];

      for (final entry in color.images.entries) {
        final type = entry.key;
        final file = entry.value;

        if (file == null) continue;

        final bytes = await file.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'color_${i}_$type',
            bytes,
            filename: file.name,
            contentType: _mediaTypeFor(file.name),
          ),
        );
      }

      for (int j = 0; j < color.spin360Images.length; j++) {
        final file = color.spin360Images[j];

        final bytes = await file.readAsBytes();

        request.files.add(
          http.MultipartFile.fromBytes(
            'color_${i}_360_$j',
            bytes,
            filename: file.name,
            contentType: _mediaTypeFor(file.name),
          ),
        );
      }
    }

    final streamed = await request.send();

    final response = await http.Response.fromStream(streamed);

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    
    print(response.statusCode);
    print(response.body);
    
    if (response.statusCode == 201) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }


    throw Exception(
      body['message'] ?? 'Failed to add product (${response.statusCode})',
    );
  }

  /// PATCH /products/variants/:id/stock
  static Future<Map<String, dynamic>> adjustVariantStock(
    int variantId,
    int delta,
  ) async {
    final response = await ApiService.patch(
      '/products/variants/$variantId/stock',
      {'delta': delta},
    );

    return Map<String, dynamic>.from(response['data'] as Map);
  }

  /// PATCH /products/:id/status
  static Future<void> setProductStatus(int id, String status) async {
    await ApiService.patch('/products/$id/status', {'status': status});
  }

  /// DELETE /products/:id
  static Future<void> deleteProduct(int id) async {
    await ApiService.delete('/products/$id');
  }
}
