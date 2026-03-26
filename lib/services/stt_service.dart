import 'dart:io';

/// Lightweight STT stub. Speech-to-text requires native plugins on mobile.
/// On desktop, this gracefully reports unavailability.
class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  bool _isAvailable = false;
  bool _isListening = false;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;

  Future<bool> initialize() async {
    // STT is only available on Android/iOS with native support
    if (Platform.isAndroid || Platform.isIOS) {
      _isAvailable = true;
      return true;
    }
    _isAvailable = false;
    return false;
  }

  Future<void> startListening({required Function(String) onResult}) async {
    if (!_isAvailable) return;
    _isListening = true;
    // On mobile, this would use the native speech recognition APIs
    // For now, gracefully report that it needs platform setup
  }

  Future<void> stopListening() async {
    _isListening = false;
  }
}
