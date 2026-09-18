import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_colors.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await NotificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _onTapNotification(Map<String, dynamic> n) async {
    if (n['is_read'] != true) {
      try {
        await NotificationService.markRead(n['notification_id']);
        setState(() => n['is_read'] = true);
      } catch (_) {
        // Non-fatal — the notification still opens even if "mark read" fails.
      }
    }

    final orderId = n['order_id'];
    if (orderId != null && mounted) {
      context.push('/orders/$orderId');
    }
  }

  Future<void> _markAllRead() async {
    try {
      await NotificationService.markAllRead();
      setState(() {
        for (final n in _items) {
          n['is_read'] = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: _items.isEmpty ? null : _markAllRead,
            child: const Text('Mark all read', style: TextStyle(color: AppColors.accentBrown, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.brown));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42, color: AppColors.warning),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textGrey)),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _load, child: const Text('RETRY')),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 46, color: AppColors.textLight),
            SizedBox(height: 12),
            Text('No notifications yet', style: TextStyle(color: AppColors.textGrey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.brown,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _NotificationTile(
          data: _items[i],
          onTap: () => _onTapNotification(_items[i]),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _NotificationTile({required this.data, required this.onTap});

  IconData get _icon {
    switch (data['notification_type']) {
      case 'new_order':
        return Icons.shopping_bag_rounded;
      case 'status_update':
        return Icons.local_shipping_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = data['is_read'] == true;
    final createdAt = DateTime.tryParse(data['created_at']?.toString() ?? '');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isRead ? AppColors.card : AppColors.brownLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.white),
              child: Icon(_icon, size: 18, color: AppColors.accentBrown),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                      fontSize: 13.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(data['message'] ?? '', style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(_timeAgo(createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
                  ],
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  static String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
