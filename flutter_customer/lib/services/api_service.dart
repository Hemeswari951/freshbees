import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AppConfig {
  static const bool isDevelopment = true;

  static String get serverUrl {
    if (isDevelopment) {
      if (kIsWeb) return 'http://localhost:3000';

      if (Platform.isAndroid) {
        return 'http://10.0.2.2:3000';
      }

      return 'http://localhost:3000';
    }

    return 'https://api.thiraa.com';
  }
}

class ApiService {
  static String get serverUrl => AppConfig.serverUrl;
  static String get baseUrl => '$serverUrl/api/customer';

  static String? _token;
  static String? _refreshToken;

  // Prevent multiple API calls from refreshing simultaneously
  static Future<bool>? _refreshing;

  // ============================================================
  // IMAGE URL
  // ============================================================

  static String imageUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      return '';
    }

    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }

    if (photoUrl.startsWith('/')) {
      return '$serverUrl$photoUrl';
    }

    return '$serverUrl/$photoUrl';
  }

  // ============================================================
  // JWT EXPIRY CHECK
  // ============================================================

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

  // ============================================================
  // TOKEN MANAGEMENT
  // ============================================================

  static Future<void> setToken(
    String? token, {
    String? refreshToken,
    Map<String, dynamic>? customer,
  }) async {
    _token = token;

    if (refreshToken != null && refreshToken.isNotEmpty) {
      _refreshToken = refreshToken;
    }

    final prefs = await SharedPreferences.getInstance();

    if (token == null || token.isEmpty) {
      await prefs.remove('customer_token');
    } else {
      await prefs.setString('customer_token', token);
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString('customer_refresh_token', refreshToken);
    }

    if (customer != null) {
      final fullName =
          '${customer['first_name'] ?? ''} '
                  '${customer['last_name'] ?? ''}'
              .trim();

      await prefs.setString(
        'user_name',
        fullName.isNotEmpty ? fullName : 'User',
      );
    }
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('customer_token');

    _refreshToken = prefs.getString('customer_refresh_token');

    debugPrint('Access token loaded: ${_token != null}');

    debugPrint('Refresh token loaded: ${_refreshToken != null}');
  }

  static Future<void> clearToken() async {
    _token = null;
    _refreshToken = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('customer_token');
    await prefs.remove('customer_refresh_token');
    await prefs.remove('user_name');
  }

  static String? getToken() => _token;

  static String? getRefreshToken() => _refreshToken;

  // ============================================================
  // HEADERS
  // ============================================================

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  // ============================================================
  // REFRESH ACCESS TOKEN
  // ============================================================

  static Future<bool> refreshAccessToken() async {
    // If another request is already refreshing,
    // wait for that same refresh operation.
    if (_refreshing != null) {
      return await _refreshing!;
    }

    _refreshing = _performRefresh();

    try {
      return await _refreshing!;
    } finally {
      _refreshing = null;
    }
  }

  static Future<bool> _performRefresh() async {
    try {
      final refreshToken = _refreshToken;

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('No refresh token available');
        return false;
      }

      debugPrint('Refreshing access token...');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      debugPrint('Refresh status: ${response.statusCode}');

      debugPrint('Refresh body: ${response.body}');

      Map<String, dynamic> data;

      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        debugPrint('Invalid refresh response');
        return false;
      }

      if (response.statusCode == 200 &&
          data['success'] == true &&
          data['accessToken'] != null) {
        final newAccessToken = data['accessToken'].toString();

        _token = newAccessToken;

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('customer_token', newAccessToken);

        debugPrint('Access token refreshed successfully');

        return true;
      }

      debugPrint('Refresh token invalid or expired');

      return false;
    } catch (e) {
      debugPrint('Refresh access token error: $e');

      return false;
    }
  }

  // ============================================================
  // MAKE REQUEST
  // ============================================================

  static Future<http.Response> _request({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    bool retry = true,
  }) async {
    // ----------------------------------------------------------
    // Check locally whether access token already expired
    // ----------------------------------------------------------

    if (_token != null && _token!.isNotEmpty && _isTokenExpired(_token!)) {
      debugPrint('Access token already expired. Refreshing...');

      final refreshed = await refreshAccessToken();

      if (!refreshed) {
        await clearToken();

        throw Exception('Session expired. Please login again.');
      }
    }

    final uri = Uri.parse('$baseUrl$endpoint');

    final requestHeaders = headers;

    late http.Response response;

    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: requestHeaders);
        break;

      case 'POST':
        response = await http.post(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? {}),
        );
        break;

      case 'PUT':
        response = await http.put(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? {}),
        );
        break;

      case 'PATCH':
        response = await http.patch(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? {}),
        );
        break;

      case 'DELETE':
        response = await http.delete(uri, headers: requestHeaders);
        break;

      default:
        throw Exception('Unsupported HTTP method: $method');
    }

    debugPrint('$method $endpoint → ${response.statusCode}');

    // ----------------------------------------------------------
    // Access token expired on server
    // ----------------------------------------------------------

    if (response.statusCode == 401 && retry) {
      debugPrint('401 received. Trying refresh token...');

      final refreshed = await refreshAccessToken();

      if (refreshed) {
        debugPrint('Retrying original request...');

        return await _request(
          method: method,
          endpoint: endpoint,
          body: body,
          retry: false,
        );
      }

      // Refresh token itself failed
      await clearToken();

      throw Exception('Session expired. Please login again.');
    }

    return response;
  }

  // ============================================================
  // GET
  // ============================================================

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final response = await _request(method: 'GET', endpoint: endpoint);

    return _handle(response);
  }

  // ============================================================
  // POST
  // ============================================================

  static Future<Map<String, dynamic>> post(String endpoint, Map body) async {
    final response = await _request(
      method: 'POST',
      endpoint: endpoint,
      body: Map<String, dynamic>.from(body),
    );

    return _handle(response);
  }

  // ============================================================
  // PUT
  // ============================================================

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await _request(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
    );

    return _handle(response);
  }

  // ============================================================
  // PATCH
  // ============================================================

  static Future<Map<String, dynamic>> patch(String endpoint, Map body) async {
    final response = await _request(
      method: 'PATCH',
      endpoint: endpoint,
      body: Map<String, dynamic>.from(body),
    );

    return _handle(response);
  }

  // ============================================================
  // DELETE
  // ============================================================

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final response = await _request(method: 'DELETE', endpoint: endpoint);

    return _handle(response);
  }

  // ============================================================
  // RESPONSE HANDLER
  // ============================================================

  static Map<String, dynamic> _handle(http.Response res) {
    debugPrint('STATUS: ${res.statusCode}');

    debugPrint('BODY: ${res.body}');

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

    throw Exception(body['message']?.toString() ?? 'Something went wrong');
  }

  // ============================================================
  // USER NAME
  // ============================================================

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('user_name');
  }
}
