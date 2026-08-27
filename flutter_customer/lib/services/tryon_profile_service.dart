import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class TryOnProfile {
  final int profileId;
  final int customerId;
  final String profileName;
  final String relationship;
  final String? gender;
  final int? age;
  final String? size;
  final double? height;
  final double? weight;
  final String? photoUrl;
  final bool isDefault;

  TryOnProfile({
    required this.profileId,
    required this.customerId,
    required this.profileName,
    required this.relationship,
    this.gender,
    this.age,
    this.size,
    this.height,
    this.weight,
    this.photoUrl,
    required this.isDefault,
  });

  factory TryOnProfile.fromJson(Map<String, dynamic> json) {
    return TryOnProfile(
      profileId:
          int.tryParse(json['profile_id'].toString()) ?? 0,

      customerId:
          int.tryParse(json['customer_id'].toString()) ?? 0,

      profileName:
          json['profile_name']?.toString() ?? '',

      relationship:
          json['relationship']?.toString() ?? '',

      gender:
          json['gender']?.toString(),

      age: json['age'] != null
          ? int.tryParse(json['age'].toString())
          : null,

      size:
          json['size']?.toString(),

      height: json['height'] != null
          ? double.tryParse(json['height'].toString())
          : null,

      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,

      photoUrl:
          json['photo_url']?.toString(),

      isDefault:
          json['is_default'] == true,
    );
  }
}


class TryOnProfileService {

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${ApiService.getAccessToken()}',
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
    int? age,
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
        'age': age,
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
    int? age,
    String? size,
    double? height,
    double? weight,
    String? photoUrl,
  }) async {

    final response = await http.put(
      Uri.parse(
        '${ApiService.serverUrl}/api/customer/tryon-profiles/$profileId',
      ),
      headers: _headers,
      body: jsonEncode({
        'profileName': profileName,
        'relationship': relationship,
        'gender': gender,
        'age': age,
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
        'Bearer ${ApiService.getAccessToken()}';

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

  final token = ApiService.getAccessToken();

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

}