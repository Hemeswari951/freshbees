// ============================================================================
//  models/settings_model.dart
//  Mirrors the app_settings table — GET /api/admin/settings response
// ============================================================================
 
class SettingsModel {
 
  // 1.1 Application information
  final String  appName;
  final String? appLogo;       // stored as URL: http://localhost:3000/uploads/logo/logo_123.png
  final String? faviconUrl;    // stored as URL: http://localhost:3000/uploads/favicon/fav_123.ico
  final String  appVersion;    // read-only — set in backend .env
 
  // 1.2 Contact information
  final String? supportEmail;
  final String? supportPhone;
  final String? whatsappNumber;
  final String? websiteUrl;
 
  // 1.3 Social media links
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? youtubeUrl;
  final String? linkedinUrl;
 
  // 1.4 Footer information
  final String? companyName;
  final String? copyrightText;
  final String? privacyPolicyLink;
  final String? termsLink;
 
  // 1.5 Contact us details
  final String? officeAddress;
  final String? contactEmail;
  final String? contactPhone;
  final String? workingHours;
 
  final DateTime? updatedAt;
 
  SettingsModel({
    required this.appName,
    this.appLogo,
    this.faviconUrl,
    this.appVersion = 'v1.0.0',
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
    this.updatedAt,
  });
 
  factory SettingsModel.empty() => SettingsModel(appName: '');
 
  // Maps GET /api/admin/settings → { success: true, data: {...} }
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      appName:           json['app_name']           ?? '',
      appLogo:           json['app_logo'],
      faviconUrl:        json['favicon_url'],
      appVersion:        json['app_version']         ?? 'v1.0.0',
      supportEmail:      json['support_email'],
      supportPhone:      json['support_phone'],
      whatsappNumber:    json['whatsapp_number'],
      websiteUrl:        json['website_url'],
      facebookUrl:       json['facebook_url'],
      instagramUrl:      json['instagram_url'],
      twitterUrl:        json['twitter_url'],
      youtubeUrl:        json['youtube_url'],
      linkedinUrl:       json['linkedin_url'],
      companyName:       json['company_name'],
      copyrightText:     json['copyright_text'],
      privacyPolicyLink: json['privacy_policy_link'],
      termsLink:         json['terms_link'],
      officeAddress:     json['office_address'],
      contactEmail:      json['contact_email'],
      contactPhone:      json['contact_phone'],
      workingHours:      json['working_hours'],
      updatedAt:         json['updated_at'] != null
                           ? DateTime.tryParse(json['updated_at'])
                           : null,
    );
  }
 
  // copyWith — used after each section save to merge new values in
  SettingsModel copyWith({
    String? appName,
    String? appLogo,
    String? faviconUrl,
    String? appVersion,
    String? supportEmail,
    String? supportPhone,
    String? whatsappNumber,
    String? websiteUrl,
    String? facebookUrl,
    String? instagramUrl,
    String? twitterUrl,
    String? youtubeUrl,
    String? linkedinUrl,
    String? companyName,
    String? copyrightText,
    String? privacyPolicyLink,
    String? termsLink,
    String? officeAddress,
    String? contactEmail,
    String? contactPhone,
    String? workingHours,
  }) {
    return SettingsModel(
      appName:           appName           ?? this.appName,
      appLogo:           appLogo           ?? this.appLogo,
      faviconUrl:        faviconUrl        ?? this.faviconUrl,
      appVersion:        appVersion        ?? this.appVersion,
      supportEmail:      supportEmail      ?? this.supportEmail,
      supportPhone:      supportPhone      ?? this.supportPhone,
      whatsappNumber:    whatsappNumber    ?? this.whatsappNumber,
      websiteUrl:        websiteUrl        ?? this.websiteUrl,
      facebookUrl:       facebookUrl       ?? this.facebookUrl,
      instagramUrl:      instagramUrl      ?? this.instagramUrl,
      twitterUrl:        twitterUrl        ?? this.twitterUrl,
      youtubeUrl:        youtubeUrl        ?? this.youtubeUrl,
      linkedinUrl:       linkedinUrl       ?? this.linkedinUrl,
      companyName:       companyName       ?? this.companyName,
      copyrightText:     copyrightText     ?? this.copyrightText,
      privacyPolicyLink: privacyPolicyLink ?? this.privacyPolicyLink,
      termsLink:         termsLink         ?? this.termsLink,
      officeAddress:     officeAddress     ?? this.officeAddress,
      contactEmail:      contactEmail      ?? this.contactEmail,
      contactPhone:      contactPhone      ?? this.contactPhone,
      workingHours:      workingHours      ?? this.workingHours,
      updatedAt:         updatedAt,
    );
  }
 
  // ── Per-section JSON builders ─────────────────────────────────────────────
  // Blank strings are dropped so COALESCE in backend preserves existing DB value.
  // Sending "" would overwrite existing data — this prevents that.
 
  Map<String, dynamic> _clean(Map<String, dynamic> fields) {
    return Map.fromEntries(
      fields.entries.where((e) => e.value != null && e.value.toString().trim().isNotEmpty),
    );
  }
 
  // 1.1 — sent by PUT /api/admin/settings/app-info
  Map<String, dynamic> toAppInfoJson() => _clean({'app_name': appName});
 
  // 1.2 — sent by PUT /api/admin/settings/contact
  Map<String, dynamic> toContactJson() => _clean({
    'support_email':   supportEmail,
    'support_phone':   supportPhone,
    'whatsapp_number': whatsappNumber,
    'website_url':     websiteUrl,
  });
 
  // 1.3 — sent by PUT /api/admin/settings/social
  Map<String, dynamic> toSocialJson() => _clean({
    'facebook_url':  facebookUrl,
    'instagram_url': instagramUrl,
    'twitter_url':   twitterUrl,
    'youtube_url':   youtubeUrl,
    'linkedin_url':  linkedinUrl,
  });
 
  // 1.4 — sent by PUT /api/admin/settings/footer
  Map<String, dynamic> toFooterJson() => _clean({
    'company_name':        companyName,
    'copyright_text':      copyrightText,
    'privacy_policy_link': privacyPolicyLink,
    'terms_link':          termsLink,
  });
 
  // 1.5 — sent by PUT /api/admin/settings/contact-us
  Map<String, dynamic> toContactUsJson() => _clean({
    'office_address': officeAddress,
    'contact_email':  contactEmail,
    'contact_phone':  contactPhone,
    'working_hours':  workingHours,
  });
}
 