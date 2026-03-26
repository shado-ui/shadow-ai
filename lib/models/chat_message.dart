enum MessageRole { user, assistant }
enum AIMode { auto, online, offline }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final AIMode mode;
  final DateTime timestamp;
  final bool isLoading;
  final String? attachment;
  final String? modelId;
  final String? imagePath;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.mode,
    required this.timestamp,
    this.isLoading = false,
    this.attachment,
    this.modelId,
    this.imagePath,
  });

  ChatMessage copyWith({
    String? content,
    bool? isLoading,
    String? attachment,
    String? modelId,
    String? imagePath,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      mode: mode,
      timestamp: timestamp,
      isLoading: isLoading ?? this.isLoading,
      attachment: attachment ?? this.attachment,
      modelId: modelId ?? this.modelId,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'role': role.name,
        'mode': mode.name,
        'timestamp': timestamp.toIso8601String(),
        if (modelId != null) 'model_id': modelId,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'],
        content: json['content'],
        role: MessageRole.values.byName(json['role']),
        mode: AIMode.values.byName(json['mode']),
        timestamp: DateTime.parse(json['timestamp']),
        modelId: json['model_id'] as String?,
      );
}

