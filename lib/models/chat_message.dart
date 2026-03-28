enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final String sessionId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    sessionId: json['sessionId'] as String,
    role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
    content: json['content'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'role': role == MessageRole.user ? 'user' : 'assistant',
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };
}
