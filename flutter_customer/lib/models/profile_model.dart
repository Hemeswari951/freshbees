
class ProfileModel {
  final int customerId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? profileImage;
  final String? gender;
  final String? city;
  final String? state;
  final String? dateOfBirth;
  final bool isVerified;

  // Style profile
  final int? styleProfileId;
  final String? apparelSize;
  final String? fitPreference;
  final List<String> preferredColors;
  final List<String> preferredStyles;

  ProfileModel({
    required this.customerId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.profileImage,
    this.gender,
    this.city,
    this.state,
    this.dateOfBirth,
    required this.isVerified,
    this.styleProfileId,
    this.apparelSize,
    this.fitPreference,
    this.preferredColors = const [],
    this.preferredStyles = const [],
  });

  String get fullName {
    return '$firstName $lastName'.trim();
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      customerId:
          int.tryParse(json['customer_id'].toString()) ?? 0,

      firstName:
          json['first_name']?.toString() ?? '',

      lastName:
          json['last_name']?.toString() ?? '',

      email:
          json['email']?.toString(),

      phone:
          json['phone']?.toString(),

      profileImage:
          json['profile_image']?.toString(),

      gender:
          json['gender']?.toString(),

      city:
          json['city']?.toString(),

      state:
          json['state']?.toString(),

      dateOfBirth:
          json['date_of_birth']?.toString(),

      isVerified:
          json['is_verified'] == true,

      styleProfileId:
          json['style_profile_id'] != null
              ? int.tryParse(
                  json['style_profile_id'].toString(),
                )
              : null,

      apparelSize:
          json['apparel_size']?.toString(),

      fitPreference:
          json['fit_preference']?.toString(),

      preferredColors:
          _stringList(json['preferred_colors']),

      preferredStyles:
          _stringList(json['preferred_styles']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value == null) {
      return [];
    }

    if (value is List) {
      return value
          .map((item) => item.toString())
          .toList();
    }

    return [];
  }
}