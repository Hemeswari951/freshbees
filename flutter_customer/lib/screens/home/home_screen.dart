import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        child: Column(
          children: [
            if (isMobile) _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: _buildSelectedCategoryContent(),
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
                    onSubmitted: (_) {
                      // TODO: point this at your actual search route.
                    },
                  ),
                ),
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
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildHeaderIconButton(
          icon: Icons.notifications_none_outlined,
          onTap: () {
            // TODO: point this at your actual notifications route.
          },
        ),
        const SizedBox(width: 8),
        _buildHeaderIconButton(
          icon: Icons.shopping_bag_outlined,
          showBadge: true,
          onTap: () => context.go('/bag'),
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
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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