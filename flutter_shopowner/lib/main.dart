import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/app_colors.dart';
import 'widgets/shop_owner_layout.dart';

import 'widgets/splash_screen.dart';

import './services/api_service.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password.dart';
import '../screens/auth/otp_verification.dart';
import '../screens/auth/reset_password.dart';

import '../screens/home/home_screen.dart';
import '../screens/orders/order_screen.dart';
import '../screens/products/add_product_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/profile/profile_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiService.loadToken(); // <-- ADD THIS

  runApp(const ThiraaShopOwner());
}

class ThiraaShopOwner extends StatelessWidget {
  const ThiraaShopOwner({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        // Login Screen
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/verify-otp',
          builder: (context, state) {
            final email = state.extra as String;
            return OtpVerificationScreen(email: email);
          },
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final extra = state.extra;

            if (extra is int) {
              // First login flow
              return ResetPasswordScreen(ownerId: extra);
            } else if (extra is String) {
              // Forgot password flow
              return ResetPasswordScreen(email: extra);
            }

            return const LoginScreen();
          },
        ),
        
        ShellRoute(
          builder: (context, state, child) {
            return ShopOwnerLayout(currentPath: state.uri.path, child: child);
          },

          routes: [
            GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

            GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
            GoRoute(
              path: '/add-product',
              builder: (_, __) => const AddProductScreen(),
            ),

            GoRoute(
              path: '/products',
              builder: (_, __) => const ProductsScreen(),
            ),
            GoRoute(
              path: '/inventory',
              builder: (_, __) => const InventoryScreen(),
            ),
            GoRoute(
              path: '/reports',
              builder: (_, __) => const ReportsScreen(),
            ),
            GoRoute(
              path: '/earnings',
              builder: (_, __) => const EarningsScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (_, __) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'THIRAA Shop Owner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.cream,
        fontFamily: 'Inter',
      ),
      routerConfig: router,
    );
  }
}
