import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../services/api_service.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _userName = 'User';
  bool _isLoggedIn = false;

  // Location shown in the header. Wire this up to a real location
  // service / picker later if needed.
  String _location = 'Chennai, Tamil Nadu';

  bool _showLoginNotification = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final TextEditingController _searchController = TextEditingController();

  // Toggle state for the header category selector — starts from
  // whichever category the route opened with.
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
    _checkLoginStatus();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(
      begin: -10,
      end: 10,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    await ApiService.loadToken();
    final prefs = await SharedPreferences.getInstance();
    final token = ApiService.getToken();

    final name1 = prefs.getString('userName');
    final name2 = prefs.getString('user_name');

    String displayName = 'Guest';

    if (name1 != null && name1.trim().isNotEmpty) {
      displayName = name1.trim();
    } else if (name2 != null && name2.trim().isNotEmpty) {
      displayName = name2.trim();
    }

    setState(() {
      _isLoggedIn = (token != null && token.isNotEmpty);
      _userName = displayName;
    });
  }

  void _triggerGuestPopUp() {
    setState(() {
      _showLoginNotification = true;
    });
    _shakeController.forward(from: 0.0);

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _showLoginNotification = false;
        });
      }
    });
  }

  void _handleShoppingAction() {
    if (!_isLoggedIn) {
      _triggerGuestPopUp();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Opening details...')));
    }
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < kMobileBreakpoint;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMobile) ...[
                    _buildLocationRow(),
                    const SizedBox(height: 14),
                    _buildSearchRow(),
                    const SizedBox(height: 18),
                    _buildCategoryToggle(),
                    const SizedBox(height: 24),
                  ],
                  _buildSelectedCategoryContent(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            if (_showLoginNotification)
              Positioned(
                bottom: 16,
                right: 16,
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(_shakeAnimation.value, 0),
                      child: child,
                    );
                  },
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLoginNotification = false;
                      });
                      context.push('/login');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFB8956A),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.lock_outline,
                            color: Color(0xFFB8956A),
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Please continue to login',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
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
  // BODY: each toggle has its own file — tap "Men" and MenTab() is what
  // gets called, tap "Kids" and KidsTab() gets called, and so on.
  // Add your real per-category content inside each tab file.
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
  // HEADER: location row
  // ---------------------------------------------------------------------
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
  // HEADER: search bar + notification/bag icons
  // ---------------------------------------------------------------------
  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2ECE4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search,
                  size: 20,
                  color: Colors.black54,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    onSubmitted: (_) => _handleShoppingAction(),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: hook up voice search.
                    _handleShoppingAction();
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
                    _handleShoppingAction();
                  },
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildHeaderIconButton(
          icon: Icons.notifications_none_outlined,
          onTap: _handleShoppingAction,
        ),
        const SizedBox(width: 8),
        _buildHeaderIconButton(
          icon: Icons.shopping_bag_outlined,
          showBadge: true,
          onTap: () {
            if (!_isLoggedIn) {
              _triggerGuestPopUp();
            } else {
              context.push('/cart');
            }
          },
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
  // HEADER: category toggle
  // ---------------------------------------------------------------------
  Widget _buildCategoryToggle() {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final label = cat['label'] as String;
          final icon = cat['icon'] as IconData;
          final isSelected = _selectedCategory == label;

          return GestureDetector(
            onTap: () => _selectCategory(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 68,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : const Color(0xFFF2ECE4),
                borderRadius: BorderRadius.circular(16),
                border: isSelected
                    ? Border.all(color: const Color(0xFFB8956A), width: 1.5)
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black87,
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