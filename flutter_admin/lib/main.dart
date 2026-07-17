import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'services/api_service.dart';

import 'widgets/t_colors.dart';
import 'widgets/admin_layout.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/shops/shops_screen.dart';
import 'screens/customers/customer_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/payouts/payouts_screen.dart';
import 'screens/banners/banners_screen.dart';
import 'screens/reports/reports_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'widgets/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/add_admin_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiService.loadToken(); // <-- ADD THIS

  runApp(const ThiraaAdminApp());
}

class ThiraaAdminApp extends StatelessWidget {
  const ThiraaAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        // Splash Screen
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Login Screen
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return AppShell(currentPath: state.uri.path, child: child);
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const DashboardScreen(),
            ),
            GoRoute(path: '/shops', builder: (_, __) => const ShopsScreen()),
            GoRoute(
              path: '/customers',
              builder: (_, __) => const CustomersScreen(),
            ),
            GoRoute(
              path: '/products',
              builder: (_, __) => const ProductsScreen(),
            ),
            GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
            GoRoute(
              path: '/categories',
              builder: (_, __) => const CategoriesScreen(),
            ),
            GoRoute(
              path: '/payouts',
              builder: (_, __) => const PayoutsScreen(),
            ),
            GoRoute(
              path: '/banners',
              builder: (_, __) => const BannersScreen(),
            ),
            GoRoute(
              path: '/reports',
              builder: (_, __) => const ReportsScreen(),
            ),
            GoRoute(
              path: '/settings',
              builder: (_, __) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/add-admin',
              builder: (_, __) => const AddAdminScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'THIRAA Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: TColors.cream,
        fontFamily: 'Inter',
      ),
      routerConfig: router,
    );
  }
}
