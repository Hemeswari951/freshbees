import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

import './app_colors.dart';
import '../services/profile_service.dart';
import '../services/notification_service.dart';
 
class ShopOwnerHeader extends StatefulWidget {
  const ShopOwnerHeader({super.key});
 
  @override
  State<ShopOwnerHeader> createState() => _ShopOwnerHeaderState();
}
 
class _ShopOwnerHeaderState extends State<ShopOwnerHeader> {
  // Seed from whatever's already cached (e.g. from a previous screen's
  // header, or from the Home/Profile screen having already loaded it) so
  // there's no flash of placeholder text when navigating between screens.
  ShopProfile? _profile = ProfileService.cachedProfile;
  bool _logoFailed = false;
   int _unreadCount = 0;
  Timer? _poll;
 
  @override
  void initState() {
    super.initState();
    _loadProfile();
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


  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileService.getProfileCached();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _logoFailed = false;
      });
    } catch (_) {
      // Shop details couldn't be loaded (e.g. offline) — keep showing
      // whatever we already have (or the fallback defaults below) rather
      // than breaking the header.
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final shopName = (_profile?.shopName.trim().isNotEmpty ?? false)
        ? _profile!.shopName.trim()
        : "Your Shop";
    final address = _profile?.address?.trim();
    final city = _profile?.city?.trim();
    final pincode = _profile?.pincode?.trim();
    // "<address>, <city> - <pincode>" — each part is optional and only
    // included (with the right separator) when the Admin actually set it,
    // so a shop missing a city or pincode still renders cleanly.
    final addressLine = [
      if (address != null && address.isNotEmpty) address,
      if (city != null && city.isNotEmpty) city,
    ].join(', ');
    final locationLine = (pincode != null && pincode.isNotEmpty)
        ? (addressLine.isNotEmpty ? '$addressLine - $pincode' : pincode)
        : addressLine;
    final logoUrl = _profile?.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty && !_logoFailed;
    final initial = shopName.isNotEmpty ? shopName[0].toUpperCase() : "S";
 
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
          // Logo — shows the Admin-provided shop logo, falling back to the
          // shop name's initial letter when no logo is set or it fails to
          // load, so the circular avatar area always renders correctly.
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.brownLight,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasLogo
                ? Image.network(
                    ProfileService.fullImageUrl(logoUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      // Defer the setState until after this build finishes.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_logoFailed) {
                          setState(() => _logoFailed = true);
                        }
                      });
                      return _initialAvatar(initial);
                    },
                  )
                : _initialAvatar(initial),
          ),
 
          const SizedBox(width: 14),
 
          // Shop Name + Address — fetched dynamically for the logged-in
          // shop owner's shop rather than hardcoded.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (locationLine.isNotEmpty)
                  Text(
                    locationLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
 
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
 
  Widget _initialAvatar(String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.brown,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}