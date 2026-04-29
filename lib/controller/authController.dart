import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/model/user.dart';

class AuthController {
  static final ValueNotifier<UserModel?> userNotifier = ValueNotifier<UserModel?>(null);

  /// Đăng nhập với username và password
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$urlAPI/api/auth/login-mobile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'emailOrUsername': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Kết nối quá hạn (30s). Server có thể đang khởi động lại, vui lòng thử lại.'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = UserModel.fromJson(data['data']);

        // Lưu thông tin đăng nhập
        await _saveUserData(user);

        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng nhập thất bại (${response.statusCode})',
        };
      }
    } catch (e) {
      // In ra lỗi thực sự để debug
      debugPrint('[AuthController.login] ERROR: $e');
      return {
        'success': false,
        'message': 'Lỗi kết nối: ${e.toString()}',
      };
    }
  }

  /// Đăng ký tài khoản mới
  static Future<Map<String, dynamic>> register({
    required String username,
    required String fullname,
    required String email,
    required String password,
    String? phone,
    String? gender,
    String? birthday,
    String? address,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$urlAPI/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'fullname': fullname,
          'email': email,
          'password': password,
          'phone': phone,
          'gender': gender,
          'birthday': birthday,
          'address': address,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode == 200 && data['success'] == true)) {
        return {'success': true, 'message': data['message'] ?? 'Đăng ký thành công'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đăng ký thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến server. Vui lòng thử lại.',
      };
    }
  }

  static Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setString('access_token', user.accessToken);
    await prefs.setString('refresh_token', user.refreshToken);
    await prefs.setBool('is_logged_in', true);
    
    // Cập nhật notifier để giao diện thay đổi realtime
    userNotifier.value = user;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  static Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      final user = UserModel.fromJson(jsonDecode(userData));
      userNotifier.value = user; // Khởi tạo giá trị ban đầu cho notifier
      return user;
    }
    return null;
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getAccessToken();
      if (token == null) return {'success': false, 'message': 'Chưa đăng nhập'};

      final response = await http.get(
        Uri.parse('$urlAPI/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = UserModel.fromJson(data['data']);
        await _saveUserData(user); // Cập nhật dữ liệu mới nhất
        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy thông tin cá nhân',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String fullname,
    String? phone,
    String? gender,
    String? birthday,
    String? address,
    String? avatar,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) return {'success': false, 'message': 'Chưa đăng nhập'};

      final response = await http.put(
        Uri.parse('$urlAPI/api/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fullname': fullname,
          'phone': phone,
          'gender': gender,
          'birthday': birthday,
          'address': address,
          'avatar': avatar,
        }),
      );

      if (response.statusCode != 200) {
        return {
          'success': false,
          'message': 'Server trả về lỗi (${response.statusCode}). Vui lòng thử lại sau.',
        };
      }

      if (response.headers['content-type']?.contains('application/json') != true) {
        return {
          'success': false,
          'message': 'Phản hồi từ server không hợp lệ. Vui lòng thử lại.',
        };
      }

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final user = UserModel.fromJson(data['data']);
        await _saveUserData(user);
        return {'success': true, 'user': user};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể cập nhật thông tin',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Đổi mật khẩu
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String username,
    required String email,
    required String newPassword,
  }) async {
    try {
      final token = await getAccessToken();
      if (token == null) return {'success': false, 'message': 'Chưa đăng nhập'};

      final response = await http.post(
        Uri.parse('$urlAPI/api/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'username': username,
          'email': email,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Đổi mật khẩu thành công'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Đổi mật khẩu thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
