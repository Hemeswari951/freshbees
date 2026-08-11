import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'image_enhancer.dart';
import '../../../widgets/app_colors.dart';

/// Manual photo editor — opened via the pencil icon on an already-added
/// photo. Brightness/contrast/saturation are live-previewed with a cheap
/// `ColorFilter.matrix` (instant while dragging); rotate and the real
/// pixel-level adjustment only run once, on Save, via [ImageEnhancer].
///
/// Bytes in, [XFile] out — works the same on mobile and web.
class PhotoEditScreen extends StatefulWidget {
  final Uint8List initialBytes;
  final String fileName;

  const PhotoEditScreen({
    super.key,
    required this.initialBytes,
    required this.fileName,
  });

  @override
  State<PhotoEditScreen> createState() => _PhotoEditScreenState();
}

class _PhotoEditScreenState extends State<PhotoEditScreen> {
  double _brightness = 1.0; // 1.0 = unchanged
  double _contrast = 1.0;
  double _saturation = 1.0;
  int _rotation = 0; // degrees, steps of 90
  bool _saving = false;

  void _rotate() => setState(() => _rotation = (_rotation + 90) % 360);

  void _reset() => setState(() {
    _brightness = 1.0;
    _contrast = 1.0;
    _saturation = 1.0;
    _rotation = 0;
  });

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final adjusted = await ImageEnhancer.applyManualAdjustments(
        bytes: widget.initialBytes,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        rotateDegrees: _rotation,
      );
      if (!mounted) return;
      final file = XFile.fromData(
        adjusted,
        name: widget.fileName,
        mimeType: 'image/jpeg',
      );
      Navigator.of(context).pop<XFile>(file);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.ink),
        title: const Text(
          'Edit photo',
          style: TextStyle(
            fontFamily: 'Fraunces',
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _reset,
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.inkSoft),
            ),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              _saving ? 'Saving...' : 'Save',
              style: const TextStyle(
                color: AppColors.terracotta,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    _previewMatrix(_brightness, _contrast, _saturation),
                  ),
                  child: AnimatedRotation(
                    turns: _rotation / 360,
                    duration: const Duration(milliseconds: 200),
                    child: Image.memory(
                      widget.initialBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _slider(
                  'Brightness',
                  _brightness,
                  0.5,
                  1.5,
                  (v) => setState(() => _brightness = v),
                ),
                _slider(
                  'Contrast',
                  _contrast,
                  0.5,
                  1.5,
                  (v) => setState(() => _contrast = v),
                ),
                _slider(
                  'Saturation',
                  _saturation,
                  0.0,
                  2.0,
                  (v) => setState(() => _saturation = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _rotate,
              icon: const Icon(Icons.rotate_90_degrees_cw, size: 18),
              label: const Text('Rotate 90°'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ink,
                side: const BorderSide(color: AppColors.line),
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppColors.terracotta,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Cheap approximation of brightness/contrast/saturation as a 4x5 color
  // matrix, purely for an instant live preview while dragging sliders.
  // The real, saved output is computed pixel-by-pixel via the `image`
  // package on Save (see ImageEnhancer.applyManualAdjustments).
  List<double> _previewMatrix(
    double brightness,
    double contrast,
    double saturation,
  ) {
    final b = (brightness - 1.0) * 255;
    final c = contrast;
    final s = saturation;
    const lumR = 0.3086, lumG = 0.6094, lumB = 0.0820;
    final sr = (1 - s) * lumR;
    final sg = (1 - s) * lumG;
    final sb = (1 - s) * lumB;
    return [
      c * (sr + s), c * sg, c * sb, 0, b,
      c * sr, c * (sg + s), c * sb, 0, b,
      c * sr, c * sg, c * (sb + s), 0, b,
      0, 0, 0, 1, 0,
    ];
  }
}