class NotificationModel {
  final int notificationId;
  final String notificationType; // 'new_order' | 'status_update'
  final int? orderId;
  final int? orderItemId;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.notificationType,
    this.orderId,
    this.orderItemId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'],
      notificationType: json['notification_type'] ?? '',
      orderId: json['order_id'],
      orderItemId: json['order_item_id'],
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}