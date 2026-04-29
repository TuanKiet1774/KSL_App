import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ksl/connectDB/api.dart';
import 'package:ksl/controller/authController.dart';
import 'package:ksl/model/word.dart';

class WordController {
  static Future<Map<String, dynamic>> getWordsByTopic(String topicId, {int page = 1, int limit = 10}) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.get(
        Uri.parse('$urlAPI/api/words?topicId=$topicId&page=$page&limit=$limit&sortBy=name&sortOrder=asc'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> wordJson = data['data'];
        final List<WordModel> words = wordJson.map((json) => WordModel.fromJson(json)).toList();
        
        return {
          'success': true,
          'data': words
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể lấy danh sách từ vựng'
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
