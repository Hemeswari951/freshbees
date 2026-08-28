import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

/// One size/stock row within a color.
///
/// [price] / [mrp] are OPTIONAL per-size overrides (Approach 1): leave
/// them null when this size should just use the product's base
/// price/mrp. Only set them when this specific size (or the color it
/// belongs to) needs a different price — e.g. XXL costs more, or this
/// is a premium color. The backend should store these on
/// `product_variants.price` / `product_variants.mrp` and fall back to
/// `products.price` / `products.mrp` when they're null.
///
/// [variantId] is null for a brand-new size row (add flow, or a size the
/// owner just added while editing). When editing an existing size, it's
/// the `product_variants.id` for that row — the update endpoint uses this
/// to UPDATE that row instead of inserting a duplicate.
class SizeStockInput {
  final int? variantId;
  final String size;
  final int stock;
  final double? price;
  final double? mrp;

  SizeStockInput({
    this.variantId,
    required this.size,
    required this.stock,
    this.price,
    this.mrp,
  });
}

/// One color block from the Add/Edit Product screen.
///
/// [colorId] is null for a brand-new color (add flow, or a color the
/// owner just added while editing). When editing an existing color, it's
/// the color's id on the backend — the update endpoint uses this to
/// UPDATE that color's row instead of inserting a duplicate.
///
/// [existingImageUrls] / [existingSpin360Urls] carry the photo URLs that
/// already exist on the server for this color (as returned by
/// `getProductDetail`). They tell the update endpoint which photos to
/// KEEP as-is. If the owner picks a new photo for an angle, the new file
/// is sent (keyed the same way addProduct sends it) and takes priority
/// over the existing URL for that angle. If an angle's existing URL is
/// null AND no new file is sent for it, that photo is considered removed.
class ProductColorInput {
  final int? colorId;
  final String colorName;
  final String? colorHex;

  /// Keys:
  /// front
  /// back
  /// side
  /// zoom
  final Map<String, XFile?> images;

  /// Existing server photo URLs per angle (same keys as [images]). Only
  /// meaningful in edit mode.
  final Map<String, String?> existingImageUrls;

  /// Ordered 360° images newly picked this session.
  final List<XFile> spin360Images;

  /// Existing server 360° photo URLs, in playback order. Newly picked
  /// [spin360Images] are appended after these. Only meaningful in edit
  /// mode.
  final List<String> existingSpin360Urls;

  final List<SizeStockInput> sizes;

  ProductColorInput({
    this.colorId,
    required this.colorName,
    this.colorHex,
    required this.images,
    this.existingImageUrls = const {},
    this.spin360Images = const [],
    this.existingSpin360Urls = const [],
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

  /// Shared by addProduct/updateProduct — builds the `colors` JSON field.
  /// [includeIds] controls whether colorId/variantId are emitted (only
  /// meaningful — and only sent — on update, since a fresh add never has
  /// pre-existing ids).
  static String _encodeColors(
    List<ProductColorInput> colors, {
    required bool includeIds,
  }) {
    return jsonEncode(
      colors
          .map(
            (c) => {
              if (includeIds) 'colorId': c.colorId,
              'colorName': c.colorName,
              'colorHex': c.colorHex,
              if (includeIds) 'existingImages': c.existingImageUrls,
              if (includeIds) 'existingSpin360': c.existingSpin360Urls,
              'sizes': c.sizes
                  .map(
                    (s) => {
                      if (includeIds) 'variantId': s.variantId,
                      'size': s.size,
                      'stockQuantity': s.stock,
                      // null here = "use the product's base price/mrp"
                      // (Approach 1 — backend should COALESCE this against
                      // products.price / products.mrp when writing into
                      // product_variants).
                      'price': s.price,
                      'mrp': s.mrp,
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    );
  }

  /// Shared by addProduct/updateProduct — attaches every newly picked
  /// local photo (angle photos + 360 photos) to the multipart request.
  /// Existing server photos are NOT re-uploaded; they're referenced by
  /// URL in the `colors` JSON field instead (see `_encodeColors`).
  static Future<void> _attachColorFiles(
    http.MultipartRequest request,
    List<ProductColorInput> colors,
  ) async {
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
    required List<ProductColorInput> colors,
    // ── schema-aligned extra fields (products table + tags + attributes) ──
    // NOTE: no `sku` param here on purpose — SKU is generated by the
    // backend (e.g. from shop_id + product_id) once the product row is
    // inserted, so the seller never types one in.
    // NOTE: also no `discountPercent` param — discount is derived from
    // mrp/price and should be calculated on read (e.g. in a view or in
    // the API response), never stored, so it can't go stale.
    String? subCategory,
    String? fabric,
    String? pattern,
    String? fitType,
    String? sleeveType,
    String? neckType,
    String? occasion,
    String? washCare,
    String? countryOfOrigin,
    List<String> tags = const [],
    List<Map<String, String>> attributes = const [],
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

    // ── schema-aligned extra fields ──
    if (subCategory != null) request.fields['subCategory'] = subCategory;
    if (fabric != null) request.fields['fabric'] = fabric;
    if (pattern != null) request.fields['pattern'] = pattern;
    if (fitType != null) request.fields['fitType'] = fitType;
    if (sleeveType != null) request.fields['sleeveType'] = sleeveType;
    if (neckType != null) request.fields['neckType'] = neckType;
    if (occasion != null) request.fields['occasion'] = occasion;
    if (washCare != null) request.fields['washCare'] = washCare;
    if (countryOfOrigin != null) {
      request.fields['countryOfOrigin'] = countryOfOrigin;
    }

    // tags[] -> backend resolves/creates rows in `tags` + `product_tags`
    if (tags.isNotEmpty) {
      request.fields['tags'] = jsonEncode(tags);
    }

    // attributes[] -> backend inserts rows into `product_attributes` (EAV)
    if (attributes.isNotEmpty) {
      request.fields['attributes'] = jsonEncode(attributes);
    }

    request.fields['colors'] = _encodeColors(colors, includeIds: false);

    await _attachColorFiles(request, colors);

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

  /// PUT /products/:id
  ///
  /// Same shape as [addProduct], plus [productId] and id-aware colors/
  /// sizes so the backend can update existing color/variant rows in
  /// place instead of always inserting new ones:
  ///  - a color with `colorId` set → UPDATE that color
  ///  - a color with `colorId` null → INSERT a new color for this product
  ///  - a size with `variantId` set → UPDATE that variant
  ///  - a size with `variantId` null → INSERT a new variant for its color
  ///  - a color present in [colors] with an id that ISN'T anymore →
  ///    (handled server-side) any color previously on the product but
  ///    missing from this payload should be treated as removed
  ///
  /// Existing photos are referenced via `existingImages` /
  /// `existingSpin360` (URLs) inside the `colors` JSON field so they're
  /// kept without being re-uploaded; only newly picked local photos are
  /// sent as multipart files, using the same `color_{i}_{angle}` /
  /// `color_{i}_360_{j}` keys as [addProduct]. Returns the updated
  /// product in the same shape as [getProductDetail].
  static Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String productName,
    required String description,
    int? categoryId,
    int? brandId,
    double? mrp,
    required double price,
    required List<ProductColorInput> colors,
    String? subCategory,
    String? fabric,
    String? pattern,
    String? fitType,
    String? sleeveType,
    String? neckType,
    String? occasion,
    String? washCare,
    String? countryOfOrigin,
    List<String> tags = const [],
    List<Map<String, String>> attributes = const [],
  }) async {
    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('${ApiService.baseUrl}/products/$productId'),
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

    if (subCategory != null) request.fields['subCategory'] = subCategory;
    if (fabric != null) request.fields['fabric'] = fabric;
    if (pattern != null) request.fields['pattern'] = pattern;
    if (fitType != null) request.fields['fitType'] = fitType;
    if (sleeveType != null) request.fields['sleeveType'] = sleeveType;
    if (neckType != null) request.fields['neckType'] = neckType;
    if (occasion != null) request.fields['occasion'] = occasion;
    if (washCare != null) request.fields['washCare'] = washCare;
    if (countryOfOrigin != null) {
      request.fields['countryOfOrigin'] = countryOfOrigin;
    }

    // tags[] / attributes[] are sent in full every time — the backend
    // should treat these as a full replace (diff against what's already
    // stored) rather than an append, same as most edit forms do.
    request.fields['tags'] = jsonEncode(tags);
    request.fields['attributes'] = jsonEncode(attributes);

    request.fields['colors'] = _encodeColors(colors, includeIds: true);

    await _attachColorFiles(request, colors);

    final streamed = await request.send();

    final response = await http.Response.fromStream(streamed);

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    print(response.statusCode);
    print(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(body['data'] as Map);
    }

    throw Exception(
      body['message'] ?? 'Failed to update product (${response.statusCode})',
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