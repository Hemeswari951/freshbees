import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import './app_colors.dart';

class ShopOwnerFooter extends StatelessWidget {
  final String currentPath;

  const ShopOwnerFooter({super.key, required this.currentPath});

  int get currentIndex {
    switch (currentPath) {
      case "/home":
        return 0;

      case "/orders":
        return 1;

      case "/products":
        return 3;

      case "/profile":
        return 4;

      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.white,
      elevation: 4,
      shadowColor: Colors.black12,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(context, 0, Icons.home_filled, "Home", "/home"),

            _item(context, 1, Icons.shopping_bag_outlined, "Orders", "/orders"),

            InkWell(
              onTap: () {
                context.go("/add-product");
              },
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textDark,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
            ),

            _item(context, 3, Icons.sell_outlined, "Products", "/products"),

            _item(context, 4, Icons.person_outline, "Profile", "/profile"),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    String route,
  ) {
    final active = currentIndex == index;

    return InkWell(
      onTap: () {
        context.go(route);
      },
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? AppColors.black : AppColors.textGrey,
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? AppColors.black : AppColors.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
