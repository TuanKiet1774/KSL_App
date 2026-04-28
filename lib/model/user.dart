class UserModel {
  final String id;
  final String username;
  final String fullname;
  final String email;
  final String phone;
  final String role;
  final String avatar;
  final String birthday;
  final String address;
  final String gender;
  final int exp;
  final String accessToken;
  final String refreshToken;

  UserModel({
    required this.id,
    required this.username,
    required this.fullname,
    required this.email,
    required this.phone,
    required this.role,
    required this.avatar,
    required this.birthday,
    required this.address,
    required this.gender,
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
      phone: json['phone'] ?? '',
      role: json['role'] ?? '',
      avatar: json['avatar'] ?? '',
      birthday: json['birthday'] ?? '',
      address: json['address'] ?? '',
      gender: json['gender'] ?? '',
      exp: json['exp'] ?? 0,
      accessToken: json['accessToken'] ?? json['mobileSessionToken'] ?? '',
      refreshToken: json['refreshToken'] ?? json['mobileRefreshToken'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'fullname': fullname,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'birthday': birthday,
      'address': address,
      'gender': gender,
      'exp': exp,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}
