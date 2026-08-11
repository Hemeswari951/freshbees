import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Runs pixel processing off the UI thread via `compute()`.
///
/// Deliberately bytes-in / bytes-out everywhere (no `dart:io File`) so the
/// exact same code path works on mobile AND Flutter web — a temp-file
/// based approach would break on web, where there's no filesystem.
class ImageEnhancer {
  static const int _maxDimension = 1600;
  static const int _jpegQuality = 85;

  /// Silent auto-enhance applied right after every camera/gallery pick:
  /// bakes in EXIF rotation, downsizes to a sane max dimension, auto
  /// levels (contrast stretch), a small brightness/contrast/saturation
  /// lift, then re-encodes as JPEG — so every uploaded product photo ends
  /// up a consistent size/quality regardless of the source device.
  static Future<XFile> enhance(XFile source) async {
    final bytes = await source.readAsBytes();
    final enhancedBytes = await compute(_autoEnhance, bytes);
    return XFile.fromData(
      enhancedBytes,
      name: source.name,
      mimeType: 'image/jpeg',
    );
  }

  /// Manual adjustment pass used by the photo editor — brightness/
  /// contrast/saturation are user-controlled multipliers (1.0 = no
  /// change), optional 90°-step rotation.
  static Future<Uint8List> applyManualAdjustments({
    required Uint8List bytes,
    double brightness = 1.0,
    double contrast = 1.0,
    double saturation = 1.0,
    int rotateDegrees = 0,
  }) {
    return compute(_manualAdjust, {
      'bytes': bytes,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'rotate': rotateDegrees,
    });
  }

  // ── Isolate-side work below. Must be top-level or static, and every
  // argument/return value must be a simple, transferable type. ──

  static Uint8List _autoEnhance(Uint8List bytes) {
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    // Camera photos often carry an EXIF rotation flag instead of being
    // physically rotated — bake it in so the pixels themselves are
    // upright before anything else touches them.
    decoded = img.bakeOrientation(decoded);

    if (decoded.width > _maxDimension || decoded.height > _maxDimension) {
      final landscape = decoded.width >= decoded.height;
      decoded = img.copyResize(
        decoded,
        width: landscape ? _maxDimension : null,
        height: !landscape ? _maxDimension : null,
      );
    }

    // Auto levels: stretches the histogram so the darkest pixel becomes
    // black and the lightest becomes white — fixes the flat, slightly
    // grey look most phone cameras produce indoors.
    decoded = img.normalize(decoded, min: 0, max: 255);

    // Small, deliberately subtle lift — should read as "a good camera
    // took this", not "this has a filter on it".
    decoded = img.adjustColor(
      decoded,
      brightness: 1.03,
      contrast: 1.06,
      saturation: 1.08,
    );

    return Uint8List.fromList(img.encodeJpg(decoded, quality: _jpegQuality));
  }

  static Uint8List _manualAdjust(Map<String, dynamic> args) {
    final bytes = args['bytes'] as Uint8List;
    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    final rotate = args['rotate'] as int;
    if (rotate != 0) {
      decoded = img.copyRotate(decoded, angle: rotate);
    }

    decoded = img.adjustColor(
      decoded,
      brightness: args['brightness'] as double,
      contrast: args['contrast'] as double,
      saturation: args['saturation'] as double,
    );

    return Uint8List.fromList(img.encodeJpg(decoded, quality: 90));
  }
}