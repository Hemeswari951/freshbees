import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/voice_search_service.dart';

/// Shows the voice-search bottom sheet and returns the final recognized
/// text (or null if the person cancelled / nothing was recognized).
Future<String?> showVoiceSearchSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _VoiceSearchSheet(),
  );
}

class _VoiceSearchSheet extends StatefulWidget {
  const _VoiceSearchSheet();

  @override
  State<_VoiceSearchSheet> createState() => _VoiceSearchSheetState();
}

enum _VoiceState { listening, permissionDenied, permissionPermanentlyDenied, notAvailable, error }

class _VoiceSearchSheetState extends State<_VoiceSearchSheet>
    with SingleTickerProviderStateMixin {
  final VoiceSearchService _voiceService = VoiceSearchService.instance;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  _VoiceState _state = _VoiceState.listening;
  String _liveText = '';
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  Future<void> _begin() async {
    await _voiceService.startListening(
      onPartialResult: (text) {
        if (!mounted) return;
        setState(() => _liveText = text);
      },
      onFinalResult: (text) {
        if (!mounted || _finished) return;
        _finished = true;
        Navigator.of(context).pop(text);
      },
      onStatus: (status) {
        // 'done' / 'notListening' fires when the recognizer stops on its
        // own (e.g. the person went quiet without a clean final result).
        if (!mounted || _finished) return;
        if (status == 'done' || status == 'notListening') {
          _finished = true;
          Navigator.of(context).pop(_liveText.isEmpty ? null : _liveText);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          switch (error) {
            case 'permission_denied':
              _state = _VoiceState.permissionDenied;
              break;
            case 'permission_permanently_denied':
              _state = _VoiceState.permissionPermanentlyDenied;
              break;
            case 'not_available':
              _state = _VoiceState.notAvailable;
              break;
            default:
              _state = _VoiceState.error;
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (!_finished) {
      // Sheet dismissed (swipe/back) while still listening — stop the
      // mic session so it doesn't keep running in the background.
      _voiceService.cancelListening();
    }
    super.dispose();
  }

  void _cancel() {
    _finished = true;
    _voiceService.cancelListening();
    Navigator.of(context).pop();
  }

  void _done() {
    _finished = true;
    _voiceService.stopListening();
    Navigator.of(context).pop(_liveText.isEmpty ? null : _liveText);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: _state == _VoiceState.listening
            ? _buildListening()
            : _buildProblem(),
      ),
    );
  }

  Widget _buildListening() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1 + (_pulseController.value * 0.25);
            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB8956A).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                child!,
              ],
            );
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFF8B7355),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Listening...',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          _liveText.isEmpty ? 'Say what you\'re looking for' : _liveText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: _liveText.isEmpty ? Colors.black45 : Colors.black87,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(onPressed: _cancel, child: const Text('Cancel')),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _liveText.isEmpty ? null : _done,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Search'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProblem() {
    String message;
    String? actionLabel;
    VoidCallback? action;

    switch (_state) {
      case _VoiceState.permissionDenied:
        message = 'Microphone access is needed for voice search.';
        actionLabel = 'Try Again';
        action = () => setState(() {
              _state = _VoiceState.listening;
              _finished = false;
              _begin();
            });
        break;
      case _VoiceState.permissionPermanentlyDenied:
        message =
            'Microphone access is blocked. Please enable it in your device settings to use voice search.';
        actionLabel = 'Open Settings';
        action = () => openAppSettings();
        break;
      case _VoiceState.notAvailable:
        message = 'Voice search isn\'t available on this device right now.';
        break;
      case _VoiceState.error:
      default:
        message = 'Something went wrong while listening. Please try again.';
        actionLabel = 'Try Again';
        action = () => setState(() {
              _state = _VoiceState.listening;
              _finished = false;
              _begin();
            });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mic_off_rounded, size: 40, color: Colors.black38),
        const SizedBox(height: 14),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: action,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
