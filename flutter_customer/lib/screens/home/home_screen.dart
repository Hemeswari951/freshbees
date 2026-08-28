import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../product/product_list_screen.dart';
import '../../services/api_service.dart';
import '../../services/search_service.dart';
import '../../screens/notifications/notifications _screen.dart';

import 'tabs/all_tab.dart';
import 'tabs/men_tab.dart';
import 'tabs/women_tab.dart';
import 'tabs/kids_tab.dart';
import 'tabs/beauty_tab.dart';

/// Below this width, the app is treated as "mobile" and the custom
/// location/search/toggle header is shown. At or above this width
/// (web/desktop), your existing shell header is used instead, so
/// this header hides itself.
const double kMobileBreakpoint = 600;

class HomeScreen extends StatefulWidget {
  /// Which toggle should be active when this screen opens — set by the
  /// route ('/home' = All, '/home/men' = Men, etc). Defaults to 'All'.
  final String initialCategory;

  const HomeScreen({super.key, this.initialCategory = 'All'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Location shown in the header. Wire this up to a real location
  // service / picker later if needed.
  final String _location = 'Chennai, Tamil Nadu';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  final OverlayPortalController _searchOverlayController =
      OverlayPortalController();

  // Toggle state for the header category selector — starts from
  // whichever category the route opened with.
  late String _selectedCategory = widget.initialCategory;

  Timer? _debounce;
  List<SearchSuggestion> _suggestions = [];
  bool _isSuggesting = false;

  final List<Map<String, dynamic>> _categories = const [
    {'label': 'All', 'icon': Icons.apps_rounded},
    {'label': 'Men', 'icon': Icons.checkroom_outlined},
    {'label': 'Women', 'icon': Icons.dry_cleaning_outlined},
    {'label': 'Kids', 'icon': Icons.child_care_outlined},
    {'label': 'Beauty', 'icon': Icons.clean_hands_outlined},
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // SEARCH — debounced, calls the shared HomeService method. Overlay is
  // driven by OverlayPortalController (same pattern as _ProfileHoverMenu
  // in customer_header.dart) so suggestion taps register reliably —
  // no focus-loss race condition tearing the overlay down early.
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

  void _selectCategory(String label) {
    setState(() {
      _selectedCategory = label;
    });

    // Reflect the selected toggle in the URL — each toggle is its own
    // route, so /home/men, /home/women, /home/kids, /home/beauty.
    // 'All' maps back to plain /home.
    final route = label == 'All' ? '/home' : '/home/${label.toLowerCase()}';
    context.go(route);
  }

  void _goToSearch(String query) {
    if (query.trim().isEmpty) return;
    if (_searchOverlayController.isShowing) {
      _searchOverlayController.hide();
    }
    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductListScreen(
          args: ProductListArgs.search(query: query.trim()),
        ),
      ),
    );
  }

  void _onSuggestionTap(SearchSuggestion suggestion) {
    _searchController.text = suggestion.text;
    // Both tag and product suggestions route through the same search —
    // backend matches product_name OR tag_name, so the text alone
    // filters correctly on ProductListScreen.
    _goToSearch(suggestion.text);
  }

  // Checks login state before navigating to a protected route.
  // If not logged in, redirects to /login and passes the intended
  // destination so the login flow can send the user back afterwards.
  void _goToProtected(BuildContext context, String route) {
    final isLoggedIn =
        ApiService.getAccessToken() != null && ApiService.getAccessToken()!.isNotEmpty;

    if (isLoggedIn) {
      context.go(route);
    } else {
      context.go(
        Uri(path: '/login', queryParameters: {'redirect': route}).toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Column(
          children: [
            if (isMobile) _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // ==========================================
                    // AI VIRTUAL TRY-ON BANNER
                    // ==========================================

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,

                      decoration: BoxDecoration(
                        color: const Color(0xFFF2ECE4),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Row(
                        children: [
                          // ======================================
                          // LEFT CONTENT
                          // ======================================

                          Expanded(
                            flex: 3,

                            child: Padding(
                              padding: const EdgeInsets.all(20),

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [
                                  const Text(
                                    'AI VIRTUAL TRY-ON',
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                      color: Color(0xFF8B7355),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  const Text(
                                    'Try Before\nYou Buy',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w500,
                                      height: 1.1,
                                      fontFamily: 'Serif',
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  const Text(
                                    'See it on you,\nlove it for real.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // =================================
                                  // TRY NOW BUTTON
                                  // =================================
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      context.go('/trial');
                                    },

                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,

                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),

                                      elevation: 0,
                                    ),

                                    label: const Text(
                                      'Try Now',
                                      style: TextStyle(fontSize: 12),
                                    ),

                                    icon: const Icon(
                                      Icons.arrow_forward,
                                      size: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ======================================
                          // RIGHT IMAGE / PLACEHOLDER
                          // ======================================
                          Expanded(
                            flex: 2,

                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(20),
                              ),

                              child: Container(
                                height: 210,

                                color: const Color(0xFFE8DFD1),

                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.black38,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ==========================================
                    // SPACE AFTER AI BANNER
                    // ==========================================
                    const SizedBox(height: 24),

                    _buildSelectedCategoryContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // No bottomNavigationBar here — handled by the shared layout/shell.
    );
  }

  // ---------------------------------------------------------------------
  // BODY: each toggle has its own file, and each tab calls its own
  // dedicated HomeService method — tap "Men" and MenTab() runs, which
  // calls HomeService.getMenShops() itself, and so on. Home doesn't
  // fetch or filter anything.
  // ---------------------------------------------------------------------
  Widget _buildSelectedCategoryContent() {
    switch (_selectedCategory) {
      case 'Men':
        return const MenTab();
      case 'Women':
        return const WomenTab();
      case 'Kids':
        return const KidsTab();
      case 'Beauty':
        return const BeautyTab();
      case 'All':
      default:
        return const AllTab();
    }
  }

  // ---------------------------------------------------------------------
  // HEADER — sits above the scrollable content, with a bottom shadow so
  // it visually separates from whatever's below it.
  // ---------------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLocationRow(),
          const SizedBox(height: 14),
          _buildSearchRow(),
          const SizedBox(height: 14),
          _buildCategoryToggle(),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return GestureDetector(
      onTap: () {
        // TODO: open a location picker / detect current location.
      },
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 18,
            color: Color(0xFF8B7355),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _location,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Colors.black54,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // SEARCH ROW — wrapped in CompositedTransformTarget + OverlayPortal so
  // the suggestions dropdown anchors exactly under this bar and taps on
  // suggestions register reliably (no manual OverlayEntry race).
  // ---------------------------------------------------------------------
  Widget _buildSearchRow() {
    return Row(
      children: [
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
                      // Tap outside the suggestion panel — just close it.
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
                              elevation: 4,
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 40,
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
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Colors.black.withOpacity(0.05),
                                    ),
                                    itemBuilder: (context, index) {
                                      final s = _suggestions[index];
                                      return ListTile(
                                        dense: true,
                                        leading: Icon(
                                          s.isTag
                                              ? Icons.sell_outlined
                                              : Icons.search_rounded,
                                          size: 18,
                                          color: const Color(0xFF8B7355),
                                        ),
                                        title: Text(
                                          s.text,
                                          style: const TextStyle(
                                            fontSize: 13,
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
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2ECE4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 20, color: Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.black45,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        onChanged: _onSearchChanged,
                        onSubmitted: _goToSearch,
                      ),
                    ),
                    if (_isSuggesting)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      GestureDetector(
                        onTap: () {
                          // TODO: hook up voice search.
                        },
                        child: const Icon(
                          Icons.mic_none_rounded,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          // TODO: hook up visual/camera search.
                        },
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildHeaderIconButton(
  icon: Icons.notifications_none_outlined,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  },
),

        const SizedBox(width: 8),
        _buildHeaderIconButton(
          icon: Icons.shopping_cart_outlined,
          showBadge: true,
          onTap: () => _goToProtected(context, '/cart'),
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF2ECE4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: Colors.black87),
          ),
          if (showBadge)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Category toggle — plain, no boxed pills. Selected item gets a very
  // light background fill and a bottom border under just that item.
  // ---------------------------------------------------------------------
  Widget _buildCategoryToggle() {
    return SizedBox(
      height: 58,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = _selectedCategory == label;

          return GestureDetector(
            onTap: () => _selectCategory(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                // Very light fill only when selected — plain otherwise.
                color: isSelected
                    ? const Color(0xFFB8956A).withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  bottom: BorderSide(
                    color: isSelected
                        ? const Color(0xFFB8956A)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 17,
                    color: isSelected
                        ? const Color(0xFF8B7355)
                        : Colors.black54,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF3A2E22)
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
