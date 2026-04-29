import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/model/progress.dart';

class ProgressController {
  /// Lấy thông tin tiến độ và thống kê của người dùng
  static Future<Map<String, dynamic>> getUserProgress() async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.get(
        Uri.parse('$urlAPI/api/progress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'data': ProgressModel.fromJson(data['data'])
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy thông tin thống kê'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server'
      };
    }
  }

  /// Cập nhật thời gian học tập
  static Future<Map<String, dynamic>> updateLearningTime(int durationMinutes) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.post(
        Uri.parse('$urlAPI/api/progress/update-learning-time'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'durationMinutes': durationMinutes,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': 'Đã cập nhật thời gian học'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể cập nhật thời gian học'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server'
      };
    }
  }
}
