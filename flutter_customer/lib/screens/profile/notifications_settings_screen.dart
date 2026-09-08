import 'package:flutter/material.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  static const Color _bg = Color(0xFFF6F6F7);
  static const Color _surface = Colors.white;
  static const Color _ink = Color(0xFF1A1A1D);
  static const Color _muted = Color(0xFF8A8A8E);
  static const Color _line = Color(0xFFE7E7E9);
  static const Color _accent = Color(0xFF8B7355);
  static const Color _accentSoft = Color(0xFFF2ECE4);

  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Container(
      width: double.infinity,
      color: _bg,
      child: isDesktop ? _buildDesktopContent() : _buildMobileContent(context),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _buildNotificationSettings(),
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileHeader(context),
          const SizedBox(height: 24),
          _buildNotificationSettings(),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE HEADER
  // ============================================================

  Widget _buildMobileHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () {
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: _line),
            ),
            child: const Icon(Icons.arrow_back, size: 20, color: _ink),
          ),
        ),

        const SizedBox(width: 14),

        const Text(
          'Notification Settings',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NOTIFICATION SETTINGS
  // ============================================================

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Manage your notification preferences',
          style: TextStyle(color: _muted, fontSize: 13),
        ),

        const SizedBox(height: 20),

        _buildNotificationToggle(),
      ],
    );
  }

  // ============================================================
  // NOTIFICATION TOGGLE
  // ============================================================

  Widget _buildNotificationToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              color: _accent,
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will get you notified',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Receive notifications about orders, offers and updates.',
                  style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Switch.adaptive(
            value: _notificationsEnabled,
            activeColor: _accent,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
