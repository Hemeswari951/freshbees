import 'api_service.dart';

class StyleProfileService {
  /// Get the currently logged-in customer's style profile.
  static Future<Map<String, dynamic>?> getProfile() async {
    final response = await ApiService.get('/style-profile');

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to load style profile',
      );
    }

    return response['data'] as Map<String, dynamic>?;
  }

  /// Create or update the currently logged-in customer's style profile.
  static Future<Map<String, dynamic>> saveProfile({
    required String gender,
    required String ageGroup,
    required double heightCm,
    required double weightKg,
    required String size,
    required List<String> preferredColors,
    required List<String> preferredStyles,
  }) async {
    final response = await ApiService.put(
      '/style-profile',
      {
        'gender': gender,
        'age_group': ageGroup,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'size': size,
        'preferred_colors': preferredColors,
        'preferred_styles': preferredStyles,
      },
    );

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to save style profile',
      );
    }

    return response;
  }
}