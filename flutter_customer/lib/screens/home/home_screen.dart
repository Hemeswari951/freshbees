import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/cart_service.dart';
import '../../services/cart_count.dart';

import '../product/product_list_screen.dart';
import '../../services/api_service.dart';
import '../../services/search_service.dart';
import '../../widgets/location_bar.dart';

import 'tabs/all_tab.dart';
import 'tabs/men_tab.dart';
import 'tabs/women_tab.dart';
import 'tabs/kids_tab.dart';
import 'tabs/beauty_tab.dart';

/// Below this width, the app is treated as mobile.
const double kMobileBreakpoint = 600;

class HomeScreen extends StatefulWidget {
  /// Which category should be selected when this screen opens.
  ///
  /// /home       → All
  /// /home/men   → Men
  /// /home/women → Women
  /// /home/kids  → Kids
  /// /home/beauty → Beauty
  final String initialCategory;

  const HomeScreen({super.key, this.initialCategory = 'All'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // =========================================================================
  // SEARCH
  // =========================================================================

  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  final LayerLink _searchLayerLink = LayerLink();

  final OverlayPortalController _searchOverlayController =
      OverlayPortalController();

  Timer? _debounce;

  List<SearchSuggestion> _suggestions = [];

  bool _isSuggesting = false;

  // =========================================================================
  // CATEGORY
  // =========================================================================

  late String _selectedCategory = widget.initialCategory;

  final List<Map<String, dynamic>> _categories = const [
    {'label': 'All', 'icon': Icons.apps_rounded},
    {'label': 'Men', 'icon': Icons.checkroom_outlined},
    {'label': 'Women', 'icon': Icons.dry_cleaning_outlined},
    {'label': 'Kids', 'icon': Icons.child_care_outlined},
    {'label': 'Beauty', 'icon': Icons.clean_hands_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _syncCartCount();
  }

  Future<void> _syncCartCount() async {
    final token = ApiService.getToken();
    if (token == null || token.isEmpty) {
      cartItemCount.value = 0;
      return;
    }
    try {
      final cart = await CartService.getCart();
      cartItemCount.value = cart.items.length;
    } catch (_) {
      // Silent — badge just stays at whatever it was.
    }
  }
  // =========================================================================
  // LIFECYCLE
  // =========================================================================

  @override
  void dispose() {
    _debounce?.cancel();

    _searchFocusNode.dispose();
    _searchController.dispose();

    super.dispose();
  }

  // =========================================================================
  // PROTECTED ROUTES
  // =========================================================================

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

  // =========================================================================
  // SEARCH
  // =========================================================================

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
      }
    });
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

    _goToSearch(suggestion.text);
  }

  // =========================================================================
  // CATEGORY
  // =========================================================================

  void _selectCategory(String label) {
    setState(() {
      _selectedCategory = label;
    });

    final route = label == 'All' ? '/home' : '/home/${label.toLowerCase()}';

    context.go(route);
  }

  // =========================================================================
  // BUILD
  // =========================================================================

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
                  horizontal: 10,
                  vertical: 10,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    // =======================================================
                    // AI VIRTUAL TRY-ON BANNER
                    // =======================================================

                    Container(
                      width: double.infinity,

                      decoration: BoxDecoration(
                        color: const Color(0xFFF2ECE4),
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Row(
                        children: [
                          // -------------------------------------------------
                          // LEFT CONTENT
                          // -------------------------------------------------

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

                          // -------------------------------------------------
                          // RIGHT IMAGE / PLACEHOLDER
                          // -------------------------------------------------
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

                    const SizedBox(height: 24),

                    // =======================================================
                    // CATEGORY CONTENT
                    // =======================================================
                    _buildSelectedCategoryContent(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom navigation is handled by the shared shell.
    );
  }

  // =========================================================================
  // CATEGORY CONTENT
  // =========================================================================

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

  // =========================================================================
  // HEADER
  // =========================================================================

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
          // Shared across every screen — reads/writes LocationManager().
          const LocationBar(),

          const SizedBox(height: 14),

          _buildSearchRow(),

          const SizedBox(height: 14),

          _buildCategoryToggle(),
        ],
      ),
    );
  }

  // =========================================================================
  // SEARCH ROW
  // =========================================================================

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
                                      final suggestion = _suggestions[index];

                                      return ListTile(
                                        dense: true,

                                        leading: Icon(
                                          suggestion.isTag
                                              ? Icons.sell_outlined
                                              : Icons.search_rounded,

                                          size: 18,

                                          color: const Color(0xFF8B7355),
                                        ),

                                        title: Text(
                                          suggestion.text,

                                          style: const TextStyle(
                                            fontSize: 13,
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

                                        onTap: () =>
                                            _onSuggestionTap(suggestion),
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
                          // TODO: voice search
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
                          // TODO: visual search
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
          onTap: () => _goToProtected(context, '/notifications'),
        ),

        const SizedBox(width: 8),

        ValueListenableBuilder<int>(
          valueListenable: cartItemCount,
          builder: (context, count, child) {
            return _buildHeaderIconButton(
              icon: Icons.shopping_cart_outlined,
              badgeCount: count,
              onTap: () => _goToProtected(context, '/cart'),
            );
          },
        ),
      ],
    );
  }

  // =========================================================================
  // HEADER ICON BUTTON
  // =========================================================================

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
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

          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // CATEGORY TOGGLE
  // =========================================================================

  Widget _buildCategoryToggle() {
    return SizedBox(
      height: 58,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,

        itemCount: _categories.length,

        itemBuilder: (context, index) {
          final category = _categories[index];

          final label = category['label'] as String;

          final icon = category['icon'] as IconData;

          final isSelected = _selectedCategory == label;

          return GestureDetector(
            onTap: () => _selectCategory(label),

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),

              margin: const EdgeInsets.only(right: 4),

              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),

              decoration: BoxDecoration(
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
