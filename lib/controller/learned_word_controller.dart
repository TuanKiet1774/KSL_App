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
        // Cập nhật lại thông tin user để đồng bộ EXP realtime
        await AuthController.getProfile();
        
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

  /// Lấy danh sách từ đã học của user (có phân trang)
  static Future<Map<String, dynamic>> getMyLearnedWords({String? topicId, int page = 1, int limit = 10}) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      String url = '$urlAPI/api/learned-words?page=$page&limit=$limit';
      if (topicId != null) url += '&topicId=$topicId';

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
  /// Xóa một từ đã học
  static Future<Map<String, dynamic>> deleteLearnedWord(String id) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.delete(
        Uri.parse('$urlAPI/api/learned-words/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Cập nhật lại thông tin user để đồng bộ EXP realtime
        await AuthController.getProfile();

        return {
          'success': true,
          'message': data['message'] ?? 'Đã xóa từ vựng khỏi danh sách đã học'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể xóa từ vựng'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }

  /// Xóa nhiều từ đã học
  static Future<Map<String, dynamic>> deleteMultipleLearnedWords(List<String> ids) async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.delete(
        Uri.parse('$urlAPI/api/learned-words/bulk'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'ids': ids}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Cập nhật lại thông tin user để đồng bộ EXP realtime
        await AuthController.getProfile();

        return {
          'success': true,
          'message': data['message'] ?? 'Đã xóa các từ vựng đã chọn'
        };
      } else {
        // Nếu API bulk không tồn tại, thử xóa từng cái (fallback)
        int successCount = 0;
        for (String id in ids) {
          final res = await deleteLearnedWord(id);
          if (res['success']) successCount++;
        }
        
        if (successCount > 0) {
          return {
            'success': true,
            'message': 'Đã xóa $successCount/${ids.length} từ vựng'
          };
        }

        return {
          'success': false,
          'message': data['message'] ?? 'Không thể xóa các từ vựng'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối server: $e'
      };
    }
  }

  /// Đồng bộ EXP
  static Future<Map<String, dynamic>> syncExp() async {
    try {
      final token = await AuthController.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Bạn chưa đăng nhập'};
      }

      final response = await http.post(
        Uri.parse('$urlAPI/api/learned-words/sync-exp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'totalExp': data['totalExp']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Không thể đồng bộ EXP'
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
