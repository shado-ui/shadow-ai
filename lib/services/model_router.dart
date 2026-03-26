import 'dart:typed_data';
import '../models/chat_message.dart';
import 'connectivity_service.dart';
import 'providers/ai_provider.dart';
import 'providers/gemini_provider.dart';
import 'providers/huggingface_provider.dart';
import 'providers/openrouter_provider.dart';
import 'providers/local_provider.dart';
import 'providers/free_provider.dart';
import 'providers/video_provider.dart';

typedef ModeChangeCallback = void Function(AIMode from, AIMode to, String reason);

class ModelRouter {
  static final ModelRouter _instance = ModelRouter._internal();
  factory ModelRouter() => _instance;
  ModelRouter._internal();

  final _connectivity = ConnectivityService();
  final _gemini = GeminiProvider();
  final _hf = HuggingFaceProvider();
  final _openRouter = OpenRouterProvider();
  final _local = LocalProvider();
  final _free = FreeProvider();
  final _video = VideoProvider();

  AIMode lastUsedMode = AIMode.offline;
  ModeChangeCallback? onModeChange;

  AIProvider _getProviderForModel(String modelId) {
    if (modelId.startsWith('openrouter:')) return _openRouter;
    if (modelId.startsWith('pollinations:')) return _free;
    if (modelId.contains('offline')) return _local;
    if (modelId.contains('huggingface:')) return _hf;
    if (modelId.contains('gemini')) return _gemini;
    return _free;
  }

  Future<String> sendText({required String prompt, required AIMode mode, required List<Map<String, String>> history, String modelId = 'auto'}) async {
    switch (mode) {
      case AIMode.online:
        return await _sendOnlineText(prompt, history, modelId, explicit: true);
      case AIMode.offline:
        return await _sendOfflineText(prompt, history, modelId, explicit: true);
      case AIMode.auto:
        return await _sendAutoText(prompt, history, modelId);
    }
  }

  Future<String> analyzeImage({required String base64Image, required String mimeType, required String userPrompt}) async {
    try {
      return await _openRouter.analyzeImage(base64Image: base64Image, mimeType: mimeType, userPrompt: userPrompt);
    } catch (e) {
      throw Exception('Image analysis failed: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  Future<Uint8List> generateImage({required String prompt, String modelId = 'black-forest-labs/FLUX.1-schnell'}) async {
    try {
      return await _hf.generateImage(prompt: prompt, modelId: modelId);
    } catch (e) {
      throw Exception('Image generation failed: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  Future<Uint8List> generateVideo({required String prompt}) async {
    try {
      return await _video.generateVideo(prompt: prompt);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String> _sendOnlineText(String prompt, List<Map<String, String>> history, String modelId, {bool explicit = false}) async {
    final prev = lastUsedMode;
    lastUsedMode = AIMode.online;
    if (prev != AIMode.online && !explicit) {
      onModeChange?.call(prev, AIMode.online, 'Internet available');
    }
    try {
      return await _getProviderForModel(modelId).generateText(prompt: prompt, history: history, modelId: modelId);
    } catch (primaryError) {
      try {
        onModeChange?.call(AIMode.online, AIMode.online, 'Selected model unavailable, using online fallback');
        return await _free.generateText(prompt: prompt, history: history, modelId: modelId);
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<String> _sendOfflineText(String prompt, List<Map<String, String>> history, String modelId, {bool explicit = false}) async {
    final prev = lastUsedMode;
    lastUsedMode = AIMode.offline;
    if (prev != AIMode.offline && !explicit) {
      onModeChange?.call(prev, AIMode.offline, 'Switched to local offline model');
    }
    return await _local.generateText(prompt: prompt, history: history, modelId: modelId);
  }

  Future<String> _sendAutoText(String prompt, List<Map<String, String>> history, String modelId) async {
    final isOnline = await _connectivity.isOnline();
    if (!isOnline) {
      return await _sendOfflineText(prompt, history, 'mistral-7b-offline');
    }

    // If user explicitly selected a specific model, use that provider directly
    if (modelId != 'auto') {
      try {
        return await _sendOnlineText(prompt, history, modelId);
      } catch (e) {
        // Fall through to free provider
        try {
          return await _free.generateText(prompt: prompt, history: history, modelId: modelId);
        } catch (_) {}
        rethrow;
      }
    }

    // Auto mode: try free provider FIRST (unlimited, no rate limits)
    // then Gemini as backup, then offline
    try {
      final prev = lastUsedMode;
      lastUsedMode = AIMode.online;
      if (prev != AIMode.online) {
        onModeChange?.call(prev, AIMode.online, 'Using free AI provider');
      }
      return await _free.generateText(prompt: prompt, history: history, modelId: modelId);
    } catch (freeError) {
      // Free provider failed, try Gemini
      try {
        return await _sendOnlineText(prompt, history, modelId);
      } catch (geminiError) {
        // Both online providers failed, try offline
        try {
          return await _sendOfflineText(prompt, history, 'mistral-7b-offline');
        } catch (offlineError) {
          throw Exception("Online: ${freeError.toString().replaceFirst('Exception: ', '')}\nFallback: ${geminiError.toString().replaceFirst('Exception: ', '')}");
        }
      }
    }
  }
}

