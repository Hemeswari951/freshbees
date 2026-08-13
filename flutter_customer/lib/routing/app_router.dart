import 'package:go_router/go_router.dart';
import '../widgets/customer_layout.dart';
import '../widgets/splash_screen.dart';
import '../screens/auth/login_screen.dart';

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
  if (path.startsWith('/wishlist/')) {
    return const _LayoutVisibility(showFooterOnMobile: false);
  }
  return const _LayoutVisibility();
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),

    // Login Screen
    // Reads the `redirectTo` value passed via extra from CustomerHeader's
    // _goToProtected() (e.g. context.go('/login', extra: {'redirectTo': '/wishlist'}))
    // so LoginScreen -> OTP/Password flow can send the user back to where
    // they originally wanted to go, instead of always landing on /home.
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final redirectRoute = state.uri.queryParameters['redirect'];
        return LoginScreen(redirectRoute: redirectRoute);
      },
    ),

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
