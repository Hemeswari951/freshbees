import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/search_service.dart';
import '../widgets/location_bar.dart';
import './app_colors.dart';
import '../services/cart_count.dart';
import '../services/cart_service.dart';


class CustomerHeader extends StatefulWidget {
  const CustomerHeader({super.key});

  @override
  State<CustomerHeader> createState() => _CustomerHeaderState();
}

class _CustomerHeaderState extends State<CustomerHeader> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final LayerLink _searchLayerLink = LayerLink();

  final OverlayPortalController _searchOverlayController =
      OverlayPortalController();

  Timer? _debounce;

  List<SearchSuggestion> _suggestions = [];
  bool _isSuggesting = false;

  // ===========================================================================
  // CATEGORY NAVIGATION
  // ===========================================================================

  final List<_NavLink> _navLinks = const [
    _NavLink('Home', '/home'),
    _NavLink('Men', '/home/men'),
    _NavLink('Women', '/home/women'),
    _NavLink('Kids', '/home/kids'),
    _NavLink('Beauty', '/home/beauty'),
  ];

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // SEARCH
  // ===========================================================================

  void _onSearchChanged(String value) {
    _debounce?.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _isSuggesting = false;
      });

      if (_searchOverlayController.isShowing) {
        _searchOverlayController.hide();
      }

      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;

      setState(() {
        _isSuggesting = true;
      });

      try {
        final results = await SearchService.getSearchSuggestions(value);

        if (!mounted) return;

        setState(() {
          _suggestions = results;
          _isSuggesting = false;
        });

        if (_suggestions.isNotEmpty && !_searchOverlayController.isShowing) {
          _searchOverlayController.show();
        } else if (_suggestions.isEmpty && _searchOverlayController.isShowing) {
          _searchOverlayController.hide();
        }
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _suggestions = [];
          _isSuggesting = false;
        });

        if (_searchOverlayController.isShowing) {
          _searchOverlayController.hide();
        }
      }
    });
  }

  void _handleSearch(String query) {
    final trimmed = query.trim();

    if (trimmed.isEmpty) return;

    if (_searchOverlayController.isShowing) {
      _searchOverlayController.hide();
    }

    _searchFocusNode.unfocus();

    final uri = Uri(path: '/products', queryParameters: {'search': trimmed});

    context.push(uri.toString());
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    final query = suggestion.text.trim();

    if (query.isEmpty) return;

    _searchController.text = query;

    if (_searchOverlayController.isShowing) {
      _searchOverlayController.hide();
    }

    _searchFocusNode.unfocus();

    if (suggestion.isShop) {
      context.push(
        Uri(
          path: '/shops',
          queryParameters: {'category': 'All', 'search': query},
        ).toString(),
      );
      return;
    }

    context.push(
      Uri(path: '/products', queryParameters: {'search': query}).toString(),
    );
  }

  // ===========================================================================
  // PROTECTED ROUTES
  // ===========================================================================

  void _goToProtected(BuildContext context, String route) {
    final token = ApiService.getToken();

    final isLoggedIn = token != null && token.isNotEmpty;

    if (isLoggedIn) {
      context.push(route);
    } else {
      context.push(
        Uri(path: '/login', queryParameters: {'redirect': route}).toString(),
      );
    }
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // =====================================================================
        // TOP BLACK BAR
        // =====================================================================
        Container(
          width: double.infinity,
          height: 48,
          color: AppColors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              // ---------------------------------------------------------------
              // LOCATION
              //
              // This is your existing LocationBar.
              // No new location logic is created here.
              // ---------------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const LocationBar(),
              ),

              const Spacer(),

              // ---------------------------------------------------------------
              // TRACK ORDER
              // ---------------------------------------------------------------
              _TopBarAction(
                icon: Icons.local_shipping_outlined,
                label: 'Track Order',
                onTap: () {
                  _goToProtected(context, '/profile/details?section=orders');
                },
              ),

              const SizedBox(width: 30),

              // ---------------------------------------------------------------
              // HELP CENTER
              // ---------------------------------------------------------------
              _TopBarAction(
                icon: Icons.help_outline,
                label: 'Help Center',
                onTap: () {
                  _goToProtected(
                    context,
                    '/profile/details?section=help-center',
                  );
                },
              ),

              const SizedBox(width: 30),

              // ---------------------------------------------------------------
              // NOTIFICATION
              // ---------------------------------------------------------------
              _TopBarAction(
                icon: Icons.notifications_none,
                label: 'Notifications',
                onTap: () {
                  _goToProtected(context, '/notifications');
                },
              ),
            ],
          ),
        ),

        // =====================================================================
        // MAIN WHITE HEADER
        // =====================================================================
        Container(
          width: double.infinity,
          color: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---------------------------------------------------------------
              // THIRAA LOGO
              // ---------------------------------------------------------------
              InkWell(
                onTap: () {
                  context.push('/home');
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Thiraa',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 32),

              // ---------------------------------------------------------------
              // SEARCH BAR
              // ---------------------------------------------------------------
              Expanded(
                flex: 3,
                child: CompositedTransformTarget(
                  link: _searchLayerLink,
                  child: OverlayPortal(
                    controller: _searchOverlayController,
                    overlayChildBuilder: (context) {
                      return Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            _searchOverlayController.hide();
                          },
                          child: Stack(
                            children: [
                              CompositedTransformFollower(
                                link: _searchLayerLink,
                                showWhenUnlinked: false,
                                offset: const Offset(0, 52),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 8,
                                    borderRadius: BorderRadius.circular(12),
                                    color: AppColors.white,
                                    child: SizedBox(
                                      width: 500,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxHeight: 320,
                                        ),
                                        child: ListView.separated(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                          ),
                                          itemCount: _suggestions.length,
                                          separatorBuilder: (_, __) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final suggestion =
                                                _suggestions[index];

                                            return ListTile(
                                              dense: true,
                                              leading: Icon(
                                                suggestion.isShop
                                                    ? Icons.storefront_outlined
                                                    : suggestion.isTag
                                                    ? Icons.sell_outlined
                                                    : Icons.search_rounded,
                                                size: 18,
                                                color: suggestion.isShop
                                                    ? AppColors.black
                                                    : AppColors.textGrey,
                                              ),
                                              title: Text(
                                                suggestion.text,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              trailing: suggestion.isTag
                                                  ? const Text(
                                                      'tag',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.black38,
                                                      ),
                                                    )
                                                  : null,
                                              onTap: () {
                                                _onSuggestionTap(suggestion);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search,
                            size: 20,
                            color: AppColors.textGrey,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: _onSearchChanged,
                              onSubmitted: _handleSearch,
                              textInputAction: TextInputAction.search,
                              decoration: const InputDecoration(
                                hintText:
                                    'Search for products, brands and more',
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

                          if (_isSuggesting)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 30),

              // ---------------------------------------------------------------
              // CATEGORY NAVIGATION
              // ---------------------------------------------------------------
              Row(
                mainAxisSize: MainAxisSize.min,
                children: _navLinks.map((link) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _MainNavItem(
                      label: link.label,
                      onTap: () {
                        context.push(link.route);
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(width: 6),

              // ---------------------------------------------------------------
              // PROFILE
              // ---------------------------------------------------------------
              const _ProfileHoverMenu(),

              const SizedBox(width: 16),

              // ---------------------------------------------------------------
              // WISHLIST
              // ---------------------------------------------------------------
              _HeaderAction(
                icon: Icons.favorite_border,
                label: 'Wishlist',
                onTap: () {
                  _goToProtected(context, '/wishlist');
                },
              ),

              const SizedBox(width: 16),

              // ---------------------------------------------------------------
              // CART
              // ---------------------------------------------------------------
              ValueListenableBuilder<int>(
                valueListenable: cartItemCount,
                builder: (context, count, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _HeaderAction(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Cart',
                        onTap: () => _goToProtected(context, '/cart'),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 0,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        // =====================================================================
        // BOTTOM BORDER
        // =====================================================================
        Container(height: 1, color: AppColors.border),
      ],
    );
  }
}

// =============================================================================
// NAV LINK MODEL
// =============================================================================

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
// =============================================================================
// TOP BLACK BAR ACTION
// =============================================================================

class _TopBarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TopBarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.white),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MAIN CATEGORY NAV ITEM
// =============================================================================

class _MainNavItem extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MainNavItem({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PROFILE MENU ITEM
// =============================================================================

class _ProfileMenuItem {
  final IconData icon;
  final String label;
  final String route;

  const _ProfileMenuItem(this.icon, this.label, this.route);
}

const List<_ProfileMenuItem> _profileMenuItems = [
  _ProfileMenuItem(Icons.dashboard_outlined, 'My Profile', 'personal-info'),
  _ProfileMenuItem(Icons.receipt_long_outlined, 'Orders', 'orders'),
  _ProfileMenuItem(Icons.favorite_border, 'Wishlist', '/wishlist'),
  _ProfileMenuItem(Icons.local_offer_outlined, 'Coupons', 'coupons'),
  _ProfileMenuItem(Icons.help_outline, 'Help Center', 'help-center'),
  _ProfileMenuItem(Icons.credit_card_outlined, 'Saved Cards', 'saved-cards'),
  _ProfileMenuItem(
    Icons.location_on_outlined,
    'Saved Address',
    'saved-address',
  ),
  _ProfileMenuItem(
    Icons.notifications_none,
    'Notification Settings',
    'notification-settings',
  ),
];

// =============================================================================
// PROFILE HOVER MENU
// =============================================================================

class _ProfileHoverMenu extends StatefulWidget {
  const _ProfileHoverMenu();

  @override
  State<_ProfileHoverMenu> createState() => _ProfileHoverMenuState();
}

class _ProfileHoverMenuState extends State<_ProfileHoverMenu> {
  final LayerLink _layerLink = LayerLink();

  final OverlayPortalController _overlayController = OverlayPortalController();

  Timer? _closeTimer;
  Timer? _authPollTimer;

  bool _isLoggedIn = false;

  String _userName = 'My Account';

  // ---------------------------------------------------------------------------
  // INIT
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _refreshAuthState();

    _authPollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshAuthState(),
    );
  }

  // ---------------------------------------------------------------------------
  // AUTH STATE
  // ---------------------------------------------------------------------------

  Future<void> _refreshAuthState() async {
    final loggedIn =
        ApiService.getToken() != null && ApiService.getToken()!.isNotEmpty;

    if (loggedIn != _isLoggedIn) {
      // Login/logout state flipped — reload the name too.
      final name = loggedIn ? await ApiService.getUserName() : null;
      if (!mounted) return;
      setState(() {
        _isLoggedIn = loggedIn;
        _userName = name ?? 'My Account';
      });

      // Cart count also needs to reflect the new user's cart —
      // or empty out on logout.
      if (loggedIn) {
        try {
          final cart = await CartService.getCart();
          cartItemCount.value = cart.items.length;
        } catch (_) {
          // Silent — badge stays whatever it was.
        }
      } else {
        cartItemCount.value = 0;
      }
    } else if (loggedIn && _userName == 'My Account') {
      // Still logged in but name hasn't loaded yet (e.g. first check
      // right after token was set, before prefs write completed).
      final name = await ApiService.getUserName();
      if (!mounted) return;
      if (name != null) setState(() => _userName = name);
    }
  }

  // ---------------------------------------------------------------------------
  // OPEN DROPDOWN
  // ---------------------------------------------------------------------------

  void _open() {
    _closeTimer?.cancel();

    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  // ---------------------------------------------------------------------------
  // CLOSE DROPDOWN
  // ---------------------------------------------------------------------------

  void _scheduleClose() {
    _closeTimer?.cancel();

    _closeTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted) {
        _overlayController.hide();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // NAVIGATE
  // ---------------------------------------------------------------------------

  void _navigate(String routeOrSlug) {
    _overlayController.hide();

    final target = routeOrSlug.startsWith('/')
        ? routeOrSlug
        : '/profile/details?section=$routeOrSlug';

    if (_isLoggedIn) {
      context.push(target);
    } else {
      context.push(
        Uri(path: '/login', queryParameters: {'redirect': target}).toString(),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  Future<void> _logout() async {
    _overlayController.hide();
    await AuthService.logout();
    cartItemCount.value = 0; // ← ADD THIS LINE
    if (!mounted) return;
    setState(() {
      _isLoggedIn = false;
      _userName = 'My Account';
    });
    context.push('/home');
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _authPollTimer?.cancel();
    _closeTimer?.cancel();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) {
          return Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _overlayController.hide();
              },
              child: Stack(
                children: [
                  CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    targetAnchor: Alignment.bottomCenter,
                    followerAnchor: Alignment.topRight,
                    offset: const Offset(20, 8),
                    child: MouseRegion(
                      onEnter: (_) => _open(),
                      onExit: (_) => _scheduleClose(),
                      child: _ProfileDropdownPanel(
                        isLoggedIn: _isLoggedIn,
                        userName: _userName,
                        onItemTap: _navigate,
                        onLoginTap: () {
                          _overlayController.hide();

                          context.push('/login');
                        },
                        onLogoutTap: _logout,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: MouseRegion(
          onEnter: (_) => _open(),
          onExit: (_) => _scheduleClose(),
          child: _ProfileTrigger(
            isLoggedIn: _isLoggedIn,
            userName: _userName,
            onTap: _open,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// PROFILE TRIGGER
//
// IMPORTANT:
// Profile name is ALWAYS shown below the icon.
// No tooltip.
// =============================================================================

class _ProfileTrigger extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;
  final VoidCallback onTap;

  const _ProfileTrigger({
    required this.isLoggedIn,
    required this.userName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = isLoggedIn
        ? userName.trim().split(RegExp(r'\s+')).first
        : 'Profile';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 22, color: AppColors.black),

            const SizedBox(height: 3),

            Text(
              displayName,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// PROFILE DROPDOWN
// =============================================================================

class _ProfileDropdownPanel extends StatelessWidget {
  final bool isLoggedIn;
  final String userName;

  final void Function(String route) onItemTap;

  final VoidCallback onLoginTap;
  final VoidCallback onLogoutTap;

  const _ProfileDropdownPanel({
    required this.isLoggedIn,
    required this.userName,
    required this.onItemTap,
    required this.onLoginTap,
    required this.onLogoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(12),
      color: AppColors.white,
      child: Container(
        width: 260,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // -----------------------------------------------------------------
            // LOGGED OUT
            // -----------------------------------------------------------------
            if (!isLoggedIn)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onLoginTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            // -----------------------------------------------------------------
            // LOGGED IN
            // -----------------------------------------------------------------
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.cream,
                      child: Icon(Icons.person, color: AppColors.black),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Welcome $userName',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1),

            // -----------------------------------------------------------------
            // MENU ITEMS
            // -----------------------------------------------------------------
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _profileMenuItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final item = _profileMenuItems[index];

                  return InkWell(
                    onTap: () {
                      onItemTap(item.route);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 18, color: AppColors.black),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // -----------------------------------------------------------------
            // LOGOUT
            // -----------------------------------------------------------------
            if (isLoggedIn) ...[
              const Divider(height: 1),

              InkWell(
                onTap: onLogoutTap,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 18, color: Colors.red),

                      SizedBox(width: 12),

                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
