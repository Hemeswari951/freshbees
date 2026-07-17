class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final bool firstLogin;
  final int? ownerId;
  final Map<String, dynamic>? shopOwner;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    required this.firstLogin,
    this.ownerId,
    this.shopOwner,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json["success"] ?? false,
      message: json["message"] ?? "",
      token: json["token"],
      firstLogin: json["firstLogin"] ?? false,
      ownerId: json["ownerId"],
      shopOwner: json["shop_owner"],
    );
  }
}