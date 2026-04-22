import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/controller/auth_controller.dart';

import 'package:ksl/model/topic.dart';

class TopicController {
  /// Lấy danh sách tất cả các chủ đề với phân trang
  static Future<Map<String, dynamic>> getAllTopics({int page = 1, int limit = 10}) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.get(
        Uri.parse('$urlAPI/api/topics?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> topicJson = data['data'];
        final List<TopicModel> topics = topicJson.map((json) => TopicModel.fromJson(json)).toList();
        
        return {
          'success': true,
          'data': topics
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy danh sách chủ đề'
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
