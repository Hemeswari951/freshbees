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
    final prefs = await SharedPreferences.getInstance();

    if (loginResponse.firstLogin) {
      await prefs.setInt("ownerId", loginResponse.ownerId!);
    } else {
      ApiService.setToken(loginResponse.token);

      await prefs.setString("token", loginResponse.token!);

      await prefs.setString("email", loginResponse.shopOwner!["email"]);

      await prefs.setString("full_name", loginResponse.shopOwner!["full_name"]);
    }

    return loginResponse;
  }

  Future<void> logout() async {
    await ApiService.post("/auth/logout", {});

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("email");
    await prefs.remove("full_name");
    await prefs.remove("ownerId");

    ApiService.setToken(null);
  }

  Future<void> forgotPassword(String email) async {
    await ApiService.post("/auth/forgot-password", {"email": email});
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    await ApiService.post("/auth/verify-otp", {"email": email, "otp": otp});
  }

  Future<void> resetPassword({int? ownerId, String? email, required String password}) async {
  final Map<String, dynamic> body = {"password": password};

  if (ownerId != null) {
    body["ownerId"] = ownerId;
  }
  if (email != null) {
    body["email"] = email;
  }

  await ApiService.post("/auth/reset-password", body);
}
}

