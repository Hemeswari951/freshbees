import 'package:shared_preferences/shared_preferences.dart';

import '../models/login_response.dart';
import 'api_service.dart';

class AuthService {
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiService.post('/auth/login', {
      "email": email,
      "password": password,
    });

    final loginResponse = LoginResponse.fromJson(data);

    ApiService.setToken(loginResponse.token);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("token", loginResponse.token);
    await prefs.setString("email", loginResponse.admin["email"]);

    await prefs.setString("full_name", loginResponse.admin["full_name"]);

    await prefs.setString("role", loginResponse.admin["role"]);

    return loginResponse;
  }

  Future<void> logout() async {
    await ApiService.post("/auth/logout", {});

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("email");
    await prefs.remove("full_name");
    await prefs.remove("role");

    ApiService.setToken(null);
  }
}
