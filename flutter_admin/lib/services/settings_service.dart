// ============================================================================
//  services/settings_service.dart
//  Talks to /api/admin/settings/*  — built on top of your ApiService
//  UPDATED: uploadLogo / uploadFavicon now take Uint8List (web-compatible)
//           instead of dart:io File which doesn't work on Flutter Web
// ============================================================================
 
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/settings_model.dart';
import 'api_service.dart';
 
class SettingsService {
  static const String _section = '/settings';
 
  // ── GET /api/admin/settings ──────────────────────────────────────────────
  Future<SettingsModel> getSettings() async {
    final body = await ApiService.get(_section);
    return SettingsModel.fromJson(body['data']);
  }
 
  // ── PUT /settings/app-info — 1.1 text fields ────────────────────────────
  Future<SettingsModel> updateAppInfo(SettingsModel s) async {
    final body = await ApiService.put('$_section/app-info', s.toAppInfoJson());
    return _merge(body, s);
  }
 
  // ── POST /settings/app-logo — multipart (bytes, web-safe) ───────────────
  // Returns the logo URL saved in DB (e.g. http://localhost:3000/uploads/logo/logo_1234.png)
  Future<String> uploadLogo(Uint8List bytes, String filename) async {
    final data = await _multipart('$_section/app-logo', 'logo', bytes, filename);
    return data['app_logo'] as String? ?? '';
  }
 
  // ── POST /settings/favicon — multipart (bytes, web-safe) ────────────────
  Future<String> uploadFavicon(Uint8List bytes, String filename) async {
    final data = await _multipart('$_section/favicon', 'favicon', bytes, filename);
    return data['favicon_url'] as String? ?? '';
  }
 
  // ── PUT /settings/contact — 1.2 ─────────────────────────────────────────
  Future<SettingsModel> updateContact(SettingsModel s) async {
    final body = await ApiService.put('$_section/contact', s.toContactJson());
    return _merge(body, s);
  }
 
  // ── PUT /settings/social — 1.3 ──────────────────────────────────────────
  Future<SettingsModel> updateSocial(SettingsModel s) async {
    final body = await ApiService.put('$_section/social', s.toSocialJson());
    return _merge(body, s);
  }
 
  // ── PUT /settings/footer — 1.4 ──────────────────────────────────────────
  Future<SettingsModel> updateFooter(SettingsModel s) async {
    final body = await ApiService.put('$_section/footer', s.toFooterJson());
    return _merge(body, s);
  }
 
  // ── PUT /settings/contact-us — 1.5 ──────────────────────────────────────
  Future<SettingsModel> updateContactUs(SettingsModel s) async {
    final body = await ApiService.put('$_section/contact-us', s.toContactUsJson());
    return _merge(body, s);
  }
 
  // ── Multipart helper (no dart:io — works on Flutter Web) ─────────────────
  Future<Map<String, dynamic>> _multipart(
    String endpoint,
    String fieldName,
    Uint8List bytes,
    String filename,
  ) async {
    final uri     = Uri.parse('${ApiService.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', uri);
 
    final token = ApiService.getToken();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
 
    request.files.add(
      http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
    );
 
    final streamed = await request.send();
    final res      = await http.Response.fromStream(streamed);
 
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      throw Exception('Upload failed — server returned invalid JSON (${res.statusCode})');
    }
 
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['error'] ?? body['message'] ?? 'Upload failed');
  }
 
  // ── Merge partial response into current model ────────────────────────────
  // Each section PUT returns only its own columns, so we merge rather than
  // replace the whole model.
  SettingsModel _merge(Map<String, dynamic> body, SettingsModel current) {
    final data = (body['data'] as Map<String, dynamic>?) ?? {};
    return SettingsModel.fromJson({..._toMap(current), ...data});
  }
 
  Map<String, dynamic> _toMap(SettingsModel s) => {
    'app_name':           s.appName,
    'app_logo':           s.appLogo,
    'favicon_url':        s.faviconUrl,
    'app_version':        s.appVersion,
    'support_email':      s.supportEmail,
    'support_phone':      s.supportPhone,
    'whatsapp_number':    s.whatsappNumber,
    'website_url':        s.websiteUrl,
    'facebook_url':       s.facebookUrl,
    'instagram_url':      s.instagramUrl,
    'twitter_url':        s.twitterUrl,
    'youtube_url':        s.youtubeUrl,
    'linkedin_url':       s.linkedinUrl,
    'company_name':       s.companyName,
    'copyright_text':     s.copyrightText,
    'privacy_policy_link':s.privacyPolicyLink,
    'terms_link':         s.termsLink,
    'office_address':     s.officeAddress,
    'contact_email':      s.contactEmail,
    'contact_phone':      s.contactPhone,
    'working_hours':      s.workingHours,
  };
}
 