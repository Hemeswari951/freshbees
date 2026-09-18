import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';
import '../models/tryon_profile_model.dart';


class TryOnProfileService {

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${ApiService.getToken()}',
      };


  // =====================================================
  // GET ALL PROFILES
  // =====================================================

  static Future<List<TryOnProfile>> getProfiles() async {

    final response = await http.get(
      Uri.parse(
        '${ApiService.serverUrl}/api/customer/tryon-profiles',
      ),
      headers: _headers,
    );

    print('GET TRY-ON PROFILES STATUS: ${response.statusCode}');
    print('GET TRY-ON PROFILES BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 ||
        data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to load try-on profiles',
      );
    }

    final List rows = data['data'] ?? [];

    return rows
        .map(
          (row) => TryOnProfile.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }


  // =====================================================
  // CREATE PROFILE
  // =====================================================

  static Future<TryOnProfile> createProfile({
    required String profileName,
    required String relationship,
    String? gender,
    String? dateOfBirth,
    String? size,
    double? height,
    double? weight,
    String? photoUrl,
    bool isDefault = false,
  }) async {

    final response = await http.post(
      Uri.parse(
        '${ApiService.serverUrl}/api/customer/tryon-profiles',
      ),
      headers: _headers,
      body: jsonEncode({
        'profileName': profileName,
        'relationship': relationship,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'size': size,
        'height': height,
        'weight': weight,
        'photoUrl': photoUrl,
        'isDefault': isDefault,
      }),
    );

    print('CREATE TRY-ON PROFILE STATUS: ${response.statusCode}');
    print('CREATE TRY-ON PROFILE BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 201 ||
        data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to create try-on profile',
      );
    }

    return TryOnProfile.fromJson(
      Map<String, dynamic>.from(data['data']),
    );
  }


  // =====================================================
  // UPDATE PROFILE
  // =====================================================

  static Future<TryOnProfile> updateProfile({
    required int profileId,
    String? profileName,
    String? relationship,
    String? gender,
    String? dateOfBirth,
    String? size,
    double? height,
    double? weight,
    String? photoUrl,
  }) async {

    print(
  'UPDATE TRY-ON PROFILE SENT DOB: $dateOfBirth',
);


    final response = await http.put(
      Uri.parse(
        '${ApiService.serverUrl}/api/customer/tryon-profiles/$profileId',
      ),
      headers: _headers,
      body: jsonEncode({
        'profileName': profileName,
        'relationship': relationship,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'size': size,
        'height': height,
        'weight': weight,
        'photoUrl': photoUrl,
      }),
    );

    print('UPDATE TRY-ON PROFILE STATUS: ${response.statusCode}');
    print('UPDATE TRY-ON PROFILE BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 ||
        data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to update try-on profile',
      );
    }

    return TryOnProfile.fromJson(
      Map<String, dynamic>.from(data['data']),
    );
  }


  // =====================================================
  // DELETE PROFILE
  // =====================================================

  static Future<void> deleteProfile(
    int profileId,
  ) async {

    final response = await http.delete(
      Uri.parse(
        '${ApiService.serverUrl}/api/customer/tryon-profiles/$profileId',
      ),
      headers: _headers,
    );

    print('DELETE TRY-ON PROFILE STATUS: ${response.statusCode}');
    print('DELETE TRY-ON PROFILE BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 ||
        data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to delete try-on profile',
      );
    }
  }

  // =====================================================
// UPLOAD PROFILE PHOTO
// =====================================================

static Future<TryOnProfile> uploadPhoto({
  required int profileId,
  required XFile image,
}) async {
  try {
    final uri = Uri.parse(
      '${ApiService.serverUrl}/api/customer/tryon-profiles/$profileId/photo',
    );

    final request = http.MultipartRequest(
      'POST',
      uri,
    );

    // Authentication
    request.headers['Authorization'] =
        'Bearer ${ApiService.getToken()}';

    // Read image bytes
    final bytes = await image.readAsBytes();

    // Add image
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: image.name,
      ),
    );

    print('UPLOAD PHOTO PROFILE ID: $profileId');
    print('UPLOAD PHOTO FILE: ${image.name}');

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(
      streamedResponse,
    );

    print(
      'UPLOAD PHOTO STATUS: ${response.statusCode}',
    );

    print(
      'UPLOAD PHOTO BODY: ${response.body}',
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 ||
        data['success'] != true) {
      throw Exception(
        data['message'] ?? 'Failed to upload profile photo',
      );
    }

    return TryOnProfile.fromJson(
      Map<String, dynamic>.from(data['data']),
    );
  } catch (e) {
    print('UPLOAD PHOTO ERROR: $e');
    rethrow;
  }
}

static Future<TryOnProfile> uploadProfilePhoto({
  required int profileId,
  required String filePath,
  required List<int> bytes,
}) async {
  final uri = Uri.parse(
    '${ApiService.serverUrl}/api/customer/tryon-profiles/$profileId/photo',
  );

  final request = http.MultipartRequest(
    'POST',
    uri,
  );

  final token = ApiService.getToken();

  if (token != null && token.isNotEmpty) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  request.files.add(
    http.MultipartFile.fromBytes(
      'photo',
      bytes,
      filename: filePath.split('/').last,
    ),
  );

  print('UPLOAD PROFILE PHOTO URL: $uri');
  print('UPLOAD PROFILE PHOTO ID: $profileId');

  final streamedResponse = await request.send();

  final response =
      await http.Response.fromStream(streamedResponse);

  print(
    'UPLOAD PROFILE PHOTO STATUS: ${response.statusCode}',
  );

  print(
    'UPLOAD PROFILE PHOTO BODY: ${response.body}',
  );

  final data = jsonDecode(response.body);

  if (response.statusCode != 200 ||
      data['success'] != true) {
    throw Exception(
      data['message'] ??
          'Failed to upload profile photo',
    );
  }

  return TryOnProfile.fromJson(
    Map<String, dynamic>.from(
      data['data'],
    ),
  );
}


// =====================================================
// GET STYLE PREFERENCES FOR TRY-ON PROFILE
// =====================================================

static Future<Map<String, dynamic>?> getProfileStyle({
  required int profileId,
}) async {
  final response = await http.get(
    Uri.parse(
      '${ApiService.serverUrl}/api/customer/tryon-profiles/$profileId/style',
    ),
    headers: _headers,
  );

  print('GET TRY-ON PROFILE STYLE STATUS: ${response.statusCode}');
  print('GET TRY-ON PROFILE STYLE BODY: ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode != 200 ||
      data['success'] != true) {
    throw Exception(
      data['message'] ?? 'Failed to load try-on profile style',
    );
  }

  return data['data'] == null
      ? null
      : Map<String, dynamic>.from(data['data']);
}


// =====================================================
// SAVE / UPDATE STYLE PREFERENCES
// =====================================================

static Future<Map<String, dynamic>> saveProfileStyle({
  required int profileId,
  String? apparelSize,
  String? fitPreference,
  List<String>? preferredColors,
  List<String>? preferredStyles,
}) async {
  final response = await http.put(
    Uri.parse(
      '${ApiService.serverUrl}/api/customer/tryon-profiles/$profileId/style',
    ),
    headers: _headers,
    body: jsonEncode({
      'apparel_size': apparelSize,
      'fit_preference': fitPreference,
      'preferred_colors': preferredColors ?? [],
      'preferred_styles': preferredStyles ?? [],
    }),
  );

  print(
    'SAVE TRY-ON PROFILE STYLE STATUS: ${response.statusCode}',
  );

  print(
    'SAVE TRY-ON PROFILE STYLE BODY: ${response.body}',
  );

  final data = jsonDecode(response.body);

  if (response.statusCode != 200 ||
      data['success'] != true) {
    throw Exception(
      data['message'] ?? 'Failed to save try-on profile style',
    );
  }

  return Map<String, dynamic>.from(data['data']);
}
static Future<Map<String, dynamic>> saveTryOnProfileStyle({
  required int profileId,
  String? apparelSize,
  String? fitPreference,
  List<String>? preferredColors,
  List<String>? preferredStyles,
}) async {
  final response = await ApiService.put(
    '/tryon-profiles/$profileId/style',
    {
      'apparel_size': apparelSize,
      'fit_preference': fitPreference,
      'preferred_colors': preferredColors ?? [],
      'preferred_styles': preferredStyles ?? [],
    },
  );

  if (response['success'] != true) {
    throw Exception(
      response['message'] ??
          'Failed to save try-on profile style',
    );
  }

  return response;
}

// =====================================================
// GET MAIN USER TRY-ON PROFILE
// GET /api/customer/tryon-profiles/main
// =====================================================

static Future<TryOnProfile> getMainProfile() async {
  final response = await http.get(
    Uri.parse(
      '${ApiService.serverUrl}/api/customer/tryon-profiles/main',
    ),
    headers: _headers,
  );

  print(
    'GET MAIN TRY-ON PROFILE STATUS: ${response.statusCode}',
  );

  print(
    'GET MAIN TRY-ON PROFILE BODY: ${response.body}',
  );

  final data = jsonDecode(response.body);

  if (response.statusCode != 200 ||
      data['success'] != true) {
    throw Exception(
      data['message'] ??
          'Failed to load main try-on profile',
    );
  }

  return TryOnProfile.fromJson(
    Map<String, dynamic>.from(data['data']),
  );
}

}