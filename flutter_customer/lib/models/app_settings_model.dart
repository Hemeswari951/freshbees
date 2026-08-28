/// Maps directly to the app_settings row — the customer settings
/// controller returns raw DB column names (snake_case), unlike the other
/// customer endpoints which map to camelCase, so this model parses
/// snake_case keys as-is.
class AppSettingsModel {
  final String? appName;
  final String? appLogo;
  final String? faviconUrl;
  final String? appVersion;
  final String? supportEmail;
  final String? supportPhone;
  final String? whatsappNumber;
  final String? websiteUrl;
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? youtubeUrl;
  final String? linkedinUrl;
  final String? companyName;
  final String? copyrightText;
  final String? privacyPolicyLink;
  final String? termsLink;
  final String? officeAddress;
  final String? contactEmail;
  final String? contactPhone;
  final String? workingHours;

  AppSettingsModel({
    this.appName,
    this.appLogo,
    this.faviconUrl,
    this.appVersion,
    this.supportEmail,
    this.supportPhone,
    this.whatsappNumber,
    this.websiteUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.youtubeUrl,
    this.linkedinUrl,
    this.companyName,
    this.copyrightText,
    this.privacyPolicyLink,
    this.termsLink,
    this.officeAddress,
    this.contactEmail,
    this.contactPhone,
    this.workingHours,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      appName: json['app_name'],
      appLogo: json['app_logo'],
      faviconUrl: json['favicon_url'],
      appVersion: json['app_version'],
      supportEmail: json['support_email'],
      supportPhone: json['support_phone'],
      whatsappNumber: json['whatsapp_number'],
      websiteUrl: json['website_url'],
      facebookUrl: json['facebook_url'],
      instagramUrl: json['instagram_url'],
      twitterUrl: json['twitter_url'],
      youtubeUrl: json['youtube_url'],
      linkedinUrl: json['linkedin_url'],
      companyName: json['company_name'],
      copyrightText: json['copyright_text'],
      privacyPolicyLink: json['privacy_policy_link'],
      termsLink: json['terms_link'],
      officeAddress: json['office_address'],
      contactEmail: json['contact_email'],
      contactPhone: json['contact_phone'],
      workingHours: json['working_hours'],
    );
  }
}