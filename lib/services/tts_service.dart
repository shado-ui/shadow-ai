import 'dart:io';
import 'package:flutter/services.dart';

/// Lightweight TTS wrapper that uses native platform TTS without heavy plugins.
/// Works on Windows via SAPI, Android via TextToSpeech, iOS via AVSpeechSynthesizer.
class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  static const _channel = MethodChannel('ai_hub/tts');
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      _isSpeaking = true;
      if (Platform.isWindows) {
        // On Windows, use Process to invoke PowerShell SAPI
        await Process.run('powershell', [
          '-Command',
          'Add-Type -AssemblyName System.Speech; '
              '\$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer; '
              '\$synth.Rate = 1; '
              '\$synth.Speak("${text.replaceAll('"', '\\"').replaceAll('\n', ' ').substring(0, text.length > 2000 ? 2000 : text.length)}");'
        ]);
      } else {
        // On mobile, try platform channel
        await _channel.invokeMethod('speak', {'text': text});
      }
    } catch (_) {
      // TTS not available on this platform
    } finally {
      _isSpeaking = false;
    }
  }

  Future<void> stop() async {
    _isSpeaking = false;
    try {
      if (Platform.isWindows) {
        // Kill any running powershell speech
        await Process.run('taskkill', ['/F', '/IM', 'powershell.exe'], runInShell: true);
      } else {
        await _channel.invokeMethod('stop');
      }
    } catch (_) {
      // Ignore
    }
  }
}
