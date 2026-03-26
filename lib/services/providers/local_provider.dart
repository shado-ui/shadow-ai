import 'package:flutter/services.dart';
import '../../services/database_service.dart';
import 'ai_provider.dart';

class LocalProvider implements AIProvider {
  static const _channel = MethodChannel('ai_hub/llama');
  String? _loadedModelPath;

  Future<void> loadModel(String path) async {
    if (_loadedModelPath == path) return;
    final success = await _channel.invokeMethod('loadModel', {'path': path});
    if (success == true) _loadedModelPath = path;
  }

  @override
  Future<String> generateText({required String prompt, required List<Map<String, String>> history, required String modelId}) async {
    String? customPath;
    if (modelId.startsWith('offline:')) {
      customPath = modelId.replaceFirst('offline:', '');
    }
    customPath ??= await DatabaseService().getSetting('local_gguf_path');
    if (customPath == null || customPath.isEmpty) {
      throw Exception('No local model loaded. Download one from the Models tab and set it as active!');
    }
    
    await loadModel(customPath);
    
    if (_loadedModelPath == null) throw Exception('Failed to initialize local model. Please verify the file path.');
    
    String combinedPrompt = "You are Shadow AI, an expert AI assistant running locally on-device. Provide clear, well-structured answers. Use markdown formatting when helpful. Think step-by-step for complex questions. Be helpful, accurate, and conversational.\n";
    for (var m in history) {
      combinedPrompt += "${m['role']}: ${m['content']}\n";
    }
    combinedPrompt += "user: $prompt\nassistant:";

    final response = await _channel.invokeMethod<String>('generate', {'prompt': combinedPrompt});
    return response?.trim() ?? '';
  }

  @override
  Future<Uint8List> generateImage({required String prompt, required String modelId}) async => throw UnimplementedError();

  @override
  Future<Uint8List> generateVideo({required String prompt, required String modelId}) async => throw UnimplementedError();
}

