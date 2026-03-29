import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/database_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_provider.dart';
import 'dart:typed_data';

class OpenRouterProvider implements AIProvider {
  final _client = http.Client();

  @override
  Future<String> generateText({required String prompt, required List<Map<String, String>> history, required String modelId}) async {
    var orModel = modelId.replaceFirst('openrouter:', '');
    if (orModel.isEmpty || orModel == 'auto' || orModel == modelId) {
      orModel = 'openrouter/free';
    }
    var dbKey = await DatabaseService().getSetting('openrouter_key');
    var envKey = dotenv.isInitialized ? dotenv.env['OPENROUTER_API_KEY'] : null;
    
    String orKey = '';
    if (dbKey != null && dbKey.trim().isNotEmpty) {
      orKey = dbKey.trim();
    } else if (envKey != null && envKey.trim().isNotEmpty) {
      orKey = envKey.trim();
    }
    if (orKey.isEmpty) throw Exception('OpenRouter API key missing. Get one free at openrouter.ai/keys and add it in Settings.');

    final orContents = <Map<String, String>>[
      {'role': 'system', 'content': 'You are Shadow AI, an expert AI assistant. Give clear, direct, well-organized answers. Use markdown formatting — bold key terms, use headings for long answers, use bullet points and code blocks where appropriate. For complex questions, break them into steps. Be conversational but precise. Never say you cannot help — always provide the best answer you can.'},
      ...history,
    ];
    orContents.add({'role': 'user', 'content': prompt});

    final res = await _client.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $orKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://shadowai.app',
        'X-Title': 'Shadow AI',
      },
      body: jsonEncode({
        'model': orModel,
        'messages': orContents,
        'temperature': 0.7,
      }),
    ).timeout(Duration(seconds: 60));

    if (res.statusCode != 200) {
      String detail = '';
      try {
        final data = jsonDecode(res.body);
        detail = data['error']?['message']?.toString() ?? res.body;
      } catch (_) {
        detail = res.body;
      }
      throw Exception('OpenRouter ${res.statusCode}: ${detail.length > 220 ? detail.substring(0, 220) : detail}');
    }
    
    final data = jsonDecode(res.body);
    final content = data['choices']?[0]?['message']?['content'];
    if (content is String && content.trim().isNotEmpty) {
      return content.trim();
    }
    if (content is List) {
      final text = content
          .whereType<Map>()
          .map((part) => part['text']?.toString() ?? '')
          .join('')
          .trim();
      if (text.isNotEmpty) return text;
    }
    throw Exception('OpenRouter returned empty response');
  }

  /// Analyze an image using a vision-capable model
  Future<String> analyzeImage({required String base64Image, required String mimeType, required String userPrompt}) async {
    var dbKey = await DatabaseService().getSetting('openrouter_key');
    var envKey = dotenv.isInitialized ? dotenv.env['OPENROUTER_API_KEY'] : null;
    
    String orKey = '';
    if (dbKey != null && dbKey.trim().isNotEmpty) {
      orKey = dbKey.trim();
    } else if (envKey != null && envKey.trim().isNotEmpty) {
      orKey = envKey.trim();
    }
    if (orKey.isEmpty) throw Exception('OpenRouter API key missing. Get one free at openrouter.ai/keys and add it in Settings.');

    // Vision-capable free models in priority order
    final visionModels = [
      'nvidia/nemotron-nano-12b-v2-vl:free',
      'mistralai/mistral-small-3.1-24b-instruct:free',
      'meta-llama/llama-3.3-70b-instruct:free',
    ];

    final dataUrl = 'data:$mimeType;base64,$base64Image';
    final messages = [
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': userPrompt.isNotEmpty ? userPrompt : 'Describe this image in detail. If it contains text, extract all the text.'},
          {'type': 'image_url', 'image_url': {'url': dataUrl}},
        ],
      },
    ];

    final errors = <String>[];
    for (final model in visionModels) {
      try {
        final res = await _client.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $orKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://shadowai.app',
            'X-Title': 'Shadow AI',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.3,
          }),
        ).timeout(Duration(seconds: 60));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final content = data['choices']?[0]?['message']?['content'];
          if (content is String && content.trim().isNotEmpty) return content.trim();
        }
      } catch (e) {
        errors.add('$model: ${e.toString().replaceFirst("Exception: ", "")}');
      }
    }
    throw Exception('Vision analysis failed: ${errors.join(', ')}');
  }

  @override
  Future<Uint8List> generateImage({required String prompt, required String modelId}) async => throw UnimplementedError();

  @override
  Future<Uint8List> generateVideo({required String prompt, required String modelId}) async => throw UnimplementedError();
}

