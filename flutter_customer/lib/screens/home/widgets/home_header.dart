import 'package:flutter/material.dart';
import '../../../widgets/app_colors.dart';

class HomeHeader extends StatelessWidget {
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onCartTap;

  final int cartCount;

  const HomeHeader({
    super.key,
    this.onMenuTap,
    this.onNotificationTap,
    this.onCartTap,
    this.cartCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        color: AppColors.background,
        padding: const EdgeInsets.symmetric(
          horizontal: AppColors.paddingMD,
          vertical: 12,
        ),
        child: Row(
          children: [

            /// Menu
            IconButton(
              onPressed: onMenuTap,
              icon: const Icon(Icons.menu_rounded),
            ),

            /// Logo
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/logo.jpeg',
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            /// Notification
            IconButton(
              onPressed: onNotificationTap,
              icon: const Icon(Icons.notifications_none_rounded),
            ),

            /// Cart
            Stack(
              clipBehavior: Clip.none,
              children: [

                IconButton(
                  onPressed: onCartTap,
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),

                if (cartCount > 0)
                  Positioned(
                    right: 6,
                    top: 4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        cartCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}