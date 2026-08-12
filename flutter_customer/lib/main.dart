import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// App Colors Helper Import
import 'widgets/t_colors.dart';

// Splash Screen
import 'screens/splash/splash_screen.dart';

// Auth Screens Integration
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verify_screen.dart';
import 'screens/auth/create_password_screen.dart';
import 'screens/auth/password_screen.dart';

// Bottom Navigation Screens
import 'screens/home/home_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/shop/shop_detail_screen.dart';
import 'models/shop_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThiraaCustomerApp());
}

class ThiraaCustomerApp extends StatelessWidget {
  const ThiraaCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',

      routes: [
        /// 1. Splash Screen Route
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),

        /// 2. Auth Routes
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/otp-verify',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return OTPVerifyScreen(
              identifier: extra['identifier'] ?? '',
              purpose: extra['purpose'] ?? 'login',
              showUsePassword: extra['showUsePassword'] ?? true,
            );  
          },
        ),
        GoRoute(
          path: '/create-password',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CreatePasswordScreen(identifier: extra['identifier'] ?? '');
          },
        ),
        GoRoute(
          path: '/reset-password',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return PasswordScreen(
              identifier: extra['identifier'] ?? '',
              isResetMode: extra['isResetMode'] ?? true,
            );
          },
        ),

        /// 3. Main Bottom Navigation Routes
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (context, state) => const WishlistScreen(),
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        /// 4. Shop Detail Route — opened from the "Nearby Shops" section
        /// on Home. `extra` carries the already-fetched ShopModel when
        /// navigating from Home (avoids a refetch); falls back to
        /// fetching by id inside the screen when arriving via a deep
        /// link with only the id.
        GoRoute(
          path: '/shop/:id',
          builder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
            final shop =
                state.extra is ShopModel ? state.extra as ShopModel : null;
            return ShopDetailScreen(shopId: id, initialShop: shop);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Thiraa Customer Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: TColors.cream,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: TColors.gold),
      ),
      routerConfig: router,
    );
  }
}