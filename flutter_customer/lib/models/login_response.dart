class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final String? refreshToken;
  final bool? isNewUser;
  final Map<String, dynamic>? customer;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.refreshToken,
    this.isNewUser,
    this.customer,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      token: json["accessToken"] ?? json["token"],
      refreshToken: json["refreshToken"],
      isNewUser: json["isNewUser"],
      customer: json["customer"],
    );
  }
}