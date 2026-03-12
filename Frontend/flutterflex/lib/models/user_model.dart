class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.preferredUnit,
    required this.preferredTheme,
    required this.preferredMode,
    required this.createdAt,
  });

  final int id;
  final String username;
  final String email;
  final String preferredUnit;
  final int preferredTheme;
  final String preferredMode;
  final DateTime createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.parse(json['id'].toString()),
      username: (json['username'] ?? 'Athlete') as String,
      email: json['email'] as String,
      preferredUnit: (json['preferredUnit'] ?? 'kg') as String,
      preferredTheme:
          int.tryParse((json['preferredTheme'] ?? 0).toString()) ?? 0,
      preferredMode: (json['preferredMode'] ?? 'dark') as String,
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
