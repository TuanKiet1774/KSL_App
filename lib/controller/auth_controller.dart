import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/model/user.dart';

class AuthController {
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
          'message': data['message'] ?? 'Đăng nhập thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến server. Vui lòng thử lại.',
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
    String? level,
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
          'level': level,
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

  /// Lưu dữ liệu người dùng vào SharedPreferences
  static Future<void> _saveUserData(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));
    await prefs.setString('access_token', user.accessToken);
    await prefs.setString('refresh_token', user.refreshToken);
    await prefs.setBool('is_logged_in', true);
  }

  /// Kiểm tra trạng thái đăng nhập
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  /// Lấy dữ liệu người dùng đã lưu
  static Future<UserModel?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');
    if (userData != null) {
      return UserModel.fromJson(jsonDecode(userData));
    }
    return null;
  }

  /// Lấy access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Lấy thông tin chi tiết người dùng (Profile)
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

  /// Đăng xuất
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
