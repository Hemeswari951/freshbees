import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/customer_layout.dart';
import '../widgets/splash_screen.dart';
 
import '../screens/auth/login_screen.dart';
 
import '../screens/home/home_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../models/profile_section.dart';
import '../screens/profile/profile_details_screen.dart';
 
import '../screens/virtual_tryon/add_person_screen.dart';
import '../screens/virtual_tryon/style_profile_screen.dart';
import '../screens/virtual_tryon/tryon_profile_selection_screen.dart';
import '../screens/virtual_tryon/try_on_entry_screen.dart';
import '../screens/virtual_tryon/tryon_product_screen.dart';
import '../screens/virtual_tryon/tryon_review_screen.dart';
import '../screens/virtual_tryon/virtual_tryon_screen.dart';
import '../services/tryon_profile_service.dart';
import '../models/product_model.dart';
 
import '../screens/product/product_list_screen.dart';
import '../screens/product/product_view_screen.dart';
import '../screens/product/shop_overview_screen.dart';
import '../screens/product/product_filters.dart';
import '../screens/profile/about_us_screen.dart';
import '../screens/profile/terms_policies_screen.dart';
import '../screens/profile/faq_screen.dart';
 
// ─────────────────────────────────────────────────────────────
// Layout visibility
// ─────────────────────────────────────────────────────────────
 
class _LayoutVisibility {
  final bool showFooterOnMobile;
 
  const _LayoutVisibility({this.showFooterOnMobile = true});
}
 
_LayoutVisibility _visibilityFor(String path) {
  // Product List + Product View
  if (path == '/products' || path.startsWith('/products/')) {
    return const _LayoutVisibility(showFooterOnMobile: false);
  }
 
  // Wishlist
  if (path == '/wishlist' || path.startsWith('/wishlist/')) {
    return const _LayoutVisibility(showFooterOnMobile: false);
  }
 
  // Shop Overview
  if (path == '/shops' || path.startsWith('/shops/')) {
    return const _LayoutVisibility(showFooterOnMobile: false);
  }
 
  // Filter
  if (path == '/filter' || path.startsWith('/filter/')) {
    return const _LayoutVisibility(showFooterOnMobile: false);
  }
 
  // Default
  return const _LayoutVisibility();
}
 
// ─────────────────────────────────────────────────────────────
// GoRouter
// ─────────────────────────────────────────────────────────────
 
final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
 
  routes: [
    // ─────────────────────────────────────────────────────────
    // Splash
    // ─────────────────────────────────────────────────────────
 
    GoRoute(
      path: '/splash',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),
 
    // ─────────────────────────────────────────────────────────
    // Login
    // ─────────────────────────────────────────────────────────
    GoRoute(
      path: '/login',
      builder: (context, state) {
        final redirectRoute = state.uri.queryParameters['redirect'];
 
        return LoginScreen(redirectRoute: redirectRoute);
      },
    ),
 
    // ─────────────────────────────────────────────────────────
    // Customer Layout
    // ─────────────────────────────────────────────────────────
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
        // ─────────────────────────────────────────
        // HOME
        // ─────────────────────────────────────────
 
        GoRoute(
          path: '/home',
 
          builder: (_, __) {
            return const HomeScreen(initialCategory: 'All');
          },
 
          routes: [
            // Men
            GoRoute(
              path: 'men',
              builder: (_, __) {
                return const HomeScreen(initialCategory: 'Men');
              },
            ),
 
            // Women
            GoRoute(
              path: 'women',
              builder: (_, __) {
                return const HomeScreen(initialCategory: 'Women');
              },
            ),
 
            // Kids
            GoRoute(
              path: 'kids',
              builder: (_, __) {
                return const HomeScreen(initialCategory: 'Kids');
              },
            ),
 
            // Beauty
            GoRoute(
              path: 'beauty',
              builder: (_, __) {
                return const HomeScreen(initialCategory: 'Beauty');
              },
            ),
          ],
        ),
 
        // Trial On
        GoRoute(path: '/trial', builder: (_, __) => const TryOnEntryScreen()),
 
        GoRoute(
          path: '/virtual-tryon/style-profile',
          builder: (_, __) => const StyleProfileScreen(),
        ),
 
        GoRoute(
          path: '/virtual-tryon/add-profile',
          builder: (_, __) => const AddPersonScreen(),
        ),
 
        GoRoute(
          path: '/virtual-tryon/select-profile',
          builder: (_, __) => const TryOnProfileSelectionScreen(),
        ),
 
        GoRoute(
          path: '/virtual-tryon/photo',
          builder: (context, state) {
            final profile = state.extra as TryOnProfile?;
 
            return VirtualTryOnScreen(selectedProfile: profile);
          },
        ),
 
        GoRoute(
          path: '/virtual-tryon/products',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
 
            final photo = extra['photo'] as XFile?;
 
            final photoUrl = extra['photoUrl'] as String?;
 
            final profile = extra['profile'] as TryOnProfile;
 
            return TryOnProductScreen(
              customerPhoto: photo,
              customerPhotoUrl: photoUrl,
              selectedProfile: profile,
            );
          },
        ),
 
        GoRoute(
          path: '/virtual-tryon/review',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
 
            final photo = extra['photo'] as XFile?;
 
            final photoUrl = extra['photoUrl'] as String?;
 
            final product = extra['product'] as ProductModel;
 
            final profile = extra['profile'] as TryOnProfile;
 
            return TryOnReviewScreen(
              customerPhoto: photo,
              customerPhotoUrl: photoUrl,
              selectedProduct: product,
              selectedProfile: profile,
            );
          },
        ),
 
        // ─────────────────────────────────────────
        // WISHLIST
        // ─────────────────────────────────────────
        GoRoute(
          path: '/wishlist',
          builder: (_, __) {
            return const WishlistScreen();
          },
        ),
 
        // ─────────────────────────────────────────
        // CART
        // ─────────────────────────────────────────
        GoRoute(
          path: '/cart',
          builder: (_, __) {
            return const CartScreen();
          },
        ),
 
        // ─────────────────────────────────────────
        // PROFILE
        // ─────────────────────────────────────────
        GoRoute(
          path: '/profile',
          builder: (_, __) {
            return const ProfileScreen();
          },
        ),
 
        // ─────────────────────────────────────────
        // PROFILE DETAILS
        // ─────────────────────────────────────────
        GoRoute(
          path: '/profile/details',
 
          builder: (context, state) {
            final sectionParam = state.uri.queryParameters['section'];
 
            return ProfileDetailsScreen(
              initialSection: ProfileSectionX.fromSlug(sectionParam),
            );
          },
        ),
         GoRoute(
          path: '/about-us',
          builder: (context, state) => const AboutUsScreen(),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsPoliciesScreen(),
        ),
        GoRoute(
  path: '/faqs',
  builder: (context, state) => const FaqScreen(),
),
 
 
        // ─────────────────────────────────────────
        // PRODUCT LIST
        // ─────────────────────────────────────────
        //
        // IMPORTANT:
        // Do NOT use state.extra here.
        //
        // Product list information is stored in the URL:
        //
        // /products?shopId=10&shopName=Surya%20Fashion
        //
        // or
        //
        // /products?search=tshirt
        //
        // This allows browser Back / Forward to work.
        // ─────────────────────────────────────────
        GoRoute(
          path: '/products',
 
          builder: (context, state) {
            final shopId = state.uri.queryParameters['shopId'];
 
            final shopName = state.uri.queryParameters['shopName'];
 
            final search = state.uri.queryParameters['search'];
 
            // -----------------------------------------
            // Shop products
            // -----------------------------------------
 
            if (shopId != null && shopName != null) {
              final args = ProductListArgs.shop(
                shopId: int.parse(shopId),
                shopName: shopName,
              );
 
              return ProductListScreen(args: args);
            }
 
            // -----------------------------------------
            // Search products
            // -----------------------------------------
 
            if (search != null && search.isNotEmpty) {
              final args = ProductListArgs.search(query: search);
 
              return ProductListScreen(args: args);
            }
 
            // -----------------------------------------
            // No valid ProductList arguments
            // -----------------------------------------
            //
            // This prevents:
            //
            // TypeError: null is not a subtype of
            // ProductListArgs
            //
            // -----------------------------------------
 
            return const HomeScreen(initialCategory: 'All');
          },
        ),
 
        // ─────────────────────────────────────────
        // PRODUCT VIEW
        // ─────────────────────────────────────────
        GoRoute(
          path: '/products/:productId',
 
          builder: (context, state) {
            final productId = state.pathParameters['productId'];
 
            return ProductViewScreen(productId: int.parse(productId!));
          },
        ),
 
        // ─────────────────────────────────────────
        // SHOP OVERVIEW
        // ─────────────────────────────────────────
        GoRoute(
          path: '/shops/:shopId',
 
          builder: (context, state) {
            final shopId = state.pathParameters['shopId'];
 
            return ShopOverviewScreen(shopId: int.parse(shopId!));
          },
        ),
 
        // ─────────────────────────────────────────
        // FILTER
        // ─────────────────────────────────────────
        //
        // For now FilterPage still receives
        // ProductFilters through extra.
        //
        // We can convert this to URL parameters later
        // if browser Back/Forward needs to restore the
        // exact filter state.
        // ─────────────────────────────────────────
        GoRoute(
          path: '/filter',
          builder: (context, state) {
            final args = state.extra as FilterPageArgs;
            return FilterPage(
              initialFilters: args.filters,
              allProducts: args.allProducts,
              availableSizes: args.availableSizes,
              availableColors: args.availableColors,
            );
          },
        ),
      ],
    ),
  ],
);