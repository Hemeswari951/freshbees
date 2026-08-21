import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../../widgets/t_colors.dart';
import '../../widgets/virtual_tryon_header.dart';
import '../../services/tryon_profile_service.dart';
import '../../services/api_service.dart';

class VirtualTryOnScreen extends StatefulWidget {
  final TryOnProfile? selectedProfile;

  const VirtualTryOnScreen({
    super.key,
    this.selectedProfile,
  });

  @override
  State<VirtualTryOnScreen> createState() =>
      _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  final ImagePicker _picker = ImagePicker();
  // XFile works across Android, iOS, Web and desktop.
  XFile? _selectedImage;
  String? _savedPhotoUrl;
  bool _savingPhoto = false;
  
 

@override
void initState() {
  super.initState();

  debugPrint(
    'TRY-ON PROFILE: ${widget.selectedProfile?.profileName}',
  );

  debugPrint(
    'TRY-ON PROFILE ID: ${widget.selectedProfile?.profileId}',
  );

  debugPrint(
    'TRY-ON PHOTO URL: ${widget.selectedProfile?.photoUrl}',
  );

  _savedPhotoUrl = widget.selectedProfile?.photoUrl;
}

  

  // ============================================================
  // TAKE PHOTO
  // ============================================================

  Future<void> _takePhoto() async {
  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = image;
    });
  } catch (e) {
    debugPrint('Camera error: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open camera'),
      ),
    );
  }
}
  // ============================================================
  // UPLOAD PHOTO
  // ============================================================

  Future<void> _uploadPhoto() async {
  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() {
      _selectedImage = image;
    });
  } catch (e) {
    debugPrint('Gallery error: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to open gallery'),
      ),
    );
  }
}
  // ============================================================
  // CONTINUE
  // ============================================================

  Future<void> _continue() async {
  // ---------------------------------------------------------
  // No new image AND no saved image
  // ---------------------------------------------------------

  if (_selectedImage == null &&
      (_savedPhotoUrl == null ||
          _savedPhotoUrl!.isEmpty)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please add your photo first',
        ),
      ),
    );

    return;
  }

  // ---------------------------------------------------------
  // If user selected a NEW image, upload it first
  // ---------------------------------------------------------

  if (_selectedImage != null) {
    if (widget.selectedProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a try-on profile first',
          ),
        ),
      );

      return;
    }

    setState(() {
      _savingPhoto = true;
    });

    try {
      final image = _selectedImage!;

      final bytes = await image.readAsBytes();

      debugPrint(
        'UPLOADING PHOTO FOR PROFILE: '
        '${widget.selectedProfile!.profileId}',
      );

      final updatedProfile =
          await TryOnProfileService.uploadProfilePhoto(
        profileId:
            widget.selectedProfile!.profileId,
        filePath: image.name,
        bytes: bytes,
      );

      debugPrint(
        'PHOTO SAVED SUCCESSFULLY',
      );

      debugPrint(
        'SAVED PHOTO URL: '
        '${updatedProfile.photoUrl}',
      );

      if (!mounted) return;

// Keep the selected XFile because the next screen
// currently expects an XFile.
//final XFile uploadedPhoto = image;

setState(() {
  _savedPhotoUrl = updatedProfile.photoUrl;
  _savingPhoto = false;
});

context.push(
  '/virtual-tryon/products',
  extra: {
    'photo': null,
    'photoUrl': _savedPhotoUrl,
    'profile': widget.selectedProfile,
  },
);

return;
    } catch (e) {
      debugPrint(
        'PROFILE PHOTO UPLOAD ERROR: $e',
      );

      if (!mounted) return;

      setState(() {
        _savingPhoto = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save photo: $e',
          ),
        ),
      );

      return;
    }
  }

  // ---------------------------------------------------------
  // Existing saved photo
  // ---------------------------------------------------------

 context.push(
  '/virtual-tryon/products',
  extra: {
    'photo': null,
    'photoUrl': _savedPhotoUrl,
    'profile': widget.selectedProfile,
  },
);
}

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TColors.cream,

      
      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Column(
      children: [
         VirtualTryOnHeader(
          title: 'Virtual Try-On',
          onBack: () {
    context.go('/virtual-tryon/select-profile');
  },
        ),

        Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            10,
            20,
            30,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Try Before You Buy',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'See how an outfit looks on you before you buy it.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // PHOTO AREA
              // ==================================================

              Container(
                width: double.infinity,
                height: 360,
                decoration: BoxDecoration(
                  color: TColors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: TColors.border,
                  ),
                ),
                child: _selectedImage != null
    ? _selectedPhoto()
    : _savedPhotoUrl != null &&
            _savedPhotoUrl!.isNotEmpty
        ? _savedPhoto()
        : _emptyPhotoState(),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // INSTRUCTIONS
              // ==================================================

              const Text(
                'For the best result',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Use a clear front-facing photo with good lighting. '
                'Try to keep your full outfit visible.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // PHOTO BUTTONS
              // ==================================================

              Row(
                children: [

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _takePhoto,
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                      ),
                      label: const Text('Take Photo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(
                          color: Colors.black,
                        ),
                        minimumSize: const Size(
                          double.infinity,
                          52,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _uploadPhoto,
                      icon: const Icon(
                        Icons.photo_library_outlined,
                      ),
                      label: const Text('Upload'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(
                          color: Colors.black,
                        ),
                        minimumSize: const Size(
                          double.infinity,
                          52,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ==================================================
              // CONTINUE
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed:  _savingPhoto
    ? null
    : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  child: _savingPhoto
    ? const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      )
    
                  : const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY PHOTO STATE
  // ============================================================

  Widget _emptyPhotoState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [

        Icon(
          Icons.person_outline,
          size: 70,
          color: Colors.black38,
        ),

        SizedBox(height: 16),

        Text(
          'Add your photo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 6),

        Text(
          'Take a photo or choose one from your gallery',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

//save photo widget

  Widget _savedPhoto() {
  final fullPhotoUrl =
      ApiService.imageUrl(_savedPhotoUrl);

  debugPrint(
    'SAVED PHOTO URL FROM DB: $_savedPhotoUrl',
  );

  debugPrint(
    'SAVED PHOTO FULL URL: $fullPhotoUrl',
  );

  return ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          fullPhotoUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,

          loadingBuilder: (
            context,
            child,
            loadingProgress,
          ) {
            if (loadingProgress == null) {
              return child;
            }

            return const Center(
              child: CircularProgressIndicator(),
            );
          },

          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            debugPrint(
              'SAVED PHOTO LOAD ERROR: $error',
            );

            debugPrint(
              'FAILED IMAGE URL: $fullPhotoUrl',
            );

            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    size: 55,
                    color: Colors.black38,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Unable to load saved photo',
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Text(
              'Saved Photo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  // ============================================================
  // SELECTED PHOTO
  // ============================================================

  Widget _selectedPhoto() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<Uint8List>(
          future: _selectedImage!.readAsBytes(),
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // Error
            if (snapshot.hasError) {
              debugPrint(
                'Image preview error: ${snapshot.error}',
              );

              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 55,
                      color: Colors.black38,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Unable to preview image',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              );
            }

            // No image
            if (!snapshot.hasData) {
              return const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 55,
                  color: Colors.black38,
                ),
              );
            }

            // Actual image
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            );
          },
        ),

        // Close / change photo button
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                });
              },
              icon: const Icon(
                Icons.close,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}



}