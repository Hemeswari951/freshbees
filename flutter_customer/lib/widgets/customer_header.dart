import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/search_service.dart';
import './app_colors.dart';

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

  // These must match the routes defined in app_router.dart
  // (/home, /home/men, /home/women, /home/kids, /home/beauty).
  final List<_NavLink> _navLinks = const [
    _NavLink('Men', '/home/men'),
    _NavLink('Women', '/home/women'),
    _NavLink('Kids', '/home/kids'),
    _NavLink('Beauty', '/home/beauty'),
    _NavLink('Home', '/home'),
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // SEARCH — same debounced flow as HomeScreen (mobile), same shared
  // HomeService.getSearchSuggestions() call, same OverlayPortal pattern
  // (no focus-loss race condition — suggestion taps register reliably).
  // ---------------------------------------------------------------------
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
      setState(() => _isSuggesting = true);
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
    _searchController.text = suggestion.text;
    _handleSearch(suggestion.text);
  }

  // Checks login state before navigating to a protected route.
  // If not logged in, redirects to /login and passes the intended
  // destination so the login flow can send the user back afterwards.
  void _goToProtected(BuildContext context, String route) {
    final isLoggedIn =
        ApiService.getToken() != null && ApiService.getToken()!.isNotEmpty;

    if (isLoggedIn) {
      context.push(route);
    } else {
      context.push(
        Uri(path: '/login', queryParameters: {'redirect': route}).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo
          InkWell(
            onTap: () => context.push('/home'),
            child: const Text(
              'Thiraa',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.black,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 32),

          // Category nav links
          Row(
            children: _navLinks
                .map(
                  (link) => Padding(
                    padding: const EdgeInsets.only(right: 22),
                    child: InkWell(
                      onTap: () => context.push(link.route),
                      child: Text(
                        link.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(width: 24),

          // Lengthy search bar — wrapped in CompositedTransformTarget +
          // OverlayPortal so the suggestions dropdown anchors under it
          // and taps register reliably.
          Expanded(
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
                            offset: const Offset(0, 46),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.white,
                                child: SizedBox(
                                  width:
                                      420, // roughly matches the search bar width
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
                                        final s = _suggestions[index];
                                        return ListTile(
                                          dense: true,
                                          leading: Icon(
                                            s.isTag
                                                ? Icons.sell_outlined
                                                : Icons.search_rounded,
                                            size: 18,
                                            color: AppColors.textGrey,
                                          ),
                                          title: Text(
                                            s.text,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          trailing: s.isTag
                                              ? const Text(
                                                  'tag',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black38,
                                                  ),
                                                )
                                              : null,
                                          onTap: () => _onSuggestionTap(s),
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
                  height: 42,
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
                            hintText: 'Search for products, brands and more',
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
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 28),

          // Icon + label actions
          const _ProfileHoverMenu(), // <-- Profile now opens a hover dropdown
          const SizedBox(width: 22),
          _HeaderAction(
            icon: Icons.favorite_border,
            label: 'Wishlist',
            onTap: () => _goToProtected(context, '/wishlist'),
          ),
          const SizedBox(width: 22),
          _HeaderAction(
            icon: Icons.shopping_cart_outlined,
            label: 'Cart',
            onTap: () => _goToProtected(context, '/cart'),
          ),
          const SizedBox(width: 22),
          _HeaderAction(
            icon: Icons.notifications_none,
            label: 'Notifications',
            onTap: () => _goToProtected(context, '/notifications'),
          ),
        ],
      ),
    );
  }
}

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

// ---------------------------------------------------------------------------
// Profile hover dropdown
// ---------------------------------------------------------------------------

/// A menu item shown inside the Profile dropdown.
/// [route] is where it navigates to when the user is logged in.
/// When logged OUT, tapping any item redirects to /login?redirect=<route>,
/// same pattern as _goToProtected above.
class _ProfileMenuItem {
  final IconData icon;
  final String label;
  final String route;
  const _ProfileMenuItem(this.icon, this.label, this.route);
}

// TODO: adjust these routes to match whatever you actually register
// in app_router.dart under /profile/...
const List<_ProfileMenuItem> _profileMenuItems = [
  _ProfileMenuItem(Icons.dashboard_outlined, 'Overview', 'overview'),
  _ProfileMenuItem(Icons.receipt_long_outlined, 'Orders', 'orders'),
  _ProfileMenuItem(
    Icons.favorite_border,
    'Wishlist',
    '/wishlist',
  ), // separate route, not a tab
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

class _ProfileHoverMenu extends StatefulWidget {
  const _ProfileHoverMenu();

  @override
  State<_ProfileHoverMenu> createState() => _ProfileHoverMenuState();
}

class _ProfileHoverMenuState extends State<_ProfileHoverMenu> {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayController = OverlayPortalController();
  Timer? _closeTimer;
  Timer? _authPollTimer; // ADD

  bool _isLoggedIn = false; // CHANGED: was a getter, now a real field
  String _userName = 'My Account';

  @override
  void initState() {
    super.initState();
    _refreshAuthState();
    // Since the header lives inside a ShellRoute and /login is pushed
    // OUTSIDE the shell, popping back from login never rebuilds this
    // widget. Polling every second is a cheap, self-contained way to
    // pick up the login/logout without wiring a global notifier.
    _authPollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshAuthState(),
    );
  }

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
    } else if (loggedIn && _userName == 'My Account') {
      // Still logged in but name hasn't loaded yet (e.g. first check
      // right after token was set, before prefs write completed).
      final name = await ApiService.getUserName();
      if (!mounted) return;
      if (name != null) setState(() => _userName = name);
    }
  }

  void _open() {
    _closeTimer?.cancel();
    if (!_overlayController.isShowing) {
      _overlayController.show();
    }
  }

  void _scheduleClose() {
    _closeTimer?.cancel();
    _closeTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) _overlayController.hide();
    });
  }

  void _navigate(String routeOrSlug) {
    _overlayController.hide();
    final String target = routeOrSlug.startsWith('/')
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

  Future<void> _logout() async {
    _overlayController.hide();
    await AuthService.logout();
    if (!mounted) return;
    setState(() {
      _isLoggedIn = false;
      _userName = 'My Account';
    });
    context.push('/home');
  }

  @override
  void dispose() {
    _authPollTimer?.cancel(); // ADD
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // REMOVE the old postFrameCallback check — polling now handles this.

    return CompositedTransformTarget(
      link: _layerLink,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) {
          return Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => _overlayController.hide(),
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
            onTap:
                _open, // also fixed: was `() => _open` (bug, never called it)
          ),
        ),
      ),
    );
  }
}

/// Header trigger: shows a generic person icon + "Profile" when logged out,
/// or a person icon + the user's first name when logged in.
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
    if (!isLoggedIn) {
      return _HeaderAction(
        icon: Icons.person_outline,
        label: 'Profile',
        onTap: onTap,
      );
    }

    // Show only the first name in the header so it stays compact.
    final displayName = userName.trim().split(RegExp(r'\s+')).first;

    return _HeaderAction(
      icon: Icons.person_outline,
      label: displayName,
      onTap: onTap,
    );
  }
}

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
      elevation: 8,
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
            // Top section: differs based on login state.
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
                      onPressed: onLoginTap, // navigates to /login
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          96,
                          213,
                          234,
                        ), // attractive coral accent
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            4,
                          ), // square-ish corners
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
                        'WelCome $userName',
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

            // Menu items — same list either way.
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: _profileMenuItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, index) {
                  final item = _profileMenuItems[index];
                  return InkWell(
                    onTap: () => onItemTap(item.route),
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

            // Logout — only shown when logged in.
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
