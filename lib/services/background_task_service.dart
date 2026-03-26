import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/chat_message.dart';
import '../models/app_state.dart';
import 'model_router.dart';
import 'database_service.dart';

/// Manages AI response generation tasks that persist across chat switches.
/// When a user sends a message and switches chats, the response still
/// gets generated and saved to the correct project in the database.
class BackgroundTaskService {
  static final BackgroundTaskService _instance = BackgroundTaskService._internal();
  factory BackgroundTaskService() => _instance;
  BackgroundTaskService._internal();

  final _router = ModelRouter();
  final _db = DatabaseService();
  final _uuid = Uuid();

  /// Set of project IDs that currently have a pending generation task.
  final Set<String> _pendingProjects = {};

  /// Callbacks: when a task completes for a project, notify the listener.
  /// The chat screen registers itself here when it's active.
  void Function(String projectId, ChatMessage message)? onTaskComplete;
  void Function(String projectId, String error)? onTaskError;

  bool hasPendingTask(String projectId) => _pendingProjects.contains(projectId);

  /// Generate a text response in the background.
  /// Saves the result to DB regardless of whether the chat screen is still open.
  Future<void> generateText({
    required String projectId,
    required String prompt,
    required List<Map<String, String>> history,
    required String modelId,
    required AIMode mode,
    required String memoryContext,
  }) async {
    _pendingProjects.add(projectId);

    try {
      final contextPrompt = memoryContext.isNotEmpty
          ? 'System Memory/Context: $memoryContext\n\nUser Query: $prompt'
          : prompt;

      final response = await _router.sendText(
        prompt: contextPrompt,
        mode: mode,
        history: history,
        modelId: modelId,
      );

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        content: response,
        role: MessageRole.assistant,
        mode: _router.lastUsedMode,
        timestamp: DateTime.now(),
        modelId: modelId,
      );

      // Always save to DB
      await _db.insertMessage({
        'id': assistantMsg.id,
        'project_id': projectId,
        'content': assistantMsg.content,
        'role': 'assistant',
        'mode': _router.lastUsedMode.name,
        'timestamp': assistantMsg.timestamp.millisecondsSinceEpoch,
        'model_used': modelId,
      });

      _pendingProjects.remove(projectId);
      AppState().refreshProjects();
      onTaskComplete?.call(projectId, assistantMsg);
    } catch (e) {
      _pendingProjects.remove(projectId);
      onTaskError?.call(projectId, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Analyze an image in the background.
  Future<void> analyzeImage({
    required String projectId,
    required String base64Image,
    required String mimeType,
    required String userPrompt,
    required String modelId,
  }) async {
    _pendingProjects.add(projectId);

    try {
      final response = await _router.analyzeImage(
        base64Image: base64Image,
        mimeType: mimeType,
        userPrompt: userPrompt,
      );

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        content: response,
        role: MessageRole.assistant,
        mode: AIMode.online,
        timestamp: DateTime.now(),
        modelId: modelId,
      );

      await _db.insertMessage({
        'id': assistantMsg.id,
        'project_id': projectId,
        'content': assistantMsg.content,
        'role': 'assistant',
        'mode': 'online',
        'timestamp': assistantMsg.timestamp.millisecondsSinceEpoch,
        'model_used': modelId,
      });

      _pendingProjects.remove(projectId);
      AppState().refreshProjects();
      onTaskComplete?.call(projectId, assistantMsg);
    } catch (e) {
      _pendingProjects.remove(projectId);
      onTaskError?.call(projectId, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Generate an image in the background.
  Future<void> generateImage({
    required String projectId,
    required String prompt,
    required String modelId,
  }) async {
    _pendingProjects.add(projectId);

    try {
      final styledPrompt = '$prompt, high quality, detailed';
      final bytes = await _router.generateImage(prompt: styledPrompt);

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'ai_image_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      final assistantMsg = ChatMessage(
        id: _uuid.v4(),
        content: '![Generated Image](${file.path})',
        role: MessageRole.assistant,
        mode: AIMode.online,
        timestamp: DateTime.now(),
        imagePath: file.path,
      );

      await _db.insertMessage({
        'id': assistantMsg.id,
        'project_id': projectId,
        'content': assistantMsg.content,
        'role': 'assistant',
        'mode': 'online',
        'timestamp': assistantMsg.timestamp.millisecondsSinceEpoch,
        'model_used': modelId,
      });

      _pendingProjects.remove(projectId);
      AppState().refreshProjects();
      onTaskComplete?.call(projectId, assistantMsg);
    } catch (e) {
      _pendingProjects.remove(projectId);
      onTaskError?.call(projectId, 'Image generation failed: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }
}
