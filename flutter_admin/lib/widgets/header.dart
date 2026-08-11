import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 't_colors.dart';
import '../core/responsive.dart';

class AdminHeader extends StatefulWidget {
  final String title;
  final String subtitle;

  const AdminHeader({
    super.key,
    required this.title,
    this.subtitle = '',
  });

  @override
  State<AdminHeader> createState() => _AdminHeaderState();
}

class _AdminHeaderState extends State<AdminHeader> {
  bool _notifHovered   = false;
  bool _profileHovered = false;
  final int _notifCount = 4;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    debugPrint("Header isMobile: $isMobile");

    return SafeArea(
  bottom: false,
  child: Container(
      height: isMobile ? 70 : 58,
      padding: EdgeInsets.symmetric(
  horizontal: isMobile ? 16 : 24,
),
      decoration: const BoxDecoration(
        color: TColors.white,
        border: Border(bottom: BorderSide(color: TColors.border)),
      ),
      child: Row(
        children: [
          
  if (isMobile)
  IconButton(
    icon: const Icon(Icons.menu),
    onPressed: () {
      Scaffold.maybeOf(context)?.openDrawer();
    },
  ),

    if (isMobile)
      const SizedBox(width: 12),
          // Title + subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.title,
                  style: TextStyle(
                      fontSize: isMobile ? 18 : 15,
                      fontWeight: FontWeight.w600,
                      color: TColors.black)),
              if (widget.subtitle.isNotEmpty)
                Text(widget.subtitle,
                    style: TextStyle(
                        fontSize: isMobile ? 12 : 11, color: TColors.brownLight)),
            ],
          ),

          const Spacer(),

          // Notification bell
          _notificationBtn(),
          const SizedBox(width: 8),

          // Profile avatar — click → /profile
          _profileBtn(context),
        ],
      ),
  ),
    );
  }

  // ── Notification ─────────────────────────────────────────────────────────
  Widget _notificationBtn() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _notifHovered = true),
      onExit:  (_) => setState(() => _notifHovered = false),
      child: GestureDetector(
        onTap: () {
          // TODO: open notifications panel
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: _notifHovered ? TColors.cardBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.notifications_outlined, size: 20,
                  color: _notifHovered ? TColors.black : TColors.brown),
              if (_notifCount > 0)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE24B4A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile avatar only — no dropdown ────────────────────────────────────
  Widget _profileBtn(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _profileHovered = true),
      onExit:  (_) => setState(() => _profileHovered = false),
      child: GestureDetector(
        onTap: () => context.go('/profile'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
    isMobile ? 19 : 17,
),
            border: Border.all(
              color: _profileHovered ? TColors.border : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            width: isMobile ? 38 : 34,
height: isMobile ? 38 : 34,
            decoration: BoxDecoration(
              color: TColors.black,
              borderRadius: BorderRadius.circular(17),
            ),
            child: const Center(
              child: Text('SA',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: TColors.white)),
            ),
          ),
        ),
      ),
    );
  }
}