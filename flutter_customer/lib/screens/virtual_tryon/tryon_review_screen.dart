import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../services/tryon_profile_service.dart';
import '../../models/product_model.dart';

class TryOnReviewScreen extends StatelessWidget {
  final XFile? customerPhoto;
  final String? customerPhotoUrl;
  final ProductModel selectedProduct;
  final TryOnProfile selectedProfile;

  const TryOnReviewScreen({
    super.key,
    this.customerPhoto,
    this.customerPhotoUrl,
    required this.selectedProduct,
    required this.selectedProfile,
  });

 Future<Uint8List> _loadPhoto() async {
  // ============================================================
  // CASE 1: Newly selected photo from device
  // ============================================================

  if (customerPhoto != null) {
    print('REVIEW: Loading newly selected photo');

    return await customerPhoto!.readAsBytes();
  }

  // ============================================================
  // CASE 2: Saved profile photo from backend
  // ============================================================

  if (customerPhotoUrl != null &&
      customerPhotoUrl!.trim().isNotEmpty) {

    String imageUrl = customerPhotoUrl!.trim();

    // Backend returns something like:
    // /uploads/tryon/profile_1_xxx.jpg

    if (!imageUrl.startsWith('http://') &&
        !imageUrl.startsWith('https://')) {
      imageUrl = '${ApiService.serverUrl}$imageUrl';
    }

    print('========================================');
    print('REVIEW: Loading saved profile photo');
    print('REVIEW PHOTO URL: $imageUrl');
    print('========================================');

    final response = await http.get(
      Uri.parse(imageUrl),
    );

    print(
      'REVIEW PHOTO STATUS: ${response.statusCode}',
    );

    if (response.statusCode != 200) {
      print(
        'REVIEW PHOTO ERROR BODY: ${response.body}',
      );

      throw Exception(
        'Failed to load saved profile photo: '
        '${response.statusCode}',
      );
    }

    return response.bodyBytes;
  }

  // ============================================================
  // CASE 3: No photo
  // ============================================================

  print('REVIEW ERROR: No customer photo available');

  throw Exception(
    'No customer photo available',
  );
}

  void _generateTryOn(BuildContext context) {
    // AI integration will be added later by the AI team.
    //
    // For now, show a temporary processing message.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your try-on is ready to be processed.',
        ),
      ),
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
          'Review Your Try-On',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Almost ready!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Review your photo and outfit before trying it on.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              // =========================
              // CUSTOMER PHOTO
              // =========================

              const Text(
                'YOUR PHOTO',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B7355),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DFD1),
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: FutureBuilder<Uint8List>(
  future: _loadPhoto(),
  builder: (context, snapshot) {
    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError) {
      return Center(
        child: Text(
          'Unable to load photo',
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    if (!snapshot.hasData) {
      return const Center(
        child: Text('No photo available'),
      );
    }

    return Image.memory(
      snapshot.data!,
      fit: BoxFit.cover,
    );
  },
),
              ),

              const SizedBox(height: 26),

              // =========================
              // SELECTED PRODUCT
              // =========================

              const Text(
                'SELECTED OUTFIT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8B7355),
                ),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.black12,
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(12),
                      child: SizedBox(
                        width: 105,
                        height: 130,
                        child: selectedProduct
                                .thumbnail.isNotEmpty
                            ? Image.network(
                                selectedProduct.thumbnail,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) {
                                  return Container(
                                    color:
                                        const Color(
                                      0xFFE8DFD1,
                                    ),
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
                                color:
                                    const Color(
                                  0xFFE8DFD1,
                                ),
                                child: const Icon(
                                  Icons.checkroom,
                                  color:
                                      Colors.black38,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(width: 14),

                    // Product details
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedProduct.productName,
                            maxLines: 2,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            selectedProduct.shopName,
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            '₹${selectedProduct.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  const Color(
                                0xFFF4EFE8,
                              ),
                              borderRadius:
                                  BorderRadius
                                      .circular(8),
                            ),
                            child: const Text(
                              'Selected for Try-On',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Information message
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4EFE8),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: Color(0xFF8B7355),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your photo and selected outfit '
                        'will be used to create your virtual '
                        'try-on.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // =========================
      // GENERATE BUTTON
      // =========================

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
                color:
                    Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () =>
                  _generateTryOn(context),

              icon: const Icon(
                Icons.auto_awesome,
                size: 18,
              ),

              label: const Text(
                'GENERATE TRY-ON',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}