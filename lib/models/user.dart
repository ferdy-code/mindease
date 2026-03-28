class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    avatar: json['avatar'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'created_at': createdAt?.toIso8601String(),
  };
}
