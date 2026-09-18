import 'api_service.dart';

class NotificationService {
  NotificationService._();

  /// GET /api/shop-owner/notifications?page=1&limit=20
  static Future<List<Map<String, dynamic>>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await ApiService.get('/notifications?page=$page&limit=$limit');
    final List list = response['data'] as List;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// GET /api/shop-owner/notifications/unread-count
  static Future<int> getUnreadCount() async {
    final response = await ApiService.get('/notifications/unread-count');
    final data = Map<String, dynamic>.from(response['data'] as Map);
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  /// PATCH /api/shop-owner/notifications/:notificationId/read
  static Future<void> markRead(int notificationId) async {
    await ApiService.patch('/notifications/$notificationId/read', {});
  }

  /// PATCH /api/shop-owner/notifications/read-all
  static Future<void> markAllRead() async {
    await ApiService.patch('/notifications/read-all', {});
  }
}
