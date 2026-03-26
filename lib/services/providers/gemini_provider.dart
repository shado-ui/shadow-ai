import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/database_service.dart';
import 'ai_provider.dart';

class GeminiProvider implements AIProvider {
  final _client = http.Client();

  @override
  Future<String> generateText({required String prompt, required List<Map<String, String>> history, required String modelId}) async {
    var dbKey = await DatabaseService().getSetting('api_key');
    var envKey = dotenv.isInitialized ? dotenv.env['GEMINI_API_KEY'] : null;
    
    String apiKey = '';
    if (dbKey != null && dbKey.trim().isNotEmpty && dbKey.trim() != 'YOUR_GEMINI_API_KEY') {
      apiKey = dbKey.trim();
    } else if (envKey != null && envKey.trim().isNotEmpty && envKey.trim() != 'YOUR_GEMINI_API_KEY') {
      apiKey = envKey.trim();
    }

    if (apiKey.isEmpty) throw Exception('Gemini API key missing. Get one free at aistudio.google.com/apikey and add it in Settings.');

    String target = modelId == 'auto' ? 'gemini-2.0-flash' : modelId;
    if (target == 'gemini-1.5-flash') target = 'gemini-2.0-flash';
    if (target.contains('gemini') && !target.contains('-')) target = 'gemini-2.0-flash';

    final url = 'https://generativelanguage.googleapis.com/v1beta/models/$target:generateContent?key=$apiKey';
    
    final contents = [
      {'role': 'user', 'parts': [{'text': 'You are Shadow AI, an expert AI assistant. Provide thorough, well-structured, and accurate answers. Use markdown formatting (headings, lists, code blocks, bold) to organize your responses clearly. Think step-by-step for complex questions. If you are unsure, say so honestly. Be conversational yet professional.'}]},
      {'role': 'model', 'parts': [{'text': 'Understood! I\'m Shadow AI — ready to help with anything. I\'ll give clear, well-formatted answers and think through complex problems step by step. What can I help you with?'}]},
      ...history.map((m) => {
        'role': m['role'] == 'assistant' ? 'model' : 'user',
        'parts': [{'text': m['content']}]
      }),
      {'role': 'user', 'parts': [{'text': prompt}]},
    ];

    final res = await _client.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contents': contents}),
    ).timeout(Duration(seconds: 45));

    if (res.statusCode != 200) {
      String detail = '';
      try {
        final errData = jsonDecode(res.body);
        detail = errData['error']?['message'] ?? res.body.substring(0, 200);
      } catch (_) {
        detail = res.body.length > 200 ? res.body.substring(0, 200) : res.body;
      }
      throw Exception('Gemini ${res.statusCode}: $detail');
    }
    
    final data = jsonDecode(res.body);
    if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
      throw Exception('Gemini returned empty response');
    }
    return data['candidates'][0]['content']['parts'][0]['text'] as String;
  }

  @override
  Future<Uint8List> generateImage({required String prompt, required String modelId}) async => throw UnimplementedError();

  @override
  Future<Uint8List> generateVideo({required String prompt, required String modelId}) async => throw UnimplementedError();
}

