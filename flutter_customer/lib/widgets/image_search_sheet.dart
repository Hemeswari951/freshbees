import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

/// Shows the "Take Photo" / "Choose from Gallery" sheet (stacked
/// vertically, as required) and returns the picked/captured photo, or
/// null if the person cancelled at any point.
Future<XFile?> showImageSearchSheet(BuildContext context) {
  return showModalBottomSheet<XFile?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _ImageSearchSheet(),
  );
}

class _ImageSearchSheet extends StatefulWidget {
  const _ImageSearchSheet();

  @override
  State<_ImageSearchSheet> createState() => _ImageSearchSheetState();
}

class _ImageSearchSheetState extends State<_ImageSearchSheet> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _showError(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------------
  // TAKE PHOTO — explicitly checks/requests camera permission first so
  // a denial is handled with a clear message instead of a silent no-op.
  // ---------------------------------------------------------------------
  Future<void> _takePhoto() async {
    setState(() => _busy = true);
    try {
      final status = await Permission.camera.status;
      PermissionStatus granted = status;

      if (!status.isGranted) {
        granted = await Permission.camera.request();
      }

      if (!granted.isGranted) {
        if (granted.isPermanentlyDenied) {
          await _showError(
            'Camera access is blocked. Enable it in Settings to take a photo.',
          );
        } else {
          await _showError('Camera permission is needed to take a photo.');
        }
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (!mounted) return;
      Navigator.of(context).pop(image);
    } catch (e) {
      debugPrint('Camera error: $e');
      await _showError('Unable to open camera. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ---------------------------------------------------------------------
  // CHOOSE FROM GALLERY — image_picker uses the system photo picker on
  // modern Android/iOS, which doesn't need an extra runtime-permission
  // prompt from us; it handles that itself.
  // ---------------------------------------------------------------------
  Future<void> _chooseFromGallery() async {
    setState(() => _busy = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (!mounted) return;
      Navigator.of(context).pop(image);
    } catch (e) {
      debugPrint('Gallery error: $e');
      await _showError('Unable to open gallery. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Search with a photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Take a picture or choose one from your gallery to find similar products.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 18),

            // Vertical (top-to-bottom) layout, as required.
            _OptionTile(
              icon: Icons.photo_camera_outlined,
              label: 'Take Photo',
              onTap: _busy ? null : _takePhoto,
            ),
            const SizedBox(height: 10),
            _OptionTile(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: _busy ? null : _chooseFromGallery,
            ),

            if (_busy) ...[
              const SizedBox(height: 16),
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _OptionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2ECE4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: const Color(0xFF3A2E22)),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}
