import 'package:flutter/material.dart';
import 'sidebar.dart';
import 'header.dart';
import 't_colors.dart';
import '../core/responsive.dart';

class AppShell extends StatelessWidget {
  final String currentPath;
  final Widget child;

  const AppShell({
    super.key,
    required this.currentPath,
    required this.child,
  });

  String get _title {
    switch (currentPath) {
      case '/dashboard':  return 'Dashboard';
      case '/shops':      return 'Shops';
      case '/users':      return 'Users';
      case '/products':   return 'Products';
      case '/orders':     return 'Orders';
      case '/categories': return 'Categories';
      case '/payouts':    return 'Payouts';
      case '/banners':    return 'Banners';
      case '/reports':    return 'Reports';
      case '/settings':   return 'Settings';
      default:            return 'Dashboard';
    }
  }

  String get _subtitle {
    switch (currentPath) {
      case '/dashboard':  return 'Welcome back, Super Admin';
      case '/shops':      return 'Manage all shops';
      case '/users':      return 'Manage all users';
      case '/products':   return 'View all products';
      case '/orders':     return 'View and manage orders';
      case '/categories': return 'Manage product categories';
      case '/payouts':    return 'Shop owner payouts';
      case '/banners':    return 'Home screen banners';
      case '/reports':    return 'Reported content';
      case '/settings':   return 'Platform configuration';
      default:            return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final isMobile = Responsive.isMobile(context);
    print("isMobile = $isMobile");
    return Scaffold(
      backgroundColor: TColors.cream,
      drawer: isMobile
      ? const Drawer(
          child: Sidebar(),
        )
      : null,
      body: Row(
        children: [
          // Sidebar — never rebuilds
          if (!isMobile)
      const Sidebar(),

          // Right side
          Expanded(
            child: Column(
              children: [
                AdminHeader(title: _title, subtitle: _subtitle),
                Expanded(child: child), // only this changes
              ],
            ),
          ),
        ],
      ),
    );
  }
}