import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import './app_colors.dart';

class CustomerHeader extends StatefulWidget {
  const CustomerHeader({super.key});

  @override
  State<CustomerHeader> createState() => _CustomerHeaderState();
}

class _CustomerHeaderState extends State<CustomerHeader> {
  final TextEditingController _searchController = TextEditingController();

  // These must match the routes defined in app_router.dart
  // (/home, /home/men, /home/women, /home/kids, /home/beauty).
  final List<_NavLink> _navLinks = const [
    _NavLink('Men', '/home/men'),
    _NavLink('Women', '/home/women'),
    _NavLink('Kids', '/home/kids'),
    _NavLink('Beauty', '/home/beauty'),
    _NavLink('Home', '/home'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;
    // TODO: point this at your actual search route.
    context.push('/search', extra: query.trim());
  }

  // Checks login state before navigating to a protected route.
  // If not logged in, redirects to /login and passes the intended
  // destination so the login flow can send the user back afterwards.
  void _goToProtected(BuildContext context, String route) {
    final isLoggedIn =
        ApiService.getToken() != null && ApiService.getToken()!.isNotEmpty;

    if (isLoggedIn) {
      context.go(route);
    } else {
      context.go(
        Uri(path: '/login', queryParameters: {'redirect': route}).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          InkWell(
            onTap: () => context.go('/home'),
            child: const Text(
              'Thiraa',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 32),

          // Category nav links
          Row(
            children: _navLinks
                .map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: InkWell(
                      onTap: () => context.go(link.route),
                      child: Text(
                        link.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(width: 24),

          // Lengthy search bar
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: AppColors.textGrey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _handleSearch,
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        hintText: 'Search for products, brands and more',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 28),

          // Icon + label actions
          _HeaderAction(
            icon: Icons.person_outline,
            label: 'Profile',
            onTap: () => context.go('/profile'),
          ),
          const SizedBox(width: 22),
          _HeaderAction(
            icon: Icons.favorite_border,
            label: 'Wishlist',
            onTap: () => _goToProtected(context, '/wishlist'),
          ),
          const SizedBox(width: 22),
          _HeaderAction(
            icon: Icons.shopping_bag_outlined,
            label: 'Bag',
            onTap: () => _goToProtected(context, '/bag'),
          ),
          const SizedBox(width: 22),
          _HeaderAction(
            icon: Icons.notifications_none,
            label: 'Notifications',
            onTap: () => _goToProtected(context, '/notifications'),
          ),
        ],
      ),
    );
  }
}

class _NavLink {
  final String label;
  final String route;
  const _NavLink(this.label, this.route);
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: AppColors.black),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.black),
            ),
          ],
        ),
      ),
    );
  }
}
