import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AppConfig {
  //static const bool isDevelopment = true;
  static const bool isDevelopment = false;


  static String get serverUrl {
    if (isDevelopment) {
      if (kIsWeb) return 'http://localhost:3000';

      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }

      return 'http://localhost:3000';
    }

    // Production
    return 'https://thiraa.onrender.com';
  }
}

class ApiService {
  static String get serverUrl => AppConfig.serverUrl;
  static String get baseUrl => '$serverUrl/api/customer';

  //static String? _token;
  static String? _accessToken;
static String? _refreshToken;

  // ============================================================
  // IMAGE URL
  // ============================================================

  static String imageUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return '';
    }

    // Already a complete URL
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }

    // Backend returns paths like:
    // /uploads/tryon/profile_1_xxx.jpg

    if (photoUrl.startsWith('/')) {
      return '$serverUrl$photoUrl';
    }

    return '$serverUrl/$photoUrl';
  }

  static bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');

      if (parts.length != 3) {
        return true;
      }

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'];

      if (exp == null) {
        return true;
      }

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(
        (exp as num).toInt() * 1000,
      );

      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      debugPrint('JWT validation error: $e');
      return true;
    }
  }

  static bool _isTokenExpiredResponse(http.Response response) {
  try {
    final body = jsonDecode(response.body);

    return body['code'] == 'TOKEN_EXPIRED';
  } catch (_) {
    return false;
  }
}
  
  // =========================
  // TOKEN MANAGEMENT
  // =========================

  static Future<void> setTokens({
  required String accessToken,
  String? refreshToken,
  Map<String, dynamic>? customer,
}) async {
  _accessToken = accessToken;

  if (refreshToken != null && refreshToken.isNotEmpty) {
    _refreshToken = refreshToken;
  }

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(
    'customer_access_token',
    accessToken,
  );

  if (refreshToken != null && refreshToken.isNotEmpty) {
    await prefs.setString(
      'customer_refresh_token',
      refreshToken,
    );
  }

  if (customer != null) {
    final fullName =
        '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'
            .trim();

    await prefs.setString(
      'user_name',
      fullName.isNotEmpty ? fullName : 'User',
    );
  }
}
  static Future<void> loadTokens() async {
  final prefs = await SharedPreferences.getInstance();

  _accessToken = prefs.getString('customer_access_token');
  _refreshToken = prefs.getString('customer_refresh_token');

  debugPrint(
    'Access token loaded: ${_accessToken != null}',
  );

  debugPrint(
    'Refresh token loaded: ${_refreshToken != null}',
  );
}

  static Future<void> clearTokens() async {
  _accessToken = null;
  _refreshToken = null;

  final prefs = await SharedPreferences.getInstance();

  await prefs.remove('customer_access_token');
  await prefs.remove('customer_refresh_token');
  await prefs.remove('user_name');
}

  //static String? getToken() => _token;
  static String? getAccessToken() => _accessToken;

static String? getRefreshToken() => _refreshToken;

  // =========================
  // HEADERS
  // =========================
  static Map<String, String> get headers => {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  if (_accessToken != null && _accessToken!.isNotEmpty)
    'Authorization': 'Bearer $_accessToken',
};

  static Future<Map<String, dynamic>> get(String endpoint) async {
  var res = await http.get(
    Uri.parse('$baseUrl$endpoint'),
    headers: headers,
  );

  if (res.statusCode == 401 &&
      _isTokenExpiredResponse(res)) {
    final refreshed = await refreshAccessToken();

    if (refreshed) {
      res = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
    }
  }

  return _handle(res);
}
  static Future<Map<String, dynamic>> post(
  String endpoint,
  Map body,
) async {
  var res = await http.post(
    Uri.parse('$baseUrl$endpoint'),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 401 &&
      _isTokenExpiredResponse(res)) {
    final refreshed = await refreshAccessToken();

    if (refreshed) {
      res = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
    }
  }

  return _handle(res);
}


  static Future<Map<String, dynamic>> patch(
  String endpoint,
  Map body,
) async {
  var res = await http.patch(
    Uri.parse('$baseUrl$endpoint'),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 401 &&
      _isTokenExpiredResponse(res)) {
    final refreshed = await refreshAccessToken();

    if (refreshed) {
      res = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
    }
  }

  return _handle(res);
}

 static Future<Map<String, dynamic>> put(
  String endpoint,
  Map<String, dynamic> body,
) async {
  var res = await http.put(
    Uri.parse('$baseUrl$endpoint'),
    headers: headers,
    body: jsonEncode(body),
  );

  if (res.statusCode == 401 &&
      _isTokenExpiredResponse(res)) {
    final refreshed = await refreshAccessToken();

    if (refreshed) {
      res = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
    }
  }

  return _handle(res);
}

  static Future<Map<String, dynamic>> delete(String endpoint) async {
  var res = await http.delete(
    Uri.parse('$baseUrl$endpoint'),
    headers: headers,
  );

  if (res.statusCode == 401 &&
      _isTokenExpiredResponse(res)) {
    final refreshed = await refreshAccessToken();

    if (refreshed) {
      res = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );
    }
  }

  return _handle(res);
}


  static Map<String, dynamic> _handle(http.Response res) {
    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    Map<String, dynamic> body;

    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception(
        'Server returned invalid JSON.\n'
        'Status: ${res.statusCode}\n'
        'Body: ${res.body}',
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Something went wrong');
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name');
  }

  static Future<bool> refreshAccessToken() async {
  try {
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      debugPrint('No refresh token available');
      return false;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/auth/refresh-token'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'refreshToken': _refreshToken,
      }),
    );

    debugPrint('REFRESH STATUS: ${response.statusCode}');
    debugPrint('REFRESH BODY: ${response.body}');

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      return false;
    }

    final body = jsonDecode(response.body);

    final newAccessToken = body['accessToken'];

    if (newAccessToken == null ||
        newAccessToken.toString().isEmpty) {
      return false;
    }

    _accessToken = newAccessToken.toString();

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'customer_access_token',
      _accessToken!,
    );

    debugPrint('Access token refreshed successfully');

    return true;
  } catch (e) {
    debugPrint('Refresh token error: $e');
    return false;
  }
}

}
