import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import './app_colors.dart';

class ShopOwnerSidebar extends StatelessWidget {
  final String currentPath;

  const ShopOwnerSidebar({super.key, required this.currentPath});

  static const double width = 270;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _item(context, Icons.home_filled, "Home", "/home"),

                _item(
                  context,
                  Icons.shopping_bag_outlined,
                  "Orders",
                  "/orders",
                ),

                _item(
                  context,
                  Icons.add_circle_outline,
                  "Add Product",
                  "/add-product",
                ),

                _item(context, Icons.sell_outlined, "Products", "/products"),

                _item(
                  context,
                  Icons.inventory_2_outlined,
                  "Inventory",
                  "/inventory",
                ),

                _item(context, Icons.bar_chart_outlined, "Reports", "/reports"),

                _item(
                  context,
                  Icons.account_balance_wallet_outlined,
                  "Earnings",
                  "/earnings",
                ),

                _item(context, Icons.person_outline, "Profile", "/profile"),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _showLogoutDialog(context),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.textDark),

                    const SizedBox(width: 12),

                    Text(
                      "Logout",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.sidebarBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Logout?",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
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
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) {
    final active = currentPath == route;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          context.go(route);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppColors.brownLight : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: active ? AppColors.brown : AppColors.textDark,
              ),

              const SizedBox(width: 16),

              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppColors.brown : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
