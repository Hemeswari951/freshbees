import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../../services/api_service.dart';
import '../../services/shop_service.dart';
import '../../models/shop_model.dart';
import '../../services/product_service.dart';
import '../../models/product_model.dart';
import '../product/product_details_screen.dart';
import '../../services/cart_service.dart';
import '../cart/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  String _userName = 'User';
  bool _isLoggedIn = false;
  String? _selectedCategory; // Tracks the currently selected category

  bool _showLoginNotification = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final Set<String> _wishlistItems = {};
  List<Map<String, dynamic>> _recommendedProducts = [];
  bool _isLoadingProducts = true;

  // Real shops created in the admin panel (replaces hardcoded list)
  List<ShopModel> _nearbyShops = [];
  bool _isLoadingShops = true;

  // Number shown on the bag badge in the top bar.
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _loadNearbyShops();
    _loadRecommendedProducts();
    _loadCartCount();

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

    if (_isLoggedIn) {
      _loadCartCount();
    }
  }

  Future<void> _loadNearbyShops() async {
    try {
      final shops = await ShopService.getNearbyShops();
      if (!mounted) return;
      setState(() {
        _nearbyShops = shops;
        _isLoadingShops = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingShops = false;
      });
    }
  }

  Future<void> _loadRecommendedProducts() async {
    try {
      final products = await ProductService.getProducts();
      if (!mounted) return;
      setState(() {
        // Reuses the existing card UI, which reads item['id']/['name']/
        // ['price']/['image'] — mapping ProductModel into that shape here
        // means the widget below doesn't need to change at all.
        _recommendedProducts = products
            .map(
              (p) => {
                'id': p.id.toString(),
                'name': p.productName,
                'price': '₹${p.price.toStringAsFixed(0)}',
                'image': p.thumbnail.isNotEmpty
                    ? '${ApiService.serverUrl}${p.thumbnail}'
                    : null,

                    // Add your category property here (change p.categoryName if your model uses a different name)
                'categoryName': p.categoryName ?? 'Formal',
              },
            )
            .toList();
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  Future<void> _loadCartCount() async {
    if (!_isLoggedIn) return;
    try {
      final result = await CartService.getCart();
      if (!mounted) return;
      setState(() {
        _cartItemCount = result.items.length;
      });
    } catch (e) {
      // Bag badge just stays at its last known value if this fails —
      // not worth surfacing an error for a background count refresh.
    }
  }

  Future<void> _openCart() async {
    if (!_isLoggedIn) {
      _triggerGuestPopUp();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
    // Quantities/removals on the Cart screen can change the count, so
    // refresh the badge as soon as the user comes back to Home.
    _loadCartCount();
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

  void _toggleWishlist(String id) {
    if (!_isLoggedIn) {
      _triggerGuestPopUp();
      return;
    }
    setState(() {
      if (_wishlistItems.contains(id)) {
        _wishlistItems.remove(id);
      } else {
        _wishlistItems.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filter products based on selected category. If null, show all.
    final filteredProducts = _selectedCategory == null
        ? _recommendedProducts
        : _recommendedProducts.where((item) {
            final category = item['categoryName']?.toString() ?? 'Formal';
            return category.toLowerCase() == _selectedCategory!.toLowerCase();
          }).toList();
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.menu, size: 26, color: Colors.black87),
                      Row(
                        children: [
                          Image.asset(
                            "assets/logo.png",
                            height: 28,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFB8956A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'thiraa',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Serif',
                              color: Colors.black,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.notifications_none_outlined,
                              color: Colors.black87,
                            ),
                            onPressed: _handleShoppingAction,
                          ),
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.shopping_bag_outlined,
                                  color: Colors.black87,
                                ),
                                onPressed: _openCart,
                              ),
                              if (_cartItemCount > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      _cartItemCount > 9 ? '9+' : '$_cartItemCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFFE8DFD1),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF8B7355),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Hello, $_userName ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const Icon(
                                Icons.auto_awesome,
                                size: 16,
                                color: Color(0xFFB8956A),
                              ),
                            ],
                          ),
                          const Text(
                            'Discover your perfect fit',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _handleShoppingAction,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2ECE4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
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
                                    onPressed: _handleShoppingAction,
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
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCategoryItem(Icons.dry_cleaning_outlined, 'Women'),
                      _buildCategoryItem(Icons.checkroom_outlined, 'Men'),
                      _buildCategoryItem(Icons.child_care_outlined, 'Kids'),
                      _buildCategoryItem(Icons.clean_hands_outlined, 'Beauty'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _handleShoppingAction,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2ECE4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(
                                        Icons.auto_awesome,
                                        size: 14,
                                        color: Color(0xFFB8956A),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'New Arrivals',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Serif',
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Fresh styles. Just for you.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: const [
                                      Text(
                                        'Explore Now',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF8B7355),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        size: 14,
                                        color: Color(0xFF8B7355),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(20),
                              ),
                              child: Container(
                                height: 120,
                                color: const Color(0xFFE8DFD1),
                                child: const Icon(
                                  Icons.checkroom,
                                  size: 40,
                                  color: Colors.black38,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. --- NEARBY SHOPS SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nearby Shops',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleShoppingAction,
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B7355),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Nearby Shops Horizontal List (real shops from admin panel)
                  _isLoadingShops
                      ? const SizedBox(
                          height: 160,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          ),
                        )
                      : _nearbyShops.isEmpty
                          ? Container(
                              height: 160,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2ECE4),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'No shops nearby yet',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 160,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _nearbyShops.length,
                                itemBuilder: (context, index) {
                                  final shop = _nearbyShops[index];

                                  return GestureDetector(
                                    onTap: _handleShoppingAction, // Shop tap action
                                    child: Container(
                                      width: 140,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF2ECE4),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(16)),
                                            child: Container(
                                              height: 90,
                                              width: double.infinity,
                                              color: const Color(0xFFE8DFD1),
                                              child: shop.logoUrl != null
                                                  ? Image.network(
                                                      shop.logoUrl!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (c, e, s) =>
                                                          const Icon(
                                                        Icons.storefront_outlined,
                                                        size: 40,
                                                        color: Colors.black38,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.storefront_outlined,
                                                      size: 40,
                                                      color: Colors.black38,
                                                    ),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  shop.shopName,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  shop.categoryLabel,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.black54,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recommended For You',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleShoppingAction,
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B7355),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  (_isLoadingProducts || _recommendedProducts.isNotEmpty)
                      ? (_recommendedProducts.isEmpty
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          // UPDATED: Use MaxCrossAxisExtent for responsive card widths
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220, // Maximum width of each product card
                            childAspectRatio: 0.56,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: 4,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: _handleShoppingAction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      height: 180,
                                      width: double.infinity,
                                      color: const Color(0xFFE8DFD1),
                                      child: const Icon(
                                        Icons.image_outlined,
                                        size: 40,
                                        color: Colors.black26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 12,
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    height: 12,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.black12,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                        : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220, 
                            childAspectRatio: 0.56, // Adjusted slightly to fit the new text layout perfectly
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _recommendedProducts.length,
                          itemBuilder: (context, index) {
                            final item = _recommendedProducts[index];
                            final isWish = _wishlistItems.contains(item['id']);
                            
                            // Mocking or extracting data to match the Admin UI
                            final String rating = item['rating']?.toString() ?? '4.3';
                            final String reviews = item['reviews']?.toString() ?? '11.6k';
                            final int stock = item['totalStock'] as int? ?? 4; 
                            final String category = item['categoryName']?.toString() ?? 'Formal';
                            
                            // Parse price safely to calculate the discount and MRP
                            double sellingPrice = 0.0;
                            if (item['price'] is num) {
                              sellingPrice = (item['price'] as num).toDouble();
                            } else if (item['price'] is String) {
                              sellingPrice = double.tryParse((item['price'] as String).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                            }
                            

                          final double mrp = item['mrp'] != null ? (item['mrp'] as num).toDouble() : (sellingPrice > 0 ? sellingPrice * 1.25 : 2000.0);
                            final int discountPercent = mrp > sellingPrice && mrp > 0 ? ((mrp - sellingPrice) / mrp * 100).toInt() : 25;

                            return GestureDetector(
                              onTap: () {
                                // 1. Parse the product ID
                                final int productId = int.parse(item['id'].toString());
                                
                                // 2. Navigate to the Details Screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductViewScreen(productId: productId),
                                  ),
                                ).then((_) => _loadCartCount());
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: const Color(0xFFEAEAEA)),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Stack(
                                      children: [
                                        // Product Image
                                        AspectRatio(
                                          aspectRatio: 1.05,
                                          child: Container(
                                            color: const Color(0xFFF2ECE4),
                                            alignment: Alignment.center,
                                            child: item['image'] != null
                                                ? Image.network(
                                                    item['image'],
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    errorBuilder: (c, e, s) =>
                                                        const Icon(Icons.image, size: 40, color: Colors.black38),
                                                  )
                                                : const Icon(Icons.image, size: 40, color: Colors.black38),
                                          ),
                                        ),
                                        // Rating badge (bottom-left)
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  rating,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                                ),
                                                const SizedBox(width: 2),
                                                const Icon(Icons.star, size: 11, color: Colors.teal),
                                                const SizedBox(width: 4),
                                                Container(width: 1, height: 10, color: Colors.black26),
                                                const SizedBox(width: 4),
                                                Text(
                                                  reviews,
                                                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        // Stock alert badge (bottom-right)
                                        if (stock < 5)
                                          Positioned(
                                            bottom: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE57373),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'Only $stock left',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        // Wishlist Button (top-right)
                                        Positioned(
                                          top: 6,
                                          right: 6,
                                          child: GestureDetector(
                                            onTap: () => _toggleWishlist(item['id']),
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.92),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                isWish ? Icons.favorite : Icons.favorite_border,
                                                size: 13,
                                                color: isWish ? Colors.red : Colors.black54,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Text Information Section
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            item['name'] ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            category,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Pricing Row
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 5,
                                            children: [
                                              Text(
                                                'Rs. ${sellingPrice.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              if (discountPercent > 0) ...[
                                                Text(
                                                  'Rs. ${mrp.toStringAsFixed(0)}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.black54,
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                                Text(
                                                  '($discountPercent% OFF)',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF388E3C), // Matching Admin green
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ))
                      : Container(
                          height: 200,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2ECE4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'No products yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2ECE4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '✦ Not sure what suits you?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Let AI find the perfect style for you.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _handleShoppingAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text(
                            'Discover with AI',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) context.push('/categories');
            if (index == 3) context.push('/wishlist');
            if (index == 4) {
              if (_isLoggedIn) {
                context.push('/profile');
              } else {
                _triggerGuestPopUp();
              }
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Home",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: "Explore",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              label: "Try-On",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              label: "Wishlist",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    final isSelected = _selectedCategory == label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          // If tapped again, deselect (shows all products). Otherwise, set the filter.
          _selectedCategory = _selectedCategory == label ? null : label;
        });
      },
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB8956A) : const Color(0xFFF2ECE4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black87, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
