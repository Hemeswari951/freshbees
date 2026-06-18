import 'package:flutter/material.dart';
import 'main_scaffold.dart'; // for AppColors
import 'profile/profile_screen.dart'; // for ProfileScreen

/// No Scaffold/background/footer here - MainScaffold provides those.
/// This widget only returns its own content (header + category selector + banners + products).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class CategoryItem {
  final String label;
  final String imageUrl;
  const CategoryItem({required this.label, required this.imageUrl});
}

class BannerItem {
  final String imageUrl;
  final String title;
  final String subtitle;
  const BannerItem({required this.imageUrl, required this.title, required this.subtitle});
}

class Product {
  final String name;
  final String price;
  final String imageUrl;
  const Product({required this.name, required this.price, required this.imageUrl});
}

class _HomeScreenState extends State<HomeScreen> {
  // 0-All, 1-Men, 2-Women, 3-Kids
  int _tabIndex = 0;
  int _bannerPage = 0;
  final PageController _bannerController = PageController();
  final Set<String> _wishlist = {};

  final List<CategoryItem> _categories = const [
    CategoryItem(label: 'All', imageUrl: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=200'),
    CategoryItem(label: 'Men', imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=200'),
    CategoryItem(label: 'Women', imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=200'),
    CategoryItem(label: 'Kids', imageUrl: 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=200'),
  ];

  final Map<int, List<BannerItem>> _bannersByTab = {
    0: const [
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=800', title: 'Flat 50% off', subtitle: 'On your first order'),
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1490578474895-699cd4e2cf59?w=800', title: 'New arrivals', subtitle: 'Fresh styles every week'),
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1490114538077-0a7f8cb49891?w=800', title: 'Try before you buy', subtitle: 'See it on you first'),
    ],
    1: const [
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1593030103066-0093718efeb9?w=800', title: 'Season sale', subtitle: 'Up to 60% off'),
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=800', title: 'Office edit', subtitle: 'Sharp looks, sorted'),
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800', title: 'Weekend casuals', subtitle: 'Comfort meets style'),
    ],
    2: const [
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800', title: 'Festive picks', subtitle: 'Shop the new edit'),
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?w=800', title: 'Everyday essentials', subtitle: 'Buy 2 get 1 free'),
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=800', title: 'Date night ready', subtitle: 'Turn heads tonight'),
    ],
    3: const [
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1503944583220-79d8926ad5e2?w=800', title: 'Playtime favorites', subtitle: 'Built to last'),
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=800', title: 'Back to school', subtitle: 'Everything they need'),
      BannerItem(imageUrl: 'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=800', title: 'Cozy & comfy', subtitle: 'Soft fabrics, happy kids'),
    ],
  };

  final Map<int, List<Product>> _productsByTab = {
    0: const [
      Product(name: 'Classic White Tee', price: '₹599', imageUrl: 'https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=400'),
      Product(name: 'Denim Jacket', price: '₹1,899', imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400'),
      Product(name: 'Running Sneakers', price: '₹2,499', imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=400'),
      Product(name: 'Floral Dress', price: '₹1,299', imageUrl: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=400'),
      Product(name: 'Leather Handbag', price: '₹2,199', imageUrl: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400'),
      Product(name: 'Analog Watch', price: '₹1,599', imageUrl: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=400'),
    ],
    1: const [
      Product(name: 'Formal Shirt', price: '₹899', imageUrl: 'https://images.unsplash.com/photo-1602810316693-3667c854239a?w=400'),
      Product(name: 'Slim Fit Jeans', price: '₹1,499', imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400'),
      Product(name: 'Bomber Jacket', price: '₹2,299', imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400'),
      Product(name: 'Leather Sneakers', price: '₹2,799', imageUrl: 'https://images.unsplash.com/photo-1549298916-b41d501d3772?w=400'),
      Product(name: 'Chrono Watch', price: '₹3,199', imageUrl: 'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=400'),
      Product(name: 'Knit Sweater', price: '₹1,199', imageUrl: 'https://images.unsplash.com/photo-1516257984-b1b4d707412e?w=400'),
    ],
    2: const [
      Product(name: 'Floral Maxi Dress', price: '₹1,599', imageUrl: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=400'),
      Product(name: 'Embroidered Kurti', price: '₹999', imageUrl: 'https://images.unsplash.com/photo-1583391733956-6c78276477e2?w=400'),
      Product(name: 'Block Heels', price: '₹1,399', imageUrl: 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=400'),
      Product(name: 'Quilted Handbag', price: '₹2,099', imageUrl: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=400'),
      Product(name: 'Silk Saree', price: '₹3,499', imageUrl: 'https://images.unsplash.com/photo-1610030469983-98e550d6193c?w=400'),
      Product(name: 'Crop Top', price: '₹699', imageUrl: 'https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=400'),
    ],
    3: const [
      Product(name: 'Cartoon Print Tee', price: '₹399', imageUrl: 'https://images.unsplash.com/photo-1503944583220-79d8926ad5e2?w=400'),
      Product(name: 'Party Frock', price: '₹899', imageUrl: 'https://images.unsplash.com/photo-1522771930-78848d9293e8?w=400'),
      Product(name: 'School Shoes', price: '₹699', imageUrl: 'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=400'),
      Product(name: 'Puffer Jacket', price: '₹1,199', imageUrl: 'https://images.unsplash.com/photo-1576871337622-98d48d1cf531?w=400'),
      Product(name: 'Denim Shorts', price: '₹499', imageUrl: 'https://images.unsplash.com/photo-1542272604-787c3835535d?w=400'),
      Product(name: 'Soft Romper', price: '₹599', imageUrl: 'https://images.unsplash.com/photo-1622290291468-a28f7a7dc6a8?w=400'),
    ],
  };

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildCategorySelector(),
        const SizedBox(height: 16),
        Expanded(child: _buildBody()),
      ],
    );
  }

  // ---------------- HEADER: search bar + notification + profile ----------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(child: _searchBar()),
          const SizedBox(width: 10),
          _iconButton(Icons.notifications_none_rounded, () {
            // TODO: Navigate to notifications screen
          }),
          const SizedBox(width: 10),
          _iconButton(Icons.person_outline_rounded, () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 22),
      ),
    );
  }

  // ---------------- CATEGORY SELECTOR: image cards, horizontal scroll ----------------
  Widget _buildCategorySelector() {
    return SizedBox(
      height: 92,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _tabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => setState(() {
                _tabIndex = index;
                _bannerPage = 0;
              }),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? AppColors.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        cat.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : Container(color: AppColors.card),
                        errorBuilder: (context, error, stack) =>
                            Container(color: AppColors.card, child: const Icon(Icons.image_outlined)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
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

  // ---------------- BODY: banners + trending products ----------------
  Widget _buildBody() {
    final products = _productsByTab[_tabIndex] ?? const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _buildBannerCarousel(),
        const SizedBox(height: 20),
        Text(
          'Trending now',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) => _productCard(products[index], index),
        ),
      ],
    );
  }

  // ---------------- BANNER CAROUSEL: 3 banners per category, swipeable ----------------
  Widget _buildBannerCarousel() {
    final banners = _bannersByTab[_tabIndex] ?? const [];
    if (banners.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (i) => setState(() => _bannerPage = i),
            itemBuilder: (context, index) {
              final b = banners[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      b.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : Container(color: AppColors.card),
                      errorBuilder: (context, error, stack) => Container(color: AppColors.card),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 14,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(b.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(banners.length, (i) {
            final isActive = i == _bannerPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 8 : 6,
              height: isActive ? 8 : 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.accent : AppColors.textSecondary.withOpacity(0.3),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---------------- PRODUCT CARD: image + wishlist heart + name + price ----------------
  Widget _productCard(Product product, int index) {
    final wishKey = '${_tabIndex}_$index';
    final isWishlisted = _wishlist.contains(wishKey);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : Container(color: AppColors.background),
                        errorBuilder: (context, error, stack) => Container(
                          color: AppColors.background,
                          child: Icon(Icons.image_outlined, color: AppColors.textSecondary.withOpacity(0.5), size: 32),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      isWishlisted ? _wishlist.remove(wishKey) : _wishlist.add(wishKey);
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: isWishlisted ? Colors.redAccent : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(product.price, style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}