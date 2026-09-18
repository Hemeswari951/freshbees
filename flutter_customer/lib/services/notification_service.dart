import '../models/notification_model.dart';
import 'api_service.dart';

class NotificationService {
  NotificationService._();

  static Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.get('/notifications?page=$page&limit=$limit');

    if (response is Map<String, dynamic> && response['data'] != null) {
      return (response['data'] as List)
          .map((e) => NotificationModel.fromJson(e))
          .toList();
    }
    throw Exception('Failed to load notifications');
  }

  static Future<int> getUnreadCount() async {
    final response = await ApiService.get('/notifications/unread-count');
    if (response is Map<String, dynamic> && response['data'] != null) {
      return response['data']['count'] ?? 0;
    }
    return 0;
  }

  static Future<bool> markRead(int notificationId) async {
    final response = await ApiService.patch('/notifications/$notificationId/read', {});
    return response is Map<String, dynamic> && response['success'] == true;
  }

  static Future<bool> markAllRead() async {
    final response = await ApiService.patch('/notifications/read-all', {});
    return response is Map<String, dynamic> && response['success'] == true;
  }

  /// "Close" — permanently removes the notification (not just marks read).
  static Future<bool> deleteNotification(int notificationId) async {
    final response = await ApiService.delete('/notifications/$notificationId');
    return response is Map<String, dynamic> && response['success'] == true;
  }
}