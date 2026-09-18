import 'api_service.dart';
import '../models/profile_model.dart';

class ProfileService {
  /// Get the currently logged-in customer's profile.
  static Future<ProfileModel> getProfile() async {
    final response = await ApiService.get('/profile');

    if (response['success'] != true) {
      throw Exception(
        response['message'] ??
            'Failed to load profile',
      );
    }

    final data = response['data'];

    if (data == null) {
      throw Exception('Profile data not found');
    }

    return ProfileModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  static Future<ProfileModel> updateProfile({
  required String firstName,
  required String lastName,
  String? email,
  String? phone,
  String? gender,
  String? city,
  String? state,
  String? dateOfBirth,
}) async {
  final response = await ApiService.put(
    '/profile',
    {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
    'gender': gender,
    'city': city,
    'state': state,
    'date_of_birth': dateOfBirth,
    },
  );

  if (response['success'] != true) {
    throw Exception(
      response['message'] ?? 'Failed to update profile',
    );
  }

  final data = response['data'];

  if (data == null) {
    throw Exception('Updated profile data not found');
  }

  return ProfileModel.fromJson(
    Map<String, dynamic>.from(data),
  );
}

}