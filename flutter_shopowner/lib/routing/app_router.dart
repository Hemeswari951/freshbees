import 'package:go_router/go_router.dart';

import '../widgets/shop_owner_layout.dart';

import '../screens/auth/login_screen.dart';
import '../screens/auth/forgot_password.dart';
import '../screens/auth/otp_verification.dart';
import '../screens/auth/reset_password.dart';

import '../screens/home/home_screen.dart';
import '../screens/orders/order_screen.dart';
import '../screens/products/add_product_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/products/product_view_screen.dart';

import '../screens/reports/reports_screen.dart';
import '../screens/earnings/earnings_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/splash_screen.dart';

// ── Per-route header/footer visibility (mobile only — desktop always shows
// header+sidebar, see ShopOwnerLayout). Add a case here when a NEW screen
// needs non-default behaviour. ShopOwnerLayout itself never needs edits. ──
class _LayoutVisibility {
  final bool showFooterOnMobile;
  const _LayoutVisibility({
    this.showFooterOnMobile = true,
  });
}

_LayoutVisibility _visibilityFor(String path) {

  if (path.startsWith('/products/')) {
    return const _LayoutVisibility(
      showFooterOnMobile: false,
    );
  }
  return const _LayoutVisibility();
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    // Login Screen
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
          return ResetPasswordScreen(ownerId: extra);
        } else if (extra is String) {
          return ResetPasswordScreen(email: extra);
        }

        return const LoginScreen();
      },
    ),

    ShellRoute(
      builder: (context, state, child) {
        final visibility = _visibilityFor(state.uri.path);
        return ShopOwnerLayout(
          currentPath: state.uri.path,
          showFooterOnMobile: visibility.showFooterOnMobile,
          child: child,
        );
      },

      routes: [
        GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),

        GoRoute(path: '/orders', builder: (_, _) => const OrdersScreen()),
        GoRoute(
          path: '/add-product',
          builder: (_, _) => const AddProductScreen(),
        ),

        GoRoute(path: '/products', builder: (_, _) => const ProductsScreen()),
        GoRoute(
          path: '/products/:id',
          builder: (_, state) => ProductViewScreen(
            productId: int.parse(state.pathParameters['id']!),
          ),
        ),
        GoRoute(
          path: '/inventory',
          builder: (_, _) => const InventoryScreen(),
        ),
        GoRoute(path: '/reports', builder: (_, _) => const ReportsScreen()),
        GoRoute(
          path: '/earnings',
          builder: (_, _) => const EarningsScreen(),
        ),
        GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      ],
    ),
  ],
);