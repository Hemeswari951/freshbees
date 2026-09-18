import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/customer_layout.dart';
import '../widgets/splash_screen.dart';

import '../models/profile_model.dart';
import '../models/tryon_profile_model.dart';
import 'package:flutter_thiraa/screens/profile/order_details_screen.dart';
import 'package:flutter_thiraa/screens/profile/personal_info_screen.dart';
import 'package:flutter_thiraa/screens/profile/personal_details_screen.dart';

import '../screens/auth/login_screen.dart';

import '../screens/home/home_screen.dart';
import '../screens/wishlist/wishlist_screen.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../models/profile_section.dart';
import '../screens/profile/profile_details_screen.dart';
import '../screens/notification/notifications_screen.dart';

import '../screens/virtual_tryon/add_person_screen.dart';
import '../screens/virtual_tryon/style_profile_screen.dart';
import '../screens/virtual_tryon/tryon_profile_selection_screen.dart';
import '../screens/virtual_tryon/try_on_entry_screen.dart';
import '../screens/virtual_tryon/tryon_product_screen.dart';
import '../screens/virtual_tryon/tryon_review_screen.dart';
import '../screens/virtual_tryon/virtual_tryon_screen.dart';
import '../models/product_model.dart';

import '../screens/product/product_list_screen.dart';
import '../screens/product/product_view_screen.dart';
import '../screens/product/product_filters.dart';

import '../screens/home/shop_list_screen.dart';
import '../screens/product/shop_overview_screen.dart';

// ─────────────────────────────────────────────────────────────
// Layout visibility
// ─────────────────────────────────────────────────────────────

class _LayoutVisibility {
  final bool showFooterOnMobile;

  /// Mic/camera icons in the desktop search bar. False on Profile,
  /// Wishlist, and Cart — true (default) everywhere else.
  final bool showVoiceAndCameraSearch;

  const _LayoutVisibility({
    this.showFooterOnMobile = true,
    this.showVoiceAndCameraSearch = true,
  });
}

_LayoutVisibility _visibilityFor(String path) {
  // Product List + Product View
  if (path == '/products' || path.startsWith('/products/')) {
    return const _LayoutVisibility(showFooterOnMobile: false);
  }

  // Wishlist — no mic/camera search
  if (path == '/wishlist' || path.startsWith('/wishlist/')) {
    return const _LayoutVisibility(
      showFooterOnMobile: false,
      showVoiceAndCameraSearch: false,
    );
  }

    // Cart — no mic/camera search
  if (path == '/cart' || path.startsWith('/cart/')) {
    return const _LayoutVisibility(
      showFooterOnMobile: false,
      showVoiceAndCameraSearch: false,
    );
  }

  // Shop Overview
  if (path == '/shops' || path.startsWith('/shops/')) {
    return const _LayoutVisibility(showFooterOnMobile: false);
  }

  // Filter
  if (path == '/filter' || path.startsWith('/filter/')) {
    return const _LayoutVisibility(showFooterOnMobile: false);
  }

  // Profile — no mic/camera search
  if (path == '/profile' || path.startsWith('/profile/')) {
    return const _LayoutVisibility(showVoiceAndCameraSearch: false);
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
          showVoiceAndCameraSearch: visibility.showVoiceAndCameraSearch,
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
          path: '/virtual-tryon/entry',
          builder: (context, state) {
            final extra = state.extra;
            ProductModel? product;
            bool skipProfileSelection = false;

            if (extra is Map<String, dynamic>) {
              product = extra['product'] as ProductModel?;
              skipProfileSelection =
                  extra['skipProfileSelection'] as bool? ?? false;
            }

            return TryOnEntryScreen(
              product: product,
              skipProfileSelection: skipProfileSelection,
            );
          },
        ),

        GoRoute(
          path: '/virtual-tryon/style-profile',
          builder: (context, state) {
            final source = state.uri.queryParameters['source'];
            final extra = state.extra;

            return StyleProfileScreen(
              source: source,
              profile: extra is TryOnProfile ? extra : null,
            );
          },
        ),

        GoRoute(
  path: '/virtual-tryon/add-profile',
  builder: (context, state) {
    final extra = state.extra;

    return AddPersonScreen(
      profile: extra is TryOnProfile ? extra : null,
    );
  },
),  
       

        GoRoute(
          path: '/virtual-tryon/select-profile',
          builder: (context, state) {
            final extra = state.extra;
            final product = extra is Map<String, dynamic>
                ? extra['product'] as ProductModel?
                : null;

            return TryOnProfileSelectionScreen(selectedProduct: product);
          },
        ),

        GoRoute(
          path: '/virtual-tryon/photo',
          builder: (context, state) {
            final extra = state.extra;

            TryOnProfile? selectedProfile;
            ProfileModel? customerProfile;
            ProductModel? selectedProduct;

            // ==========================================
            // ADDITIONAL TRY-ON PROFILE
            // ==========================================

            if (extra is TryOnProfile) {
              selectedProfile = extra;
            }
            // ==========================================
            // MAIN CUSTOMER - ME
            // ==========================================
            else if (extra is ProfileModel) {
              customerProfile = extra;
            }
            // ==========================================
            // MAP - FOR PRODUCT TRY-ON FLOW
            // ==========================================
            else if (extra is Map<String, dynamic>) {
              final profileExtra = extra['profile'];

              if (profileExtra is TryOnProfile) {
                selectedProfile = profileExtra;
              }

              if (profileExtra is ProfileModel) {
                customerProfile = profileExtra;
              }

              final productExtra = extra['product'];

              if (productExtra is ProductModel) {
                selectedProduct = productExtra;
              }

              final customerProfileExtra = extra['customerProfile'];

              if (customerProfileExtra is ProfileModel) {
                customerProfile = customerProfileExtra;
              }
            }

            return VirtualTryOnScreen(
              selectedProfile: selectedProfile,
              selectedProduct: selectedProduct,
              customerProfile: customerProfile,
            );
          },
        ),

        GoRoute(
          path: '/virtual-tryon/products',
          builder: (context, state) {
            final extra = state.extra;

            if (extra is! Map<String, dynamic>) {
              return const Scaffold(
                body: Center(child: Text('Try-on information not found')),
              );
            }

            // ==================================================
            // TRY-ON PROFILE
            // ==================================================

            final profileValue = extra['profile'];

            TryOnProfile? selectedProfile;

            if (profileValue is TryOnProfile) {
              selectedProfile = profileValue;
            }

            // ==================================================
            // VALIDATE PROFILE
            // ==================================================

            if (selectedProfile == null) {
              return const Scaffold(
                body: Center(child: Text('Try-on profile not found')),
              );
            }

            debugPrint(
              'PRODUCT ROUTE → profileId: '
              '${selectedProfile.profileId}',
            );

            debugPrint(
              'PRODUCT ROUTE → profileName: '
              '${selectedProfile.profileName}',
            );

            debugPrint(
              'PRODUCT ROUTE → photoUrl: '
              '${selectedProfile.photoUrl}',
            );

            // ==================================================
            // PRODUCT SCREEN
            // ==================================================

            return TryOnProductScreen(
              selectedProfile: selectedProfile,

              // Temporary photo is no longer used
              customerPhoto: null,
              customerPhotoUrl: null,

              // Main user is also represented by TryOnProfile
              customerProfile: null,
            );
          },
        ),

        GoRoute(
          path: '/virtual-tryon/review',
          builder: (context, state) {
            final extra = state.extra;

            if (extra is! Map<String, dynamic>) {
              return const Scaffold(
                body: Center(child: Text('Try-on information not found')),
              );
            }

            final photo = extra['photo'] as XFile?;

            final photoUrl = extra['photoUrl'] as String?;

            final product = extra['product'] as ProductModel;

            final selectedProfile = extra['selectedProfile'] as TryOnProfile?;

            final customerProfile = extra['customerProfile'] as ProfileModel?;

            debugPrint('REVIEW ROUTE → selectedProfile: $selectedProfile');

            debugPrint(
              'REVIEW ROUTE → profileId: ${selectedProfile?.profileId}',
            );

            debugPrint('REVIEW ROUTE → photoUrl: ${selectedProfile?.photoUrl}');

            return TryOnReviewScreen(
              customerPhoto: photo,
              customerPhotoUrl: photoUrl,
              selectedProduct: product,
              selectedProfile: selectedProfile,
              customerProfile: customerProfile,
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

        GoRoute(
  path: '/notifications',
  builder: (context, state) => const NotificationsScreen(),
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

        GoRoute(
          path: '/profile/my-profile',
          builder: (context, state) {
            final profile = state.extra as TryOnProfile?;

            return PersonalInfoScreen(selectedProfile: profile);
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
          routes: [
            GoRoute(
              path: 'orders/:orderId',
              builder: (context, state) {
                final orderId = int.parse(state.pathParameters['orderId']!);

                return OrderDetailsScreen(orderId: orderId);
              },
            ),
          ],
        ),

        GoRoute(
          path: '/profile/personal-details',
          builder: (context, state) => const PersonalDetailsScreen(),
        ),

        // ─────────────────────────────────────────
        // ORDER DETAILS  (pushed from OrdersScreen's "VIEW ORDER",
        // and from a notification tap)
        // /profile/details/orders/26
        // /profile/details/orders/26?itemId=91
        //
        // itemId is OPTIONAL. Notifications are about one specific item
        // in the order, so they pass it along and the screen rings that
        // item's card. Opening from the Orders list passes nothing.
        // ─────────────────────────────────────────
        GoRoute(
          path: '/profile/details/orders/:orderId',
 
          builder: (context, state) {
            final orderId = int.tryParse(
                  state.pathParameters['orderId'] ?? '',
                ) ??
                0;
 
            final highlightItemId = int.tryParse(
              state.uri.queryParameters['itemId'] ?? '',
            );
 
            return OrderDetailsScreen(
              orderId: orderId,
              highlightOrderItemId: highlightItemId,
            );
          },
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
        // /products?search=tshirt
        //
        // /products?search=&focus=true   <- opens list screen with the
        //   inline search box auto-expanded and focused, nothing typed
        //   yet. Used by ProductViewScreen's search bar tap so the user
        //   lands on the list screen ready to type, instead of the
        //   HomeScreen fallback.
        //
        // This allows browser Back / Forward to work.
        // ─────────────────────────────────────────
        GoRoute(
          path: '/products',

          builder: (context, state) {
            final shopId = state.uri.queryParameters['shopId'];

            final shopName = state.uri.queryParameters['shopName'];

            final search = state.uri.queryParameters['search'];

            final focusSearch = state.uri.queryParameters['focus'] == 'true';

            // -----------------------------------------
            // Camera/image search
            //
            // An XFile can't travel in a URL, so the camera icon hands
            // it in via route `extra` instead of a query parameter
            // (same pattern already used by the try-on routes above).
            // -----------------------------------------

            final extra = state.extra;

            if (extra is Map<String, dynamic> &&
                extra['searchImage'] is XFile) {
              final image = extra['searchImage'] as XFile;

              return ProductListScreen(
                key: ValueKey('image-${image.path}'),
                args: ProductListArgs.image(image: image),
              );
            }

            // -----------------------------------------
            // Shop products
            // -----------------------------------------

            if (shopId != null && shopName != null) {
              final args = ProductListArgs.shop(
                shopId: int.parse(shopId),
                shopName: shopName,
              );

              return ProductListScreen(
                key: ValueKey('shop-$shopId'),
                args: args,
              );
            }

            // -----------------------------------------
            // Search products (also covers the
            // "search=&focus=true" empty-search case used
            // to open the list screen with search focused)
            // -----------------------------------------

            if (search != null) {
              final args = search.isEmpty
                  ? const ProductListArgs(
                      key: ProductListArgs.keySearch,
                      value: '',
                      title: 'Search Products',
                    )
                  : ProductListArgs.search(query: search);

              return ProductListScreen(
                key: ValueKey('search-$search'),
                args: args,
                autoFocusSearch: focusSearch,
              );
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
        //
        // shopId/shopName are OPTIONAL query params carried over when
        // the product was opened from a shop's product list
        // (see ProductListScreen._openProduct). ProductViewScreen uses
        // them to build its desktop breadcrumb ("Home / <Shop> /
        // <Category>") so it reflects where the user actually came
        // from, instead of a hardcoded/guessed shop name.
        //
        // /products/42                              <- opened directly
        //   (e.g. from home, search, wishlist) — no shop context.
        // /products/42?shopId=10&shopName=Surya%20Fashion
        //   <- opened from that shop's product list.
        // ─────────────────────────────────────────
        GoRoute(
          path: '/products/:id',
          builder: (context, state) {
            final productId = int.parse(state.pathParameters['id']!);

            return ProductViewScreen(
              productId: productId,
              shopId: int.tryParse(state.uri.queryParameters['shopId'] ?? ''),
              shopName: state.uri.queryParameters['shopName'],
              searchQuery: state.uri.queryParameters['search'],
            );
          },
        ),

        // ─────────────────────────────────────────────────────────
        // SHOP LIST
        // ─────────────────────────────────────────────────────────
        GoRoute(
          path: '/shops',
          builder: (context, state) {
            final category = state.uri.queryParameters['category'] ?? 'All';

            final search = state.uri.queryParameters['search'];

            return ShopListScreen(categoryTitle: category, searchQuery: search);
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