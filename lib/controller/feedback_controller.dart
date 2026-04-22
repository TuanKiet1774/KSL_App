import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/controller/auth_controller.dart';
import 'package:ksl/model/feedback.dart';

class FeedbackController {
  static Future<Map<String, dynamic>> sendFeedback({
    required int rating,
    required String comment,
  }) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final userSource = await AuthController.getSavedUser();
      if (userSource == null) {
        return {'success': false, 'message': 'Không tìm thấy thông tin người dùng'};
      }

      final response = await http.post(
        Uri.parse('$urlAPI/api/feedbacks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userSource.id,
          'rating': rating,
          'comment': comment,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || (response.statusCode == 200 && data['success'] == true)) {
        return {
          'success': true,
          'message': data['message'] ?? 'Gửi phản hồi thành công'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gửi phản hồi thất bại'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Không thể kết nối đến server. Vui lòng thử lại sau.'
      };
    }
  }

  static Future<Map<String, dynamic>> getFeedbackHistory() async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.get(
        Uri.parse('$urlAPI/api/feedbacks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> list = data['data'];
        final feedbackList = list.map((item) => FeedbackModel.fromJson(item)).toList();
        
        return {
          'success': true,
          'data': feedbackList
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy lịch sử phản hồi'
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
