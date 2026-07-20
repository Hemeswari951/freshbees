import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String serverUrl = 'http://localhost:3000';
  static const String baseUrl = '$serverUrl/api/admin';

  static String? _token;

  // =========================
  // TOKEN MANAGEMENT
  // =========================

  static Future<void> setToken(String? token) async {
    _token = token;

    final prefs = await SharedPreferences.getInstance();

    if (token == null || token.isEmpty) {
      await prefs.remove('admin_token');
    } else {
      await prefs.setString('admin_token', token);
    }
  }

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('admin_token');
  }

  static Future<void> clearToken() async {
    _token = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_token');
  }

  static String? getToken() => _token;

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

  // NEW
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

  // NEW
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

    throw Exception(body['message'] ?? 'Something went wrong');
  }
}
