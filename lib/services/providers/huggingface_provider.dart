import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../services/database_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ai_provider.dart';

class HuggingFaceProvider implements AIProvider {
  static const _defaultToken = '';
  static const _expiredTokens = <String>[];

  Future<String> _getToken() async {
    var dbKey = await DatabaseService().getSetting('hf_key');
    var envKey = dotenv.isInitialized ? dotenv.env['HF_API_KEY'] : null;
    
    // Use DB key only if it's a valid NEW token (not the old expired one)
    if (dbKey != null && dbKey.trim().startsWith('hf_') && dbKey.trim().length > 10
        && !_expiredTokens.contains(dbKey.trim()) && dbKey.trim() != _defaultToken) {
      return dbKey.trim();
    }
    if (envKey != null && envKey.trim().startsWith('hf_') && envKey.trim().length > 10
        && !_expiredTokens.contains(envKey.trim())) {
      return envKey.trim();
    }
    if (_defaultToken.isEmpty) throw Exception('HuggingFace token missing. Get one free at huggingface.co/settings/tokens and add it in Settings.');
    return _defaultToken;
  }

  @override
  Future<String> generateText({required String prompt, required List<Map<String, String>> history, required String modelId}) async {
    final token = await _getToken();
    final url = 'https://router.huggingface.co/hf-inference/models/$modelId/v1/chat/completions';
    
    final messages = [
      ...history.map((m) => {'role': m['role'], 'content': m['content']}),
      {'role': 'user', 'content': prompt}
    ];

    var res = await http.post(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'model': modelId, 'messages': messages, 'max_tokens': 1024}),
    ).timeout(Duration(seconds: 30));

    // Fallback if model doesn't support chat completions endpoint
    if (res.statusCode == 404 || res.statusCode == 400) {
      final fallbackUrl = 'https://router.huggingface.co/hf-inference/models/$modelId';
      final stringPrompt = messages.map((m) => "${m['role']}: ${m['content']}").join('\n');
      res = await http.post(
        Uri.parse(fallbackUrl),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'inputs': '$stringPrompt\nuser: $prompt\nassistant:', 'parameters': {'max_new_tokens': 1024}}),
      ).timeout(Duration(seconds: 30));
    }

    if (res.statusCode == 503) throw Exception('Model is spinning up, please wait 30s');
    if (res.statusCode != 200) throw Exception('HF Inference Error ${res.statusCode}');

    final data = jsonDecode(res.body);
    if (data is List) return (data[0]['generated_text'] as String).split('assistant:').last.trim();
    return data['choices'][0]['message']['content'] as String;
  }

  static const _freepikKey = '';

  @override
  Future<Uint8List> generateImage({required String prompt, required String modelId}) async {
    final errors = <String>[];

    // 1. Freepik API (fast, high quality)
    try {
      return await _tryFreepikImage(prompt);
    } catch (e) {
      errors.add('Freepik: ${e.toString().replaceFirst("Exception: ", "")}');
    }

    // 2. Pollinations free image API (no key needed)
    try {
      return await _tryPollinationsImage(prompt);
    } catch (e) {
      errors.add('Pollinations: ${e.toString().replaceFirst("Exception: ", "")}');
    }

    // 3. Fall back to HuggingFace SDXL-Turbo
    try {
      return await _tryHuggingFaceImage(prompt);
    } catch (e) {
      errors.add('HuggingFace: ${e.toString().replaceFirst("Exception: ", "")}');
    }

    throw Exception('All image providers failed:\n${errors.join('\n')}');
  }

  Future<Uint8List> _tryFreepikImage(String prompt) async {
    final res = await http.post(
      Uri.parse('https://api.freepik.com/v1/ai/text-to-image'),
      headers: {
        'Content-Type': 'application/json',
        'x-freepik-api-key': _freepikKey,
      },
      body: jsonEncode({
        'prompt': prompt,
        'num_images': 1,
        'image': {'size': 'square_1_1'},
        'guidance_scale': 1.5,
        'filter_nsfw': false,
      }),
    ).timeout(Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw Exception('Freepik ${res.statusCode}: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
    }

    final data = jsonDecode(res.body);
    final b64 = data['data']?[0]?['base64'];
    if (b64 is String && b64.isNotEmpty) {
      return base64Decode(b64);
    }
    throw Exception('No image data in Freepik response');
  }

  Future<Uint8List> _tryPollinationsImage(String prompt) async {
    final encoded = Uri.encodeComponent(prompt);
    final url = 'https://image.pollinations.ai/prompt/$encoded?width=1024&height=1024&nologo=true&seed=${DateTime.now().millisecondsSinceEpoch}';
    final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 60));

    if (res.statusCode != 200) {
      throw Exception('Pollinations ${res.statusCode}');
    }
    if (res.bodyBytes.length < 1000) {
      throw Exception('Invalid image data from Pollinations');
    }
    return res.bodyBytes;
  }

  Future<Uint8List> _tryHuggingFaceImage(String prompt) async {
    final token = await _getToken();
    final models = [
      'https://api-inference.huggingface.co/models/stabilityai/sdxl-turbo',
      'https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0',
    ];

    late http.Response res;
    for (final url in models) {
      res = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'num_inference_steps': url.contains('turbo') ? 4 : 20,
          }
        }),
      ).timeout(Duration(seconds: 60));
      if (res.statusCode == 200 && res.bodyBytes.length > 1000) break;
      if (res.statusCode != 503) break;
    }

    if (res.statusCode != 200) {
      throw Exception('HF ${res.statusCode}: ${res.body.length > 200 ? res.body.substring(0, 200) : res.body}');
    }
    if (res.bodyBytes.length < 1000) {
      throw Exception('Invalid image data from HuggingFace');
    }
    return res.bodyBytes;
  }

  @override
  Future<Uint8List> generateVideo({required String prompt, required String modelId}) async {
    final token = await _getToken();
    final url = 'https://router.huggingface.co/hf-inference/models/$modelId';

    final res = await http.post(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'inputs': prompt}),
    ).timeout(Duration(seconds: 60));

    if (res.statusCode == 503) throw Exception('Video Model is loading, please wait 30s');
    if (res.statusCode != 200) throw Exception('Video Gen Error ${res.statusCode}');

    return res.bodyBytes;
  }
}

