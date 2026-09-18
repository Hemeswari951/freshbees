class TryOnProfile {
  final int profileId;
  final int customerId;
  final String profileName;
  final String relationship;
  final String? gender;
  final String? dateOfBirth;
  final String? size;
  final double? height;
  final double? weight;
  final String? photoUrl;
  final bool isDefault;

  TryOnProfile({
    required this.profileId,
    required this.customerId,
    required this.profileName,
    required this.relationship,
    this.gender,
    this.dateOfBirth,
    this.size,
    this.height,
    this.weight,
    this.photoUrl,
    required this.isDefault,
  });

  factory TryOnProfile.fromJson(Map<String, dynamic> json) {
    print('TRYON PROFILE JSON: $json');
  print(
    'TRYON PROFILE JSON DOB: ${json['date_of_birth']}',
  );
    return TryOnProfile(
      profileId:
          int.tryParse(json['profile_id'].toString()) ?? 0,

      customerId:
          int.tryParse(json['customer_id'].toString()) ?? 0,

      profileName:
          json['profile_name']?.toString() ?? '',

      relationship:
          json['relationship']?.toString() ?? '',

      gender:
          json['gender']?.toString(),

      dateOfBirth:
          json['date_of_birth']?.toString(),

      size:
          json['size']?.toString(),

      height: json['height'] != null
          ? double.tryParse(json['height'].toString())
          : null,

      weight: json['weight'] != null
          ? double.tryParse(json['weight'].toString())
          : null,

      photoUrl:
          json['photo_url']?.toString(),

      isDefault:
          json['is_default'] == true,
    );
  }
}

