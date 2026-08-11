import '../models/product_model.dart';
import 'api_service.dart';

class ProductService {
  ProductService._();

  /// Get all products
  static Future<List<ProductModel>> getProducts() async {
  final response = await ApiService.get('/products');

  if (response is Map<String, dynamic>) {
    final List data = response['data'] ?? [];

    return data
        .map((json) => ProductModel.fromJson(json))
        .toList();
  }

  return [];
}
  
}