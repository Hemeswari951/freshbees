import '../models/product_details_model.dart';
import 'api_service.dart';

class ProductDetailsService {
  ProductDetailsService._();

  static Future<ProductDetailsModel> getProductDetails(int productId) async {
    final response = await ApiService.get('/products/$productId');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return ProductDetailsModel.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw Exception('Failed to load product details');
  }
}