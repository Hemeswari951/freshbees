import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
 
import './app_colors.dart';
 
class CustomerFooter extends StatelessWidget {
  final String currentPath;
 
  const CustomerFooter({super.key, required this.currentPath});
 
  int get currentIndex {
    switch (currentPath) {
      case "/home":
        return 0;
 
      case "/trial":
        return 1;
 
      case "/wishlist":
        return 2;
 
      case "/profile":
        return 3;
 
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
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _item(context, 0, Icons.home_filled, "Home", "/home"),
 
            _item(context, 1, Icons.videocam_outlined, "Trial", "/trial"),
 
            _item(context, 2, Icons.favorite_border, "Wishlist", "/wishlist"),
 
            _item(context, 3, Icons.person_outline, "Profile", "/profile"),
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