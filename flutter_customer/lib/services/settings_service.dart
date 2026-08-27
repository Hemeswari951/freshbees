import '../models/app_settings_model.dart';
import 'api_service.dart';

class SettingsService {
  SettingsService._();

  static Future<AppSettingsModel> getSettings() async {
    final response = await ApiService.get('/settings');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return AppSettingsModel.fromJson(response['data']);
    }
    throw Exception('Failed to load settings');
  }
}