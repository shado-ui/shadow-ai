import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/database_service.dart';
import 'ai_provider.dart';

class FreeProvider implements AIProvider {
  @override
  Future<String> generateText({required String prompt, required List<Map<String, String>> history, required String modelId}) async {
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': 'You are Shadow AI, an expert AI assistant. Give clear, direct, well-organized answers. Use markdown formatting — bold key terms, use headings for long answers, use bullet points and code blocks where appropriate. For complex questions, break them into steps. Be conversational but precise. Never say you cannot help — always provide the best answer you can.'},
    ];
    for (final m in history) {
      messages.add({
        'role': m['role'] == 'assistant' ? 'assistant' : 'user',
        'content': m['content'] ?? '',
      });
    }
    messages.add({'role': 'user', 'content': prompt});

    final errors = <String>[];

    // 1. Pollinations POST API (most reliable, no rate limits)
    try {
      return await _tryPollinationsPost(messages);
    } catch (e) {
      errors.add('Pollinations: ${e.toString().replaceFirst("Exception: ", "")}');
    }

    // 2. OpenRouter free router
    try {
      return await _tryOpenRouterFree(messages);
    } catch (e) {
      errors.add('OpenRouter: ${e.toString().replaceFirst("Exception: ", "")}');
    }

    // 3. OpenRouter specific free model (bypasses auto-router rate limits)
    try {
      return await _tryOpenRouterSpecificModel(messages);
    } catch (e) {
      errors.add('OpenRouter fallback: ${e.toString().replaceFirst("Exception: ", "")}');
    }

    throw Exception('All free providers failed:\n${errors.join('\n')}');
  }

  Future<String> _tryPollinationsPost(List<Map<String, String>> messages) async {
    final res = await http.post(
      Uri.parse('https://text.pollinations.ai/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'messages': messages,
        'model': 'openai',
        'seed': DateTime.now().millisecondsSinceEpoch,
      }),
    ).timeout(Duration(seconds: 25));

    if (res.statusCode != 200) throw Exception('${res.statusCode}');
    final body = res.body.trim();
    if (body.isEmpty || body.startsWith('<!doctype') || body.startsWith('<html')) {
      throw Exception('Got HTML instead of text');
    }
    // Try to parse as JSON first (newer API returns JSON)
    try {
      final data = jsonDecode(body);
      if (data is Map && data['choices'] != null) {
        final content = data['choices'][0]['message']['content'];
        if (content is String && content.trim().isNotEmpty) return content.trim();
      }
    } catch (_) {}
    // Plain text response
    return body;
  }

  Future<String> _tryOpenRouterFree(List<Map<String, String>> messages) async {
    final orKey = await _getOpenRouterKey();

    final res = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $orKey',
        'HTTP-Referer': 'https://shadowai.app',
        'X-Title': 'Shadow AI',
      },
      body: jsonEncode({
        'model': 'openrouter/free',
        'messages': messages,
        'temperature': 0.7,
      }),
    ).timeout(Duration(seconds: 25));

    if (res.statusCode == 429) {
      // Rate limited — wait briefly and retry once
      await Future.delayed(Duration(seconds: 1));
      final retry = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $orKey',
          'HTTP-Referer': 'https://shadowhub.app',
          'X-Title': 'Shadow AI',
        },
        body: jsonEncode({
          'model': 'openrouter/free',
          'messages': messages,
          'temperature': 0.7,
        }),
      ).timeout(Duration(seconds: 25));
      if (retry.statusCode == 200) {
        return _parseOpenRouterResponse(retry.body);
      }
      throw Exception('429: Provider returned error (rate limited)');
    }

    if (res.statusCode != 200) {
      String detail = '';
      try {
        final errData = jsonDecode(res.body);
        detail = errData['error']?['message']?.toString() ?? res.body;
      } catch (_) {
        detail = res.body;
      }
      if (detail.length > 200) detail = detail.substring(0, 200);
      throw Exception('${res.statusCode}: $detail');
    }

    return _parseOpenRouterResponse(res.body);
  }

  Future<String> _tryOpenRouterSpecificModel(List<Map<String, String>> messages) async {
    final orKey = await _getOpenRouterKey();
    // Try a specific free model to bypass the auto-router rate limit
    // Confirmed working models first, then rate-limited ones as backup
    final models = [
      'google/gemma-3n-e4b-it:free',
      'nvidia/nemotron-3-super-120b-a12b:free',
      'arcee-ai/trinity-mini:free',
      'z-ai/glm-4.5-air:free',
      'stepfun/step-3.5-flash:free',
      'google/gemma-3-27b-it:free',
      'meta-llama/llama-3.3-70b-instruct:free',
    ];

    for (final model in models) {
      try {
        final res = await http.post(
          Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $orKey',
            'HTTP-Referer': 'https://shadowhub.app',
            'X-Title': 'Shadow AI',
          },
          body: jsonEncode({
            'model': model,
            'messages': messages,
            'temperature': 0.7,
          }),
        ).timeout(Duration(seconds: 20));

        if (res.statusCode == 200) {
          return _parseOpenRouterResponse(res.body);
        }
      } catch (_) {}
    }
    throw Exception('All specific models failed');
  }

  String _parseOpenRouterResponse(String body) {
    final data = jsonDecode(body);
    final content = data['choices']?[0]?['message']?['content'];
    if (content is String && content.trim().isNotEmpty) return content.trim();
    throw Exception('Empty response');
  }

  Future<String> _getOpenRouterKey() async {
    var dbKey = await DatabaseService().getSetting('openrouter_key');
    var envKey = dotenv.isInitialized ? dotenv.env['OPENROUTER_API_KEY'] : null;

    String orKey = '';
    if (dbKey != null && dbKey.trim().isNotEmpty) {
      orKey = dbKey.trim();
    } else if (envKey != null && envKey.trim().isNotEmpty) {
      orKey = envKey.trim();
    }
    if (orKey.isEmpty) throw Exception('OpenRouter API key missing. Get one free at openrouter.ai/keys and add it in Settings.');
    return orKey;
  }

  @override
  Future<Uint8List> generateImage({required String prompt, required String modelId}) async {
    throw Exception('Image generation requires a HuggingFace API key. Get one free at huggingface.co/settings/tokens and add it in Settings.');
  }

  @override
  Future<Uint8List> generateVideo({required String prompt, required String modelId}) async {
    throw Exception('Video generation requires a HuggingFace API key. Get one free at huggingface.co/settings/tokens and add it in Settings.');
  }
}

