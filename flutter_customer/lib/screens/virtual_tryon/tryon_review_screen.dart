import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/product_model.dart';
import '../../models/profile_model.dart';
import '../../services/api_service.dart';
import '../../services/tryon_generation_service.dart';
import '../../models/tryon_profile_model.dart';

class TryOnReviewScreen extends StatefulWidget {
  final XFile? customerPhoto;
  final String? customerPhotoUrl;
  final ProductModel selectedProduct;

  // Try-On profile used for this virtual try-on
  final TryOnProfile? selectedProfile;
  final ProfileModel? customerProfile;

  const TryOnReviewScreen({
    super.key,
    this.customerPhoto,
    this.customerPhotoUrl,
    required this.selectedProduct,
    this.selectedProfile,
    this.customerProfile,
  });

  @override
  State<TryOnReviewScreen> createState() =>
      _TryOnReviewScreenState();
}

class _TryOnReviewScreenState extends State<TryOnReviewScreen> {
  late final Future<Uint8List> _customerPhotoFuture;
  bool _generating = false;
  String? _generatedImageUrl;
  String? _generationError;

  @override
  void initState() {
    super.initState();

     debugPrint(
    'REVIEW SCREEN → selectedProfile: ${widget.selectedProfile}',
  );

  debugPrint(
    'REVIEW SCREEN → profileId: ${widget.selectedProfile?.profileId}',
  );

  debugPrint(
    'REVIEW SCREEN → customerProfile: ${widget.customerProfile}',
  );

  debugPrint(
    'REVIEW SCREEN → customerPhoto: ${widget.customerPhoto}',
  );

  debugPrint(
    'REVIEW SCREEN → customerPhotoUrl: ${widget.customerPhotoUrl}',
  );


    _customerPhotoFuture = _loadPhoto();
  }

  Future<Uint8List> _loadPhoto() async {
  // 1. Newly selected/uploaded photo
  if (widget.customerPhoto != null) {
    return widget.customerPhoto!.readAsBytes();
  }

  // 2. Saved photo
  final photoUrl = (
  widget.customerPhotoUrl ??
  widget.selectedProfile?.photoUrl
)?.trim();

  if (photoUrl == null || photoUrl.isEmpty) {
    throw Exception('No customer photo available');
  }

  final fullPhotoUrl = ApiService.imageUrl(photoUrl);

  final response = await http.get(
    Uri.parse(fullPhotoUrl),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to load saved profile photo',
    );
  }

  return response.bodyBytes;
}

 Future<void> _generateTryOn() async {
  setState(() {
    _generating = true;
    _generationError = null;
  });

  try {
    final profileId =
        widget.selectedProfile?.profileId;

    final customerPhoto =
        widget.customerPhoto;

    final productId =
        widget.selectedProduct.id;

    final productImageUrl =
        widget.selectedProduct.thumbnail;

    // -----------------------------------------------
    // DEBUG
    // -----------------------------------------------

    debugPrint(
      '========== TRY-ON GENERATION =========='
    );

    debugPrint(
      'REVIEW → profileId: $profileId',
    );

    debugPrint(
      'REVIEW → customerPhoto: $customerPhoto',
    );

    debugPrint(
      'REVIEW → customerPhotoUrl: ${widget.customerPhotoUrl}',
    );

    debugPrint(
      'REVIEW → productId: $productId',
    );

    debugPrint(
      'REVIEW → productImageUrl: $productImageUrl',
    );

    debugPrint(
      '========================================'
    );

    // -----------------------------------------------
// VALIDATION
// -----------------------------------------------

// Try-On Profile
final profile = widget.selectedProfile;

if (profile == null) {
  throw Exception(
    'Try-on profile not selected',
  );
}

if (profile.photoUrl == null ||
    profile.photoUrl!.trim().isEmpty) {
  throw Exception(
    'Selected profile does not have a photo',
  );
}

// Product image
if (productImageUrl.isEmpty) {
  throw Exception(
    'Selected product does not have an image',
  );
}

    // -----------------------------------------------
    // GENERATE
    // -----------------------------------------------

    final generatedUrl =
    await TryOnGenerationService.generateTryOn(
  profileId: widget.selectedProfile?.profileId,
  customerPhoto: widget.customerPhoto,
  productId: widget.selectedProduct.id,
  productImageUrl: widget.selectedProduct.thumbnail,
);

    if (!mounted) return;

    setState(() {
      _generatedImageUrl = generatedUrl;
      _generating = false;
    });

  } catch (e) {
    if (!mounted) return;

    final message =
        e.toString().replaceFirst(
          'Exception: ',
          '',
        );

    debugPrint(
      'TRY-ON GENERATION ERROR: $message',
    );

    setState(() {
      _generationError = message;
      _generating = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Almost ready!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'Review your photo and outfit before trying it on.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              if (_generatedImageUrl != null) ...[
                _sectionLabel('AI TRY-ON RESULT'),
                const SizedBox(height: 10),
                _generatedResult(),
                const SizedBox(height: 26),
              ],
              _sectionLabel('YOUR PHOTO'),
              const SizedBox(height: 10),
              _customerPhoto(),
              const SizedBox(height: 26),
              _sectionLabel('SELECTED OUTFIT'),
              const SizedBox(height: 10),
              _selectedProductCard(),
              const SizedBox(height: 24),
              _infoMessage(),
              if (_generationError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _generationError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _generating ? null : _generateTryOn,
                  icon: _generating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    _generating
                        ? 'GENERATING...'
                        : (_generatedImageUrl == null
                              ? 'GENERATE TRY-ON'
                              : 'GENERATE AGAIN'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.black54,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.pushReplacement(
                      '/virtual-tryon/select-profile',
                      extra: {'product': widget.selectedProduct},
                    );
                  },
                  icon: const Icon(Icons.person_outline, size: 16),
                  label: const Text(
                    'USE DIFFERENT PROFILE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: Color(0xFF8B7355),
      ),
    );
  }

  Widget _customerPhoto() {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFE8DFD1),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Uint8List>(
        future: _customerPhotoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load photo',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No photo available'));
          }

          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        },
      ),
    );
  }

  Widget _generatedResult() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: Image.network(
          _generatedImageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (_, __, ___) {
            return Container(
              color: const Color(0xFFE8DFD1),
              alignment: Alignment.center,
              child: const Text(
                'Unable to load generated try-on',
                style: TextStyle(color: Colors.black54),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _selectedProductCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 105,
              height: 130,
              child: widget.selectedProduct.thumbnail.isNotEmpty
                  ? Image.network(
                      widget.selectedProduct.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _productImageFallback(),
                    )
                  : _productImageFallback(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedProduct.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.selectedProduct.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: Colors.black45),
                ),
                const SizedBox(height: 14),
                Text(
                  '₹${widget.selectedProduct.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4EFE8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Selected for Try-On',
                    style: TextStyle(fontSize: 10, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImageFallback() {
    return Container(
      color: const Color(0xFFE8DFD1),
      child: const Icon(Icons.checkroom, color: Colors.black38),
    );
  }

  Widget _infoMessage() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: 20, color: Color(0xFF8B7355)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'The selected product from this page will be applied to your saved profile photo.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}