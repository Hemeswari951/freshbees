import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

/// Result of a microphone-permission check/request — mirrors the shape
/// used by LocationPermissionService so both permission flows in the app
/// look the same to callers.
enum MicPermissionResult {
  granted,
  denied,
  permanentlyDenied,
}

/// Thin wrapper around `speech_to_text` used by the Home screen's
/// microphone icon (voice search). Keeps all the plugin plumbing —
/// permission checks, initialization, listening state, error handling —
/// in one place so the UI code just calls start/stop and reacts to a
/// couple of callbacks.
class VoiceSearchService {
  VoiceSearchService._internal();
  static final VoiceSearchService instance = VoiceSearchService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  bool get isListening => _speech.isListening;

  // ---------------------------------------------------------------------
  // PERMISSION
  // ---------------------------------------------------------------------
  Future<MicPermissionResult> ensureMicPermission() async {
    final status = await Permission.microphone.status;

    if (status.isGranted) return MicPermissionResult.granted;

    if (status.isPermanentlyDenied) {
      return MicPermissionResult.permanentlyDenied;
    }

    final requested = await Permission.microphone.request();

    if (requested.isGranted) return MicPermissionResult.granted;
    if (requested.isPermanentlyDenied) {
      return MicPermissionResult.permanentlyDenied;
    }
    return MicPermissionResult.denied;
  }

  // ---------------------------------------------------------------------
  // INIT — speech_to_text needs a one-time init (loads the on-device or
  // platform recognizer). Safe to call repeatedly; it's a no-op after
  // the first successful call.
  // ---------------------------------------------------------------------
  Future<bool> _initIfNeeded({
    required ValueChanged<String> onStatus,
    required ValueChanged<String> onError,
  }) async {
    if (_isInitialized) return true;

    _isInitialized = await _speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError(error.errorMsg),
      debugLogging: false,
    );

    return _isInitialized;
  }

  /// Starts listening. [onPartialResult] fires repeatedly with the
  /// best-guess text as the person speaks (for live captions in the UI).
  /// [onFinalResult] fires once, with the final recognized text, when
  /// the person stops speaking — that's the value the caller should
  /// actually search with.
  Future<bool> startListening({
    required ValueChanged<String> onPartialResult,
    required ValueChanged<String> onFinalResult,
    required ValueChanged<String> onStatus,
    required ValueChanged<String> onError,
  }) async {
    final permission = await ensureMicPermission();
    if (permission != MicPermissionResult.granted) {
      onError(
        permission == MicPermissionResult.permanentlyDenied
            ? 'permission_permanently_denied'
            : 'permission_denied',
      );
      return false;
    }

    final ready = await _initIfNeeded(onStatus: onStatus, onError: onError);
    if (!ready) {
      onError('not_available');
      return false;
    }

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        } else {
          onPartialResult(result.recognizedWords);
        }
      },
      listenFor: const Duration(seconds: 12),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.search,
    );

    return true;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
