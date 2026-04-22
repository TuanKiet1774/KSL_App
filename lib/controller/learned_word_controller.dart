import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/controller/auth_controller.dart';
import 'package:ksl/model/learned_word.dart';

class LearnedWordController {
  /// Đánh dấu một từ vựng là đã học
  static Future<Map<String, dynamic>> markAsLearned({
    required String wordId,
    required String topicId,
    required int expGained,
  }) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.post(
        Uri.parse('$urlAPI/api/learned-words'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'wordId': wordId,
          'topicId': topicId,
          'expGained': expGained,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': LearnedWordModel.fromJson(data['data'])
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lưu tiến trình học'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }

  /// Lấy danh sách từ đã học của user
  static Future<Map<String, dynamic>> getMyLearnedWords({String? topicId}) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      String url = '$urlAPI/api/learned-words';
      if (topicId != null) url += '?topicId=$topicId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> listJson = data['data'];
        final List<LearnedWordModel> list = listJson.map((json) => LearnedWordModel.fromJson(json)).toList();
        return {
          'success': true,
          'data': list
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy danh sách từ đã học'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }
}
