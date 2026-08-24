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

    // Production
    return 'https://api.thiraa.com';
  }
}

class ApiService {
  static String get serverUrl => AppConfig.serverUrl;
  static String get baseUrl => '$serverUrl/api/customer';

  static String? _token;

  // ============================================================
// IMAGE URL
// ============================================================

static String imageUrl(String? photoUrl) {
  if (photoUrl == null || photoUrl.trim().isEmpty) {
    return '';
  }

  // Already a complete URL
  if (photoUrl.startsWith('http://') ||
      photoUrl.startsWith('https://')) {
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
      utf8.decode(
        base64Url.decode(
          base64Url.normalize(parts[1]),
        ),
      ),
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
  // =========================
  // TOKEN MANAGEMENT
  // =========================

  static Future<void> setToken(String? token, {Map<String, dynamic>? customer}) async {
    _token = token;

    final prefs = await SharedPreferences.getInstance();

    if (token == null || token.isEmpty) {
      await prefs.remove('customer_token');
      await prefs.remove('user_name');
    } else {
      await prefs.setString('customer_token', token);
      
      if (customer != null) {
        String fullName = '${customer['first_name'] ?? ''} ${customer['last_name'] ?? ''}'.trim();
        await prefs.setString('user_name', fullName.isNotEmpty ? fullName : 'User');
      }
    }
  }

  static Future<void> loadToken() async {
  final prefs = await SharedPreferences.getInstance();

  final savedToken = prefs.getString('customer_token');

  if (savedToken == null || savedToken.isEmpty) {
    _token = null;
    return;
  }

  if (_isTokenExpired(savedToken)) {
    debugPrint('Saved customer token is expired. Clearing token.');

    await clearToken();
    return;
  }

  _token = savedToken;
  debugPrint('Customer token loaded successfully.');
}

  static Future<void> clearToken() async {
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('customer_token');
    await prefs.remove('user_name');
  }

  static String? getToken() => _token;
  static bool get isLoggedIn =>
    _token != null && _token!.isNotEmpty;

  // =========================
  // HEADERS
  // =========================
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final res = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> post(String endpoint, Map body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> patch(String endpoint, Map body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _handle(res);
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    return _handle(res);
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    final res = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

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

  if (res.statusCode == 401) {
    // Token is invalid/expired.
    _token = null;

    SharedPreferences.getInstance().then((prefs) async {
      await prefs.remove('customer_token');
      await prefs.remove('user_name');
    });

    throw Exception('SESSION_EXPIRED');
  }

  throw Exception(
    body['message'] ?? 'Something went wrong',
  );
}

  static Future<String?> getUserName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_name');
}
}

