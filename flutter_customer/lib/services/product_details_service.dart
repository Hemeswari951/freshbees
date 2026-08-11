import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product_details_model.dart';

class ProductDetailsService {
  static const String baseUrl = "http://localhost:3000";

  static Future<ProductDetailsModel> getProductDetails(int productId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/api/customer/products/$productId"),
    );

    if (response.statusCode == 200) {
  final Map<String, dynamic> jsonData =
      jsonDecode(response.body);

  return ProductDetailsModel.fromJson(
      jsonData["data"] as Map<String, dynamic>);
}

    throw Exception(
  "Failed to load product details (${response.statusCode})",
);
  }
}