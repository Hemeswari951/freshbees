class LoginResponse {
  final bool success;
  final String message;
  final String token;
  final Map<String, dynamic> admin;

  LoginResponse({
    required this.success,
    required this.message,
    required this.token,
    required this.admin,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      token: json["token"] ?? "",
      admin: json["admin"] ?? {},
    );
  }
}