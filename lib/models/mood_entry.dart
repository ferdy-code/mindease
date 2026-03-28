enum MoodLevel { veryBad, bad, neutral, good, veryGood }

extension MoodLevelX on MoodLevel {
  String get emoji {
    const emojis = ['😔', '😕', '😐', '🙂', '😄'];
    return emojis[index];
  }

  String get label {
    const labels = ['Sangat Buruk', 'Buruk', 'Biasa', 'Baik', 'Sangat Baik'];
    return labels[index];
  }
}

class MoodEntry {
  final String id;
  final String userId;
  final MoodLevel mood;
  final String? note;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    this.note,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
    id: json['id'] as String,
    userId: json['userId'] as String,
    mood: MoodLevel.values[(json['moodScore'] as int) - 1],
    note: json['note'] as String?,
    tags: List<String>.from(json['activities'] as List? ?? []),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: json['updatedAt'] != null
        ? DateTime.parse(json['updatedAt'] as String)
        : DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'mood': mood.index,
    'note': note,
    'tags': tags,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
