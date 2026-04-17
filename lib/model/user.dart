class UserModel {
  final String id;
  final String username;
  final String fullname;
  final String email;
  final String role;
  final String avatar;
  final String level;
  final int exp;
  final String accessToken;
  final String refreshToken;

  UserModel({
    required this.id,
    required this.username,
    required this.fullname,
    required this.email,
    required this.role,
    required this.avatar,
    required this.level,
    required this.exp,
    required this.accessToken,
    required this.refreshToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      avatar: json['avatar'] ?? '',
      level: json['level'] ?? '',
      exp: json['exp'] ?? 0,
      accessToken: json['accessToken'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'fullname': fullname,
      'email': email,
      'role': role,
      'avatar': avatar,
      'level': level,
      'exp': exp,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
