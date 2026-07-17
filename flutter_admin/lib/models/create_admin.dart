class CreateAdmin {
  final String fullName;
  final String username;
  final String email;
  final String password;
  final String role;
  final bool isActive;

  CreateAdmin({
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      "full_name": fullName,
      "username": username,
      "email": email,
      "password": password,
      "role": role,
      "is_active": isActive,
    };
  }
}