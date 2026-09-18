import 'package:flutter/foundation.dart';
import 'notification_service.dart';

final ValueNotifier<int> notificationCount = ValueNotifier<int>(0);

Future<void> syncNotificationCount() async {
  try {
    final count = await NotificationService.getUnreadCount();
    notificationCount.value = count;
  } catch (_) {
    // Keep existing count if API fails
  }
}