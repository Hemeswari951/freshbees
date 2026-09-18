import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/notification_count.dart';

// Same palette style used across the account/profile screens.
class _Palette {
  static const Color ink = Color(0xFF1A1A1D);
  static const Color surface = Colors.white;
  static const Color canvas = Color(0xFFF6F6F7);
  static const Color muted = Color(0xFF8A8A8E);
  static const Color line = Color(0xFFE7E7E9);
  static const Color accent = Color(0xFF17B978);
  static const Color accentSoft = Color(0xFFE4F7EE);
  static const Color danger = Color(0xFFE5484D);
}

/// Notifications page — reached by tapping the bell icon in the header.
/// Works the same way on web and mobile; only the outer max-width differs
/// so it doesn't stretch edge-to-edge on a wide browser window.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _page = 1;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await NotificationService.getNotifications(page: 1, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _notifications = items;
        _page = 1;
        _hasMore = items.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load notifications.';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final items = await NotificationService.getNotifications(page: nextPage, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _notifications = [..._notifications, ...items];
        _page = nextPage;
        _hasMore = items.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _markAllRead() async {
    // Optimistic — flip every item to read locally, reconcile with backend.
    final previous = _notifications;
    setState(() {
      _notifications = _notifications
          .map((n) => NotificationModel(
                notificationId: n.notificationId,
                notificationType: n.notificationType,
                orderId: n.orderId,
                orderItemId: n.orderItemId,
                title: n.title,
                message: n.message,
                isRead: true,
                createdAt: n.createdAt,
              ))
          .toList();
    });

   final ok = await NotificationService.markAllRead();

if (ok) {
  notificationCount.value = 0;
} else if (mounted) {
  setState(() => _notifications = previous);
}
  }

  Future<void> _onTapNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      // Optimistic — flip this one to read locally first.
      setState(() {
        final index = _notifications.indexWhere((n) => n.notificationId == notification.notificationId);
        if (index != -1) {
          _notifications[index] = NotificationModel(
            notificationId: notification.notificationId,
            notificationType: notification.notificationType,
            orderId: notification.orderId,
            orderItemId: notification.orderItemId,
            title: notification.title,
            message: notification.message,
            isRead: true,
            createdAt: notification.createdAt,
          );
        }
      });
    final ok = await NotificationService.markRead(
  notification.notificationId,
);

if (ok) {
  await syncNotificationCount();
}
    }

    if (!mounted) return;

    // Tapping a notification opens the Order Details screen for that order.
    // The orderItemId (when the notification carries one) rides along as
    // ?itemId= so the exact product the update was about gets highlighted
    // in the item list, instead of the user hunting for it.
    final orderId = notification.orderId;

    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No order linked to this notification')),
      );
      return;
    }

    final itemId = notification.orderItemId;

    final target = Uri(
      path: '/profile/details/orders/$orderId',
      queryParameters: itemId != null ? {'itemId': '$itemId'} : null,
    ).toString();

    context.push(target);
  }

  // "Close" — permanently removes the notification (DELETE), not just a
  // local hide. Optimistic removal, rolled back if the API call fails.
  Future<void> _closeNotification(NotificationModel notification) async {
    final previous = _notifications;
    final removedIndex = _notifications.indexWhere((n) => n.notificationId == notification.notificationId);
    setState(() {
      _notifications = _notifications
          .where((n) => n.notificationId != notification.notificationId)
          .toList();
    });

    final ok = await NotificationService.deleteNotification(notification.notificationId);
    if (!ok && mounted) {
      setState(() => _notifications = previous);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not remove notification, try again')),
      );
    }
  }

  bool get _hasUnread => _notifications.any((n) => !n.isRead);

  @override
  Widget build(BuildContext context) {
    // Mobile-only back button: on desktop the browser's own back
    // button is already visible in the toolbar, so we skip our own.
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    return Scaffold(
      backgroundColor: _Palette.canvas,
      appBar: AppBar(
        backgroundColor: _Palette.surface,
        surfaceTintColor: _Palette.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        automaticallyImplyLeading: !isDesktop,
        leading: isDesktop
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: _Palette.ink),
                onPressed: () => context.pop(),
              ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: _Palette.ink, fontWeight: FontWeight.w700, fontSize: 17),
        ),
        centerTitle: false,
        actions: [
          if (_hasUnread)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: _Palette.accent, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Caps the width on wide browser windows so cards don't
            // stretch edge-to-edge — same content, just centered on web.
            constraints: const BoxConstraints(maxWidth: 720),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _Palette.accent));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: _Palette.muted)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, size: 48, color: _Palette.muted.withOpacity(0.5)),
            const SizedBox(height: 12),
            const Text(
              'No notifications yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _Palette.ink),
            ),
            const SizedBox(height: 4),
            const Text(
              'Order updates will show up here.',
              style: TextStyle(fontSize: 13, color: _Palette.muted),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _Palette.accent,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _notifications.length + 1, // +1 for the "load more" footer
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == _notifications.length) {
            return _loadMoreFooter();
          }
          return _notificationCard(_notifications[index]);
        },
      ),
    );
  }

  Widget _loadMoreFooter() {
    if (!_hasMore) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : TextButton(onPressed: _loadMore, child: const Text('Load more')),
      ),
    );
  }

  Widget _notificationCard(NotificationModel notification) {
    final icon = notification.notificationType == 'new_order'
        ? Icons.shopping_bag_outlined
        : Icons.local_shipping_outlined;

    return Material(
      color: _Palette.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onTapNotification(notification),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: notification.isRead ? _Palette.line : _Palette.accent.withOpacity(0.4),
            ),
            // Unread gets a very light accent tint so it's scannable at a
            // glance, same idea as the sidebar's selected-item highlight.
            color: notification.isRead ? _Palette.surface : _Palette.accentSoft.withOpacity(0.4),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(color: _Palette.canvas, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: _Palette.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.w800,
                              color: _Palette.ink,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6, top: 4),
                            decoration: const BoxDecoration(color: _Palette.accent, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(fontSize: 13, color: _Palette.ink, height: 1.4),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(notification.createdAt),
                      style: const TextStyle(fontSize: 11, color: _Palette.muted),
                    ),
                  ],
                ),
              ),
              // Close button — permanently removes this notification.
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: _Palette.muted),
                onPressed: () => _closeNotification(notification),
                tooltip: 'Remove',
                splashRadius: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}