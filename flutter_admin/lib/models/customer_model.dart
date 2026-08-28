// lib/models/customer_model.dart
//
// Maps directly to the JSON your customer.model.js queries return.
// Field names here match the customers table columns (snake_case in
// Postgres -> we read them by that same key from the JSON response).

class DashboardStats {
  final int totalCustomers;
  final int newCustomersToday;
  final int blockedCustomers;

  DashboardStats({
    required this.totalCustomers,
    required this.newCustomersToday,
    required this.blockedCustomers,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalCustomers: json['totalCustomers'] ?? 0,
      newCustomersToday: json['newCustomersToday'] ?? 0,
      blockedCustomers: json['blockedCustomers'] ?? 0,
    );
  }
}

class Customer {
  final int customerId;
  final String? profileImage;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? city;
  final String? state;
  final String? gender;
  final String? dateOfBirth;
  final DateTime? lastLogin;
  final DateTime? createdAt;
  bool isBlocked; // mutable so we can flip it instantly in the UI

  Customer({
    required this.customerId,
    this.profileImage,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.city,
    this.state,
    this.gender,
    this.dateOfBirth,
    this.lastLogin,
    this.createdAt,
    required this.isBlocked,
  });

  // Full name shown in the list & detail panel
  String get fullName => '$firstName $lastName'.trim();

  // "JD", "AK" style initials for the avatar circle when there's no image
  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return (f + l).toUpperCase();
  }

  String get statusLabel => isBlocked ? 'Blocked' : 'Unblocked';

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerId: json['customer_id'],
      profileImage: json['profile_image'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      city: json['city'],
      state: json['state'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      lastLogin: json['last_login'] != null
          ? DateTime.tryParse(json['last_login'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      isBlocked: json['is_blocked'] ?? false,
    );
  }
}
