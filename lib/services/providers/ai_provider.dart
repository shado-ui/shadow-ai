import 'dart:typed_data';

abstract class AIProvider {
  Future<String> generateText({required String prompt, required List<Map<String, String>> history, required String modelId});
  Future<Uint8List> generateImage({required String prompt, required String modelId});
  Future<Uint8List> generateVideo({required String prompt, required String modelId});
}

