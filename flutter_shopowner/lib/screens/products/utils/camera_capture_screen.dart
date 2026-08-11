import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../widgets/app_colors.dart';

/// Custom in-app live camera screen used for both:
///  - single-shot capture (one angle photo — front/back/side/zoom): first
///    tap of the shutter immediately pops back with that one photo.
///  - burst capture (360° spin photos): shots accumulate in a bottom
///    strip while the sheet stays open, so the owner can walk around the
///    product and keep tapping; "Done" pops back with the full ordered
///    list.
///
/// Pops with `List<XFile>?` — null/empty means the owner backed out
/// without keeping anything.
class CameraCaptureScreen extends StatefulWidget {
  final bool burstMode;

  const CameraCaptureScreen({super.key, this.burstMode = false});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _initializing = true;
  String? _error;
  bool _capturing = false;
  final List<XFile> _burstShots = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setup();
  }

  Future<void> _setup() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No camera found on this device.';
          _initializing = false;
        });
        return;
      }
      // Prefer the back camera — most product photography uses the rear
      // lens. Falls back to whatever's first (e.g. laptop webcams only
      // report one "camera").
      final backIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      _cameraIndex = backIndex == -1 ? 0 : backIndex;
      await _startController(_cameras[_cameraIndex]);
    } catch (e) {
      setState(() {
        _error = 'Could not access camera: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _startController(CameraDescription description) async {
    final previous = _controller;
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller = controller;
    try {
      await controller.initialize();
      try {
        await controller.setFlashMode(_flashMode);
      } catch (_) {
        // Not every camera (e.g. front lens, laptop webcam) supports
        // flash/torch — that's fine, just skip it.
      }
      if (!mounted) return;
      setState(() => _initializing = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not start camera: $e';
        _initializing = false;
      });
    } finally {
      await previous?.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _startController(controller.description);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _initializing = true);
    await _startController(_cameras[_cameraIndex]);
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null) return;
    final next = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    try {
      await controller.setFlashMode(next);
      setState(() => _flashMode = next);
    } catch (_) {
      // Unsupported on this camera — ignore silently, button just won't
      // visibly change anything.
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (!mounted) return;
      if (widget.burstMode) {
        setState(() {
          _burstShots.add(file);
          _capturing = false;
        });
      } else {
        Navigator.of(context).pop<List<XFile>>([file]);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _capturing = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  void _removeShot(int index) => setState(() => _burstShots.removeAt(index));

  void _finishBurst() => Navigator.of(context).pop<List<XFile>>(_burstShots);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _error != null
            ? _errorView()
            : _initializing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _cameraView(),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off, color: Colors.white70, size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop<List<XFile>>(null),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraView() {
    final controller = _controller!;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: CameraPreview(controller)),

        // Top bar: close + flash + switch camera.
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circleIconButton(
                Icons.close,
                onTap: () => Navigator.of(
                  context,
                ).pop<List<XFile>>(widget.burstMode ? _burstShots : null),
              ),
              Row(
                children: [
                  _circleIconButton(
                    _flashMode == FlashMode.off
                        ? Icons.flash_off
                        : Icons.flash_on,
                    onTap: _toggleFlash,
                  ),
                  const SizedBox(width: 8),
                  if (_cameras.length > 1)
                    _circleIconButton(
                      Icons.cameraswitch,
                      onTap: _switchCamera,
                    ),
                ],
              ),
            ],
          ),
        ),

        // Burst mode: thumbnail strip of shots taken so far.
        if (widget.burstMode && _burstShots.isNotEmpty)
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _burstShots.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) => _burstThumb(i),
              ),
            ),
          ),

        // Bottom bar: shutter button (+ Done button in burst mode).
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.burstMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    '${_burstShots.length} photo${_burstShots.length == 1 ? '' : 's'} '
                    'taken — move around the product and keep tapping the shutter.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _capturing ? null : _capture,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _capturing ? Colors.white38 : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (widget.burstMode && _burstShots.isNotEmpty) ...[
                    const SizedBox(width: 24),
                    ElevatedButton(
                      onPressed: _finishBurst,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _burstThumb(int i) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 52,
            height: 64,
            child: FutureBuilder<Uint8List>(
              future: _burstShots[i].readAsBytes(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return Container(color: Colors.white24);
                }
                return Image.memory(snap.data!, fit: BoxFit.cover);
              },
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => _removeShot(i),
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 11, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}