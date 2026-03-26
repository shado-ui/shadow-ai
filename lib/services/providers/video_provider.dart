import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../services/database_service.dart';

class VideoProvider {
  Future<String> _getKey() async {
    var dbKey = await DatabaseService().getSetting('veo_key');
    if (dbKey != null && dbKey.trim().isNotEmpty) return dbKey.trim();
    throw Exception('Video API key missing. Sign up free at modelslab.com and add your API key in Settings.');
  }

  Future<Uint8List> generateVideo({required String prompt, int duration = 5}) async {
    final apiKey = await _getKey();

    // ModelsLab text-to-video API
    final submitRes = await http.post(
      Uri.parse('https://modelslab.com/api/v6/video/text2video'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'key': apiKey,
        'model_id': 'cogvideox',
        'prompt': prompt,
        'negative_prompt': 'low quality, blurry',
        'height': 480,
        'width': 640,
        'num_frames': 16,
        'num_inference_steps': 20,
        'guidance_scale': 7,
      }),
    ).timeout(Duration(seconds: 30));

    if (submitRes.statusCode != 200) {
      throw Exception('Video API Error ${submitRes.statusCode}');
    }

    final data = jsonDecode(submitRes.body);

    if (data['status'] == 'error') {
      final msg = data['message'] ?? 'Unknown error';
      if (msg.toString().contains('Invalid API')) {
        throw Exception('Invalid API key. Get a free key at modelslab.com/dashboard/api-keys');
      }
      throw Exception(msg);
    }

    // Direct output URL
    if (data['output'] != null) {
      final output = data['output'];
      if (output is String) return await _downloadVideo(output);
      if (output is List && output.isNotEmpty) return await _downloadVideo(output[0]);
    }
    if (data['future_links'] != null && data['future_links'] is List && (data['future_links'] as List).isNotEmpty) {
      return await _downloadVideo(data['future_links'][0]);
    }

    // Async: poll with fetch_id
    final fetchUrl = data['fetch_result'] ?? data['fetch_url'];
    final eta = (data['eta'] ?? 30) as num;

    if (fetchUrl != null) {
      // Wait for estimated time first
      await Future.delayed(Duration(seconds: eta.toInt().clamp(5, 30)));

      for (int i = 0; i < 24; i++) {
        final pollRes = await http.post(
          Uri.parse(fetchUrl.toString()),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'key': apiKey}),
        ).timeout(Duration(seconds: 15));

        if (pollRes.statusCode != 200) {
          await Future.delayed(Duration(seconds: 5));
          continue;
        }

        final pollData = jsonDecode(pollRes.body);
        final status = (pollData['status'] ?? '').toString().toLowerCase();

        if (status == 'error' || status == 'failed') {
          throw Exception('Video generation failed: ${pollData['message'] ?? 'Unknown'}');
        }

        if (status == 'success') {
          final out = pollData['output'];
          if (out is String) return await _downloadVideo(out);
          if (out is List && out.isNotEmpty) return await _downloadVideo(out[0]);
          throw Exception('Video done but no URL in response');
        }

        // Still processing
        await Future.delayed(Duration(seconds: 5));
      }

      throw Exception('Video generation timed out. Try again later.');
    }

    throw Exception('Unexpected API response. Check your key at modelslab.com/dashboard');
  }

  Future<Uint8List> _downloadVideo(String url) async {
    final res = await http.get(Uri.parse(url)).timeout(Duration(seconds: 60));
    if (res.statusCode != 200) throw Exception('Failed to download video: ${res.statusCode}');
    if (res.bodyBytes.length < 1000) throw Exception('Downloaded video is too small/empty');
    return res.bodyBytes;
  }
}
