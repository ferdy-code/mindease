class JournalEntry {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String? mood;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    this.mood,
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
    id: json['id'] as String,
    userId: json['userId'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    mood: json['mood'] as String?,
    tags: List<String>.from(json['emotionTags'] as List? ?? []),
    isFavorite: json['isFavorite'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'content': content,
    'mood': mood,
    'tags': tags,
    'isFavorite': isFavorite,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
