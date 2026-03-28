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

  const MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    this.note,
    this.tags = const [],
    required this.createdAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        mood: MoodLevel.values[json['mood'] as int],
        note: json['note'] as String?,
        tags: List<String>.from(json['tags'] as List? ?? []),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'mood': mood.index,
        'note': note,
        'tags': tags,
        'created_at': createdAt.toIso8601String(),
      };
}
