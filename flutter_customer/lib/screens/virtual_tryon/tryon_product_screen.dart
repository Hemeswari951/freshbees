import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/profile_model.dart';
import '../../models/tryon_profile_model.dart';
import '../../services/tryon_profile_service.dart';



class TryOnProductScreen extends StatefulWidget {
  final XFile? customerPhoto;
  final String? customerPhotoUrl;
  final TryOnProfile? selectedProfile;
final ProfileModel? customerProfile;

  const TryOnProductScreen({
    super.key,
    this.customerPhoto,
    this.customerPhotoUrl,
    this.selectedProfile,
    this.customerProfile,
  });

  @override
  State<TryOnProductScreen> createState() =>
      _TryOnProductScreenState();
}

class _TryOnProductScreenState extends State<TryOnProductScreen> {
  bool _loading = true;
  String? _error;

  List<ProductModel> _products = [];
  ProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await ProductService.getProducts();

      if (!mounted) return;

      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _selectProduct(ProductModel product) {
    setState(() {
      _selectedProduct = product;
    });
  }

  void _continueWithProduct() async {
  debugPrint(
    'PRODUCT SCREEN → selectedProfile: ${widget.selectedProfile}',
  );

  debugPrint(
    'PRODUCT SCREEN → profileId: ${widget.selectedProfile?.profileId}',
  );

  debugPrint(
    'PRODUCT SCREEN → customerProfile: ${widget.customerProfile}',
  );

  if (_selectedProduct == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select an outfit first'),
      ),
    );
    return;
  }

  // ==================================================
  // TRY-ON PROFILE
  // ==================================================
  //
  // At this point both:
  //
  // 1. Main User
  // 2. Additional User
  //
  // should have a TryOnProfile.
  //
  // The only difference is how the profile was obtained.
  // ==================================================

  TryOnProfile? profile = widget.selectedProfile;

  // ==================================================
  // MAIN USER
  // ==================================================
  //
  // Main user's permanent Try-On profile may not have
  // been passed from the previous screen.
  //
  // So load it from backend.
  // ==================================================

  if (profile == null && widget.customerProfile != null) {
    try {
      debugPrint(
        'PRODUCT SCREEN → Loading MAIN TRY-ON PROFILE',
      );

      profile =
          await TryOnProfileService.getMainProfile();

      debugPrint(
        'PRODUCT SCREEN → MAIN PROFILE ID: '
        '${profile.profileId}',
      );

      debugPrint(
        'PRODUCT SCREEN → MAIN PROFILE PHOTO: '
        '${profile.photoUrl}',
      );
    } catch (e) {
      debugPrint(
        'PRODUCT SCREEN → Failed to load main profile: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to load your try-on profile: $e',
          ),
        ),
      );

      return;
    }
  }

  // ==================================================
  // NO PROFILE
  // ==================================================

  if (profile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please select a try-on profile',
        ),
      ),
    );

    return;
  }

  // ==================================================
  // PHOTO VALIDATION
  // ==================================================

  if (profile.photoUrl == null ||
      profile.photoUrl!.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please add a profile photo before trying on',
        ),
      ),
    );

    return;
  }

  // ==================================================
  // NAVIGATE TO REVIEW
  // ==================================================

  debugPrint(
    'PRODUCT SCREEN → REVIEW',
  );

  debugPrint(
    'PROFILE ID: ${profile.profileId}',
  );

  debugPrint(
    'PROFILE NAME: ${profile.profileName}',
  );

  debugPrint(
    'PROFILE PHOTO: ${profile.photoUrl}',
  );

  if (!mounted) return;

  context.push(
    '/virtual-tryon/review',
    extra: {
      // No temporary XFile anymore
      'photo': null,

      // Permanent profile photo
      'photoUrl': profile.photoUrl,

      'product': _selectedProduct!,

      // Both Main User and Additional User
      // are represented by TryOnProfile
      'selectedProfile': profile,

      // No need for ProfileModel here
      'customerProfile': null,
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),

      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black,
          ),
          onPressed: () => context.pop(),
        ),

        centerTitle: true,

        title: const Text(
          'Choose an Outfit',
          
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: _buildBody(),

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedProduct == null
                  ? null
                  : _continueWithProduct,

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                disabledBackgroundColor:
                    Colors.black12,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),

              child: Text(
                _selectedProduct == null
                    ? 'SELECT AN OUTFIT'
                    : 'TRY THIS OUTFIT',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 45,
                color: Colors.grey,
              ),

              const SizedBox(height: 12),

              const Text(
                'Unable to load outfits',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });

                  _loadProducts();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'No products available',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProducts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          90,
        ),
        children: [
          const Text(
            'Choose something you would like to try.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Available Outfits',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 14),

          GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(),

            itemCount: _products.length,

            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.68,
            ),

            itemBuilder: (context, index) {
              final product = _products[index];

              final selected =
                  _selectedProduct?.id == product.id;

              return _productCard(
                product,
                selected,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _productCard(
    ProductModel product,
    bool selected,
  ) {
    return GestureDetector(
      onTap: () => _selectProduct(product),

      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(14),

          border: Border.all(
            color: selected
                ? Colors.black
                : Colors.transparent,
            width: selected ? 2 : 1,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),

                    child: SizedBox(
                      width: double.infinity,
                      child: product.thumbnail
                              .isNotEmpty
                          ? Image.network(
                              product.thumbnail,
                              fit: BoxFit.cover,

                              errorBuilder:
                                  (_, __, ___) {
                                return Container(
                                  color:
                                      AppColors.blush,
                                  child: const Icon(
                                    Icons
                                        .image_not_supported_outlined,
                                    color:
                                        Colors.black38,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.blush,
                              child: const Icon(
                                Icons.checkroom,
                                color:
                                    Colors.black38,
                              ),
                            ),
                    ),
                  ),

                  if (selected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration:
                            const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.all(10),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    product.productName,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    product.shopName,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black45,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    '₹${product.price.toStringAsFixed(0)}',

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}