import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './app_colors.dart';
import '../services/notification_service.dart';

class ShopOwnerHeader extends StatefulWidget {
  const ShopOwnerHeader({super.key});

  @override
  State<ShopOwnerHeader> createState() => _ShopOwnerHeaderState();
}

class _ShopOwnerHeaderState extends State<ShopOwnerHeader> {
  int _unreadCount = 0;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
    // Polls every 30s so a "New Order Received" notification shows up on
    // the bell without the shop owner needing to manually refresh.
    _poll = Timer.periodic(const Duration(seconds: 30), (_) => _refreshUnreadCount());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {
      // Silent — a failed poll shouldn't show an error banner on every
      // screen; the bell just keeps its last known count.
    }
  }

  Future<void> _openNotifications() async {
    await context.push('/notifications');
    // Coming back from the notifications screen likely changed some
    // is_read flags — refresh the badge.
    _refreshUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          // Logo
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.brownLight,
            child: Text(
              "S",
              style: TextStyle(
                color: AppColors.brown,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Shop Name
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Thiraa Fashion",
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const Spacer(),

          // Notification
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: _openNotifications,
                icon: Icon(
                  Icons.notifications_none_outlined,
                  color: AppColors.textDark,
                  size: 28,
                ),
              ),

              if (_unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _unreadCount > 9 ? '9+' : '$_unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
