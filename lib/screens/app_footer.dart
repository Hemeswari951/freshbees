import 'package:flutter/material.dart';
import 'main_scaffold.dart';
import 'home_screen.dart';
import 'offers_screen.dart';
import 'wishlist_screen.dart';
import 'bag_screen.dart';

/// Footer pushes a fresh MainScaffold wrapping the target page's
/// content directly - no named routes, no separate navigation file.
class AppFooter extends StatelessWidget {
  final int currentIndex;

  const AppFooter({super.key, required this.currentIndex});

  static const List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home_outlined, 'activeIcon': Icons.home_rounded, 'label': 'Home'},
    {'icon': Icons.local_offer_outlined, 'activeIcon': Icons.local_offer_rounded, 'label': 'Offers'},
    {'icon': Icons.favorite_border_rounded, 'activeIcon': Icons.favorite_rounded, 'label': 'Wishlist'},
    {'icon': Icons.shopping_bag_outlined, 'activeIcon': Icons.shopping_bag_rounded, 'label': 'Bag'},
  ];

  // Returns the plain content widget for a given tab index.
  Widget _pageFor(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const OffersScreen();
      case 2:
        return const WishlistScreen();
      case 3:
        return const BagScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.card,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: List.generate(_navItems.length, (index) {
          final bool isSelected = currentIndex == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (!isSelected) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MainScaffold(currentIndex: index, body: _pageFor(index)),
                    ),
                  );
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isSelected ? _navItems[index]['activeIcon'] : _navItems[index]['icon'],
                    color: isSelected ? AppColors.accent : AppColors.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _navItems[index]['label'],
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}