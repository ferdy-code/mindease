class JournalEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? mood;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.mood,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        content: json['content'] as String,
        mood: json['mood'] as String?,
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'content': content,
        'mood': mood,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
