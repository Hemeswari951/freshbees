import 'package:go_router/go_router.dart';
import '../widgets/customer_layout.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
// import '../screens/auth/otp_verify_screen.dart';
// import '../screens/auth/password_screen.dart';
// import '../screens/auth/create_password_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/bag/bag_screen.dart';
import '../screens/profile/profile_screen.dart';

// ── Per-route header/footer visibility (mobile only — desktop always shows
// header+sidebar, see ShopOwnerLayout). Add a case here when a NEW screen
// needs non-default behaviour. ShopOwnerLayout itself never needs edits. ──
class _LayoutVisibility {
  final bool showFooterOnMobile;
  const _LayoutVisibility({this.showFooterOnMobile = true});
}

_LayoutVisibility _visibilityFor(String path) {
  if (path.startsWith('/products/')) {
    return const _LayoutVisibility(showFooterOnMobile: false);
  }
  return const _LayoutVisibility();
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),

    // Login Screen
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // GoRoute(
    //   path: '/forgot-password',
    //   builder: (context, state) => const ForgotPasswordScreen(),
    // ),
    // GoRoute(
    //   path: '/verify-otp',
    //   builder: (context, state) {
    //     final email = state.extra as String;
    //     return OtpVerificationScreen(email: email);
    //   },
    // ),
    // GoRoute(
    //   path: '/reset-password',
    //   builder: (context, state) {
    //     final extra = state.extra;

    //     if (extra is int) {
    //       return ResetPasswordScreen(ownerId: extra);
    //     } else if (extra is String) {
    //       return ResetPasswordScreen(email: extra);
    //     }

    //   return const LoginScreen();
    // },
    // ),
    ShellRoute(
      builder: (context, state, child) {
        final visibility = _visibilityFor(state.uri.path);
        return CustomerLayout(
          currentPath: state.uri.path,
          showFooterOnMobile: visibility.showFooterOnMobile,
          child: child,
        );
      },

      routes: [
        // '/home' = All toggle. Each nested route below is a separate
        // toggle (Men / Women / Kids / Beauty) — navigating to it opens
        // HomeScreen with that category pre-selected, and the URL
        // reflects which toggle is active.
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(initialCategory: 'All'),
          routes: [
            GoRoute(
              path: 'men',
              builder: (_, __) => const HomeScreen(initialCategory: 'Men'),
            ),
            GoRoute(
              path: 'women',
              builder: (_, __) => const HomeScreen(initialCategory: 'Women'),
            ),
            GoRoute(
              path: 'kids',
              builder: (_, __) => const HomeScreen(initialCategory: 'Kids'),
            ),
            GoRoute(
              path: 'beauty',
              builder: (_, __) => const HomeScreen(initialCategory: 'Beauty'),
            ),
          ],
        ),
        GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
        GoRoute(path: '/bag', builder: (_, __) => const BagScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);
