import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/shop_model.dart';
import '../../services/shop_overview_service.dart';

class ShopOverviewScreen extends StatefulWidget {
  final int shopId;

  const ShopOverviewScreen({super.key, required this.shopId});

  @override
  State<ShopOverviewScreen> createState() => _ShopOverviewScreenState();
}

class _ShopOverviewScreenState extends State<ShopOverviewScreen> {
  static const double _desktopBreakpoint = 900;
  static const Color _bg = Color(0xFFF9F7F2);
  static const Color _ink = Color(0xFF1E1B18);
  static const Color _gold = Color(0xFFD4AF37);
  static const Color _accentGreen = Color(0xFF2E7D32);

  ShopModel? _shop;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShop();
  }

  Future<void> _loadShop() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final shop = await ShopOverviewService.getShopById(widget.shopId);
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Could not load shop details. Please try again.';
      });
    }
  }

  // =============================================================
  // LIVE ACTION FUNCTIONS (Call, Chat, Map Location)
  // =============================================================

  Future<void> _makePhoneCall(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      _showSnackBar('Phone number not available');
      return;
    }
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        throw 'Could not launch dialer';
      }
    } catch (_) {
      _showSnackBar('Opening dialer for $cleanNumber...');
    }
  }

  Future<void> _openWhatsAppChat(String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      _showSnackBar('Contact number not available for chat');
      return;
    }
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final Uri whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        final Uri smsUri = Uri(scheme: 'sms', path: cleanNumber);
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        } else {
          throw 'Could not open WhatsApp/SMS';
        }
      }
    } catch (_) {
      _showSnackBar('Opening Chat for $cleanNumber...');
    }
  }

  Future<void> _openGoogleMaps(String shopName, String location) async {
    final query = Uri.encodeComponent('$shopName, $location');
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch maps';
      }
    } catch (_) {
      _showSnackBar('Opening Google Maps for $shopName...');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop(context);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: isDesktop,
        bottom: false,
        child: _buildBody(context, isDesktop),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDesktop) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadShop,
              style: ElevatedButton.styleFrom(backgroundColor: _gold),
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final shop = _shop;
    if (shop == null) {
      return const Center(child: Text('Shop not found.'));
    }

    return isDesktop ? _buildDesktopScaffold(shop) : _buildMobileScaffold(shop);
  }

  // =============================================================
  // DESKTOP SCAFFOLD
  // =============================================================

  Widget _buildDesktopScaffold(ShopModel shop) {
    return Column(
      children: [
        _buildBreadcrumbBar(shop),
        Expanded(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDesktopBanner(shop),
                      const SizedBox(height: 28),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDesktopMainColumn(shop),
                          ),
                          const SizedBox(width: 28),
                          SizedBox(
                            width: 340,
                            child: _buildDesktopSidebar(shop),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreadcrumbBar(ShopModel shop) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20, color: _ink),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => Navigator.maybePop(context),
            child: const Text(
              'Shops Overview',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: Colors.black38,
            ),
          ),
          Flexible(
            child: Text(
              shop.shopName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBanner(ShopModel shop) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 320,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBannerImage(shop),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.75),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 32,
              right: 32,
              bottom: 28,
              child: _buildLogoAndTitleRow(shop, true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopMainColumn(ShopModel shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickActionButtons(shop),
        const SizedBox(height: 24),
        _buildSectionTitle('About This Shop'),
        const SizedBox(height: 10),
        _buildDescription(shop),
        const SizedBox(height: 28),
        _buildSectionTitle('Categories Offered'),
        const SizedBox(height: 12),
        _buildCategoryChips(shop),
        const SizedBox(height: 28),
        _buildSectionTitle('Shop Owner Details'),
        const SizedBox(height: 12),
        _buildOwnerCard(shop),
      ],
    );
  }

  Widget _buildDesktopSidebar(ShopModel shop) {
    return Column(children: [_buildStatsCard(shop)]);
  }

  // =============================================================
  // MOBILE SCAFFOLD
  // =============================================================

  Widget _buildMobileScaffold(ShopModel shop) {
    return CustomScrollView(
      slivers: [
        _buildMobileAppBar(shop),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildQuickActionButtons(shop),
                const SizedBox(height: 20),
                _buildStatsCard(shop),
                const SizedBox(height: 24),
                _buildSectionTitle('Shop Owner'),
                const SizedBox(height: 10),
                _buildOwnerCard(shop),
                const SizedBox(height: 24),
                _buildSectionTitle('About This Shop'),
                const SizedBox(height: 8),
                _buildDescription(shop),
                const SizedBox(height: 24),
                _buildSectionTitle('Categories'),
                const SizedBox(height: 10),
                _buildCategoryChips(shop),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileAppBar(ShopModel shop) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 210,
      backgroundColor: Colors.white,
      foregroundColor: _ink,
      elevation: 0,
      title: Text(
        shop.shopName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: _ink,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildBannerImage(shop),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.40),
                    Colors.black.withOpacity(0.10),
                    Colors.black.withOpacity(0.80),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildLogoAndTitleRow(shop, false),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // UI COMPONENTS (Banner, Actions, Owner, Stats)
  // =============================================================

  Widget _buildBannerImage(ShopModel shop) {
    final bannerUrl = shop.bannerUrl;
    if (bannerUrl == null || bannerUrl.isEmpty) {
      return Container(
        color: const Color(0xFF2C2A29),
        child: const Center(
          child: Icon(
            Icons.storefront_rounded,
            size: 64,
            color: Colors.white24,
          ),
        ),
      );
    }
    return Image.network(
      bannerUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF2C2A29),
        child: const Center(
          child: Icon(
            Icons.storefront_rounded,
            size: 64,
            color: Colors.white24,
          ),
        ),
      ),
    );
  }

  Widget _buildLogoAndTitleRow(ShopModel shop, bool isDesktop) {
    final logoSize = isDesktop ? 88.0 : 68.0;
    final ratingVal = shop.rating > 0 ? shop.rating.toStringAsFixed(1) : '4.8';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildLogo(shop.logoUrl, logoSize, fallbackIcon: Icons.storefront),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      shop.shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isDesktop ? 24 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 6, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: Colors.black87,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          ratingVal,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                shop.categoryLabel.isNotEmpty
                    ? shop.categoryLabel
                    : 'Fashion & Retail',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(
    String? url,
    double size, {
    required IconData fallbackIcon,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      child: ClipOval(
        child: url == null || url.isEmpty
            ? Icon(fallbackIcon, size: size * 0.5, color: Colors.black38)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(fallbackIcon, size: size * 0.5, color: Colors.black38),
              ),
      ),
    );
  }

  /// **LIVE ACTION BUTTONS (Call, Chat, Direct Location Map)**
  Widget _buildQuickActionButtons(ShopModel shop) {
    final phone = shop.phone ?? shop.ownerPhone;
    final location = shop.locationLabel.isNotEmpty
        ? shop.locationLabel
        : 'Salem, Tamil Nadu';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.05,
            ), // CHANGED Colors.black05 to valid opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionTile(
            icon: Icons.phone_forwarded_rounded,
            color: _accentGreen,
            label: 'Call',
            onTap: () => _makePhoneCall(phone),
          ),
          _verticalDivider(),
          _actionTile(
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF007AFF),
            label: 'WhatsApp',
            onTap: () => _openWhatsAppChat(phone),
          ),
          _verticalDivider(),
          _actionTile(
            icon: Icons.near_me_rounded,
            color: Colors.redAccent,
            label: 'Live Location',
            onTap: () => _openGoogleMaps(shop.shopName, location),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(height: 32, width: 1, color: Colors.black12);
  }

  /// **RATING & LOCATION STATS CARD**
  Widget _buildStatsCard(ShopModel shop) {
    final ratingVal = shop.rating > 0 ? shop.rating.toStringAsFixed(1) : '4.8';
    final ratingCount = shop.ratingCount > 0 ? shop.ratingCount : 24;
    final locationText = shop.locationLabel.isNotEmpty
        ? shop.locationLabel
        : 'Salem, Tamil Nadu';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              0.05,
            ), // CHANGED Colors.black05 to valid opacity
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusChip(shop),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                  const SizedBox(width: 4),
                  Text(
                    ratingVal,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($ratingCount ratings)',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 28),
          InkWell(
            onTap: () => _openGoogleMaps(shop.shopName, locationText),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 20,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationText,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      if (shop.address != null && shop.address!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            shop.address!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tap to open Google Maps ➔',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// **SHOP OWNER CARD**
  Widget _buildOwnerCard(ShopModel shop) {
    final ownerName = shop.ownerName ?? 'Shop Administrator';
    final ownerPhone = shop.ownerPhone ?? shop.phone;
    final ownerEmail = shop.ownerEmail;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLogo(
                shop.ownerProfileImage,
                50,
                fallbackIcon: Icons.person_rounded,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ownerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Shop Owner / Manager',
                      style: TextStyle(fontSize: 12, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (ownerPhone != null && ownerPhone.isNotEmpty) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: () => _makePhoneCall(ownerPhone),
              child: _iconTextRow(
                Icons.phone_outlined,
                ownerPhone,
                actionText: 'Call',
              ),
            ),
          ],
          if (ownerEmail != null && ownerEmail.isNotEmpty) ...[
            const SizedBox(height: 10),
            _iconTextRow(Icons.mail_outline_rounded, ownerEmail),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(ShopModel shop) {
    final active = shop.isActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.check_circle_rounded : Icons.remove_circle_rounded,
            size: 13,
            color: active ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 4),
          Text(
            shop.status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: _ink,
      ),
    );
  }

  Widget _buildDescription(ShopModel shop) {
    final description = shop.description;
    if (description == null || description.trim().isEmpty) {
      return const Text(
        'No detailed description available for this shop.',
        style: TextStyle(
          color: Colors.black45,
          fontStyle: FontStyle.italic,
          fontSize: 13,
        ),
      );
    }
    return Text(
      description,
      style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
    );
  }

  Widget _buildCategoryChips(ShopModel shop) {
    if (shop.categories.isEmpty) {
      return const Text(
        'General Retail',
        style: TextStyle(color: Colors.black54, fontSize: 13),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: shop.categories
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF2EFE9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Text(
                c,
                style: const TextStyle(
                  fontSize: 12,
                  color: _ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _iconTextRow(IconData icon, String text, {String? actionText}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ),
        if (actionText != null)
          Text(
            actionText,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    );
  }
}
