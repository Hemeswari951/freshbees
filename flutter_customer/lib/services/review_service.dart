import '../models/review_model.dart';
import 'api_service.dart';

/// TODO: this assumes ApiService.get/post/put exist with the same
/// convention as ApiService.get('/products') — decoded JSON returned
/// directly, Bearer token attached automatically when logged in. If
/// your ApiService.post/put have a different signature, adjust the
/// three calls below only — everything else stays the same.
class ReviewService {
  ReviewService._();

  static Future<ProductReviewsResult> getReviews(
    int productId, {
    String sort = 'recent',
    int page = 1,
    int limit = 10,
  }) async {
    final response = await ApiService.get(
      '/products/$productId/reviews?sort=$sort&page=$page&limit=$limit',
    );

    if (response is Map<String, dynamic> && response['data'] != null) {
      return ProductReviewsResult.fromJson(response['data']);
    }
    throw Exception('Failed to load reviews');
  }

  /// Requires login — throws if the caller isn't authenticated (the
  /// screen should skip calling this for guests, see ReviewsSection).
  static Future<ReviewEligibilityModel> getEligibility(int productId) async {
    final response =
        await ApiService.get('/products/$productId/reviews/eligibility');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return ReviewEligibilityModel.fromJson(response['data']);
    }
    throw Exception('Failed to check review eligibility');
  }

  static Future<ReviewModel> submitReview(
    int productId, {
    required int rating,
    required String reviewText,
  }) async {
    final response = await ApiService.post('/products/$productId/reviews', {
      'rating': rating,
      'reviewText': reviewText,
    });

    if (response is Map<String, dynamic> && response['success'] == true) {
      return ReviewModel.fromJson(response['data']);
    }
    final message =
        response is Map<String, dynamic> ? response['message'] : null;
    throw Exception(message ?? 'Failed to submit review');
  }

  static Future<ReviewModel> updateReview(
    int productId,
    int reviewId, {
    required int rating,
    required String reviewText,
  }) async {
    final response = await ApiService.put(
      '/products/$productId/reviews/$reviewId',
      {'rating': rating, 'reviewText': reviewText},
    );

    if (response is Map<String, dynamic> && response['success'] == true) {
      return ReviewModel.fromJson(response['data']);
    }
    final message =
        response is Map<String, dynamic> ? response['message'] : null;
    throw Exception(message ?? 'Failed to update review');
  }
}