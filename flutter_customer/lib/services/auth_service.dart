import '../models/login_response.dart';
import 'api_service.dart';

class AuthService {
  //=========================
  // SEND OTP
  //=========================

  static Future<LoginResponse> sendOtp({
    required String identifier,
    required String purpose,
  }) async {
    try {
      final response = await ApiService.post("/auth/send-otp", {
        "identifier": identifier.trim().toLowerCase(),
        "purpose": purpose,
      });

      return LoginResponse.fromJson(response);
    } catch (e) {
      return LoginResponse(
        success: false,
        message: e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  //=========================
  // VERIFY OTP
  //=========================

  static Future<LoginResponse> verifyOtp({
    required String identifier,
    required String otp,
    required String purpose,
  }) async {
    try {
      final response = await ApiService.post("/auth/verify-otp", {
        "identifier": identifier.trim().toLowerCase(),
        "otp": otp.trim(),
        "purpose": purpose,
      });

      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.success && loginResponse.token != null) {
        await ApiService.setToken(
          loginResponse.token,
          refreshToken: loginResponse.refreshToken,
          customer: loginResponse.customer,
        );
      }

      return loginResponse;
    } catch (e) {
      return LoginResponse(
        success: false,
        message: e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  //=========================
  // REGISTER / CREATE ACCOUNT WITH PASSWORD
  //=========================

  static Future<LoginResponse> createAccountWithPassword({
    required String identifier,
    required String name,
    required String password,
    String gender = 'Other',
    String dateOfBirth = '2000-01-01',
  }) async {
    try {
      List<String> nameParts = name.trim().split(' ');
      String firstName = nameParts.first;
      String lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : 'User';

      final response = await ApiService.post("/auth/register", {
        "identifier": identifier.trim().toLowerCase(),
        "password": password,
        "first_name": firstName,
        "last_name": lastName,
        "gender": gender,
        "date_of_birth": dateOfBirth,
      });

      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.success && loginResponse.token != null) {
        await ApiService.setToken(
          loginResponse.token,
          refreshToken: loginResponse.refreshToken,
          customer: loginResponse.customer,
        );
      }

      return loginResponse;
    } catch (e) {
      return LoginResponse(
        success: false,
        message: e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  static Future<LoginResponse> register({
    required String identifier,
    required String password,
    required String firstName,
    required String lastName,
    required String gender,
    required String dob,
  }) async {
    try {
      final response = await ApiService.post("/auth/register", {
        "identifier": identifier.trim().toLowerCase(),
        "password": password,
        "first_name": firstName,
        "last_name": lastName,
        "gender": gender,
        "date_of_birth": dob,
      });

      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.success && loginResponse.token != null) {
        await ApiService.setToken(
          loginResponse.token,
          refreshToken: loginResponse.refreshToken,
          customer: loginResponse.customer,
        );
      }

      return loginResponse;
    } catch (e) {
      return LoginResponse(
        success: false,
        message: e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  //=========================
  // PASSWORD LOGIN
  //=========================

  static Future<LoginResponse> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    return login(identifier: identifier, password: password);
  }

  static Future<LoginResponse> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await ApiService.post("/auth/login", {
        "identifier": identifier.trim().toLowerCase(),
        "password": password,
      });

      final loginResponse = LoginResponse.fromJson(response);

      if (loginResponse.success && loginResponse.token != null) {
        await ApiService.setToken(
          loginResponse.token,
          refreshToken: loginResponse.refreshToken,
          customer: loginResponse.customer,
        );
      }

      return loginResponse;
    } catch (e) {
      return LoginResponse(
        success: false,
        message: e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  //=========================
  // FORGOT PASSWORD
  //=========================

  static Future<LoginResponse> forgotPassword({
    required String identifier,
  }) async {
    try {
      final response = await ApiService.post("/auth/forgot-password", {
        "identifier": identifier.trim().toLowerCase(),
      });

      return LoginResponse.fromJson(response);
    } catch (e) {
      return LoginResponse(
        success: false,
        message: e.toString().replaceFirst("Exception: ", ""),
        refreshToken: null,
      );
    }
  }

  //=========================
  // RESET PASSWORD
  //=========================

  static Future<LoginResponse> resetPassword({
    required String identifier,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.post("/auth/reset-password", {
        "identifier": identifier.trim().toLowerCase(),
        "password": newPassword,
      });

      return LoginResponse.fromJson(response);
    } catch (e) {
      return LoginResponse(
        success: false,
        message: e.toString().replaceFirst("Exception: ", ""),
      );
    }
  }

  //=========================
  // LOGOUT
  //=========================
  static Future<LoginResponse> logout() async {
    final refreshToken = ApiService.getRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await ApiService.post("/auth/logout", {"refreshToken": refreshToken});
      }

      return LoginResponse(success: true, message: "Logout Successful");
    } catch (e) {
      return LoginResponse(
        success: false,
        message: e.toString().replaceFirst("Exception: ", ""),
      );
    } finally {
      // Always clear local session,
      // even if server logout fails.
      await ApiService.clearToken();
    }
  }
  //=========================
  // TOKEN HELPERS
  //=========================

  static Future<void> loadToken() async {
    await ApiService.loadToken();
  }

  static Future<void> clearToken() async {
    await ApiService.clearToken();
  }

  static String? get token => ApiService.getToken();
}
