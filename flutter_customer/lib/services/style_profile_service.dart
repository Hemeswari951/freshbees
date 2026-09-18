import 'api_service.dart';

class StyleProfileService {
  /// Get style profile.
  ///
  /// If [tryOnProfileId] is null:
  ///   → gets the main customer's style profile.
  ///
  /// If [tryOnProfileId] is provided:
  ///   → gets that Try-On profile's style.
  static Future<Map<String, dynamic>?> getProfile({
    int? tryOnProfileId,
  }) async {
    String endpoint = '/style-profile';

    if (tryOnProfileId != null) {
      endpoint =
          '/style-profile?tryon_profile_id=$tryOnProfileId';
    }

    final response = await ApiService.get(endpoint);

    if (response['success'] != true) {
      throw Exception(
        response['message'] ?? 'Failed to load style profile',
      );
    }

    return response['data'] as Map<String, dynamic>?;
  }


  /// Create or update style profile.
  ///
  /// If [tryOnProfileId] is null:
  ///   → saves the main customer's style.
  ///
  /// If [tryOnProfileId] is provided:
  ///   → saves that Try-On profile's style.
  static Future<Map<String, dynamic>> saveProfile({
    int? tryOnProfileId,
    String? apparelSize,
    String? fitPreference,
    List<String>? preferredColors,
    List<String>? preferredStyles,
  }) async {

    final response = await ApiService.put(
      '/style-profile',
      {
        // Only included when editing a Try-On profile.
        'tryon_profile_id': tryOnProfileId,

        'apparel_size': apparelSize,
        'fit_preference': fitPreference,
        'preferred_colors': preferredColors ?? [],
        'preferred_styles': preferredStyles ?? [],
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