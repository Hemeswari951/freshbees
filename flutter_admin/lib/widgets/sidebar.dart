import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 't_colors.dart';
import '../services/auth_service.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  int? hoveredTab; // tracks which tile is hovered

  // route string for each tab index
  String _route(int tab) {
    switch (tab) {
      case 0:
        return '/dashboard';
      case 1:
        return '/shops';
      case 2:
        return '/customers';
      case 3:
        return '/products';
      case 4:
        return '/orders';
      case 5:
        return '/categories';
      case 6:
        return '/payouts';
      case 7:
        return '/banners';
      case 8:
        return '/reports';
      case 9:
        return '/settings';
      default:
        return '/dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: 210,
      decoration: const BoxDecoration(
        color: TColors.cream,
        border: Border(right: BorderSide(color: TColors.border)),
      ),
      child: Column(
        children: [
          _buildLogo(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _label('MAIN'),
                _tile(
                  context,
                  currentPath,
                  Icons.dashboard_outlined,
                  'Dashboard',
                  0,
                ),
                _tile(
                  context,
                  currentPath,
                  Icons.storefront_outlined,
                  'Shops',
                  1,
                ),
                _tile(
                  context,
                  currentPath,
                  Icons.people_outline,
                  'Customers',
                  2,
                ),
                _tile(
                  context,
                  currentPath,
                  Icons.inventory_2_outlined,
                  'Products',
                  3,
                ),
                _tile(
                  context,
                  currentPath,
                  Icons.receipt_long_outlined,
                  'Orders',
                  4,
                ),
                const SizedBox(height: 16),
                _label('CONFIG'),
                _tile(
                  context,
                  currentPath,
                  Icons.category_outlined,
                  'Categories',
                  5,
                ),
                _tile(
                  context,
                  currentPath,
                  Icons.account_balance_wallet_outlined,
                  'Payouts',
                  6,
                ),
                _tile(context, currentPath, Icons.image_outlined, 'Banners', 7),
                _tile(
                  context,
                  currentPath,
                  Icons.bar_chart_outlined,
                  'Reports',
                  8,
                ),
              ],
            ),
          ),
          _buildBottom(context, currentPath),
        ],
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────
  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TColors.border)),
      ),
      child: Row(
        children: [
          ClipOval(
            child: Image.asset(
              'assets/images/logo.jpeg',
              width: 34,
              height: 34,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THIRAA',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: TColors.black,
                ),
              ),
              Text(
                'Admin Portal',
                style: TextStyle(fontSize: 11, color: TColors.brownLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section label ─────────────────────────────────────────────────────────
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 0, 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: TColors.brownLight,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // ── Nav tile ──────────────────────────────────────────────────────────────
  Widget _tile(
    BuildContext context,
    String currentPath,
    IconData icon,
    String title,
    int tab,
  ) {
    final active = currentPath == _route(tab);
    final hovered = hoveredTab == tab;

    // active = black bg, hovered = card bg, else transparent
    Color bg = Colors.transparent;
    if (active)
      bg = TColors.black;
    else if (hovered)
      bg = TColors.cardBg;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hoveredTab = tab),
      onExit: (_) => setState(() => hoveredTab = null),
      child: GestureDetector(
        onTap: () => context.go(_route(tab)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: active ? TColors.white : TColors.brown,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? TColors.white : TColors.brown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Bottom: Settings + Logout ─────────────────────────────────────────────
  Widget _buildBottom(BuildContext context, String currentPath) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: TColors.border)),
      ),
      child: Column(
        children: [
          // Settings tile
          _tile(context, currentPath, Icons.settings_outlined, 'Settings', 9),
          const SizedBox(height: 2),
          // Logout tile
          _logoutTile(context),
        ],
      ),
    );
  }

  Widget _logoutTile(BuildContext context) {
    final hovered = hoveredTab == 99; // 99 = logout hover id

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hoveredTab = 99),
      onExit: (_) => setState(() => hoveredTab = null),
      child: GestureDetector(
        onTap: () => _showLogoutDialog(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: hovered
                ? TColors.red.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                size: 17,
                color: hovered ? TColors.red : TColors.brown,
              ),
              const SizedBox(width: 10),
              Text(
                'Log out',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: hovered ? TColors.red : TColors.brown,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Logout dialog ─────────────────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: TColors.cream,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Log out?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: TColors.black,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontSize: 13, color: TColors.brown),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: TColors.brownLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: TColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);

              try {
                await AuthService().logout();

                if (context.mounted) {
                  context.go("/login");
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst("Exception: ", ""),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Log out',
              style: TextStyle(color: TColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
