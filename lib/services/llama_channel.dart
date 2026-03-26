import 'package:flutter/services.dart';

/// Flutter-side platform channel for llama.cpp.
/// The native side is implemented in:
///   Android: android/app/src/main/kotlin/.../LlamaPlugin.kt
///   iOS:     ios/Runner/LlamaPlugin.swift
class LlamaCppChannel {
  static const MethodChannel _channel = MethodChannel('ai_hub/llama');

  static final LlamaCppChannel _instance = LlamaCppChannel._internal();
  factory LlamaCppChannel() => _instance;
  LlamaCppChannel._internal();

  /// Load a GGUF model from [modelPath] on device storage.
  /// [nThreads] — number of CPU threads (4 is safe for most phones)
  /// [nCtx]    — context window size (512–2048)
  Future<bool> loadModel({
    required String modelPath,
    int nThreads = 4,
    int nCtx = 512,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
        'nThreads': nThreads,
        'nCtx': nCtx,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw Exception('loadModel failed: ${e.message}');
    }
  }

  /// Run inference. Returns generated text.
  /// [prompt]     — full prompt string (include system + history yourself)
  /// [maxTokens]  — max tokens to generate
  /// [temperature]— sampling temperature (0.0–1.0)
  Future<String> infer({
    required String prompt,
    int maxTokens = 256,
    double temperature = 0.7,
  }) async {
    try {
      final result = await _channel.invokeMethod<String>('infer', {
        'prompt': prompt,
        'maxTokens': maxTokens,
        'temperature': temperature,
      });
      return result ?? '';
    } on PlatformException catch (e) {
      throw Exception('infer failed: ${e.message}');
    }
  }

  /// Free model from memory.
  Future<void> unloadModel() async {
    try {
      await _channel.invokeMethod('unloadModel');
    } on PlatformException catch (e) {
      throw Exception('unloadModel failed: ${e.message}');
    }
  }

  /// Returns free RAM in MB (useful before loading a model).
  Future<int> getFreeMemoryMB() async {
    try {
      final result = await _channel.invokeMethod<int>('getFreeMemoryMB');
      return result ?? 0;
    } on PlatformException {
      return 0;
    }
  }
}

