class Meditation {
  final String id;
  final String title;
  final String description;
  final int durationSeconds;
  final String category;
  final String? audioUrl;
  final String? imageUrl;

  const Meditation({
    required this.id,
    required this.title,
    required this.description,
    required this.durationSeconds,
    required this.category,
    this.audioUrl,
    this.imageUrl,
  });

  String get durationLabel {
    final minutes = durationSeconds ~/ 60;
    return '$minutes min';
  }

  factory Meditation.fromJson(Map<String, dynamic> json) => Meditation(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        durationSeconds: json['duration_seconds'] as int,
        category: json['category'] as String,
        audioUrl: json['audio_url'] as String?,
        imageUrl: json['image_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'duration_seconds': durationSeconds,
        'category': category,
        'audio_url': audioUrl,
        'image_url': imageUrl,
      };
}
